---
title: Error recovery（错误恢复）
type: concept
aliases: [error recovery, 错误恢复, 重试, retry, backoff, 退避, 输出截断, max tokens, dangling tool call, 悬空 tool call]
tags: [agent-harness, error-recovery, retry, robustness]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-openharness-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-microsoft-learn-agent-harness
---

# Error recovery（错误恢复）

## 定义

Error recovery 指 [[agent-harness|agent harness]] 在出错之后让 [[agent-loop|agent loop]] 仍能继续、或至少停在一个可恢复状态的机制。本批资料里的错误可以按"谁来处理"分成三类：

| 类别 | 例子 | 处理者 | 做法 |
|---|---|---|---|
| 工具层错误 | 命令失败、文件不存在、工具名拼错、被权限或 hook 拦下 | 模型 | 把错误作为工具结果回传 |
| 模型请求层错误 | 429、5xx、网络中断 | harness | 分类后重试或放弃 |
| 协议状态错误 | 输出被截断、tool call 没有配对结果 | harness | 补全历史，使下一次请求合法 |

learn-claude-code 网站对这一课的一句话主张是："健壮的 harness 会给失败分类，再决定哪种重试值得做"（[[2026-11-20-learn-claude-code-site]]）。

## 要解决的问题和动机

- 最小的 loop 没有任何错误处理：工具抛异常，loop 就崩；API 抖一下，整个会话就断。
- 更隐蔽的问题是**历史被留在非法状态**。模型接口要求每个 tool call 都有配对的结果；如果一批工具执行到一半出错或被取消，带着这份历史再调模型会报错，"会话就接不上了"（[[2026-11-20-harness-engineering-go-practice]]）。所以错误恢复的目标不只是"再试一次"，还包括"让日志保持可恢复"（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- 对 [[long-running-agents|长任务]]来说，错误会累积（compounding errors）（[[2026-11-20-anthropic-building-effective-agents]]）。

## 工作原理

### 1. 工具报错回传给模型

原则：错误不是异常，而是给模型的信息。

- [[anthropic|Anthropic]] 的表述是 agent 每一步都要从环境拿到 ground truth（工具调用结果、代码执行结果）来评估进展（[[2026-11-20-anthropic-building-effective-agents]]）。AI Harness Crash Course 强调失败的测试结果也是要回到模型眼前的信息（[[2026-11-20-ai-harness-crash-course]]）。
- Go 练习仓库的测试把它固定为几条行为（[[2026-11-20-harness-engineering-go-practice]]）：
  - 模型请求了不存在的工具：loop 不崩溃，回一条工具结果，内容包含错误的名字和所有可用工具名。
  - 工具返回错误：`Run` 不报错，错误文字成为结果。`bash` 把命令失败也当结果返回，注释是"命令失败也是 ground truth"，并有 30 秒超时。
  - `edit_file` 要求 `old_text` 恰好出现一次，零次或多次都返回带指引的错误。
  - 权限拒绝和人工拒绝之后 loop 继续，模型拿到固定的说明文字。
- **错误信息要带修复指引。** [[claude-code|Claude Code]] 的 `PreToolUse` hook 以 exit code `2` 阻止动作时，stderr 的内容反馈给 Claude，让它知道为什么被拦并调整（[[2026-11-20-hooks-in-claude-code]]）。[[openai|OpenAI]] 团队在自定义 lint 的错误信息里直接写入修复指引，等于在出错时把指令注入 agent 上下文（[[2026-11-20-openai-harness-engineering]]）。[[microsoft-agent-framework|Microsoft Agent Framework]] 的 `file_access_grep` 在 pattern 非法、超长或超时时返回错误，文档建议缩小目录或 pattern 再重试；行级替换要传 `expected_line`，防止行号过期时改错行（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 设计工具时让错误更难发生（poka-yoke）是上游手段：Anthropic 把工具改成始终要求绝对路径后，相对路径出错的问题消失（[[2026-11-20-anthropic-building-effective-agents]]，未给量化数字）。见 [[tools]]。

### 2. 重试：哪些错误可重试、怎么退避

Go 练习仓库的分类规则（[[2026-11-20-harness-engineering-go-practice]]）：

| 错误 | 是否重试 | 理由 |
|---|---|---|
| HTTP 429、5xx | 是 | 限流或服务端临时故障 |
| 其他 4xx（如 400、401） | 否 | 请求本身有问题，重试结果一样 |
| 取消、超时（`context.Canceled` / `DeadlineExceeded`） | 否 | 是调用方的意图 |
| 其他错误 | 是 | 多半是网络问题 |

配套约定：判断时要穿透错误包装；`Attempts` 含第一次；试满后返回**最后一次**的错误；等待期间被取消要立刻返回；退避为指数退避 `base << (attempt-1)`（[[2026-11-20-harness-engineering-go-practice]]）。

重试逻辑放在哪里，三个项目三种做法：

- **包在模型外面。** Go 练习仓库的 `Retry` 自己实现 `Model` 接口，loop 完全不知道它存在（[[2026-11-20-harness-engineering-go-practice]]）。
- **loop 的内建特性。** [[openharness|OpenHarness]] 自述其 loop 带指数退避的 API 重试，并有覆盖重试的 E2E 测试（[[2026-11-20-openharness-readme]]，自述，未读源码）。
- **loop 询问插件。** [[deepseek-harness|DeepSeek Harness]] 的 loop 不自己决定：请求失败时先把失败的尝试记为 `assistant/attempt`，再发 `agent/request-error` 事件，传入 `failure` 和适配器的 `retryPolicy`；只有处理器返回 `{ kind: 'retry' }` 才重新组装请求，否则抛错。退避和次数上限都不在 loop 文件里（[[2026-11-20-deepseek-harness-agent-loop-source]]）。每次重试前会刷新运行时上下文，即重试的不是同一个字节相同的请求。

工作流层面也有重试：ADK 的 graph workflow 可以设 retry limit，agent 反复尝试仍修不好时停下并求助（[[2026-11-20-ai-harness-crash-course]]）。

### 3. 输出被截断（max tokens）

模型输出撞上输出长度上限时，tool call 的参数可能只写了一半。

- Go 练习仓库：assistant 消息的 `FinishReason == "length"` 且带工具调用时，**一个都不执行**，每个请求回一条截断说明（提示模型把内容拆小重来），loop 继续（[[2026-11-20-harness-engineering-go-practice]]）。纯文本被截断、没有工具调用时怎么办没有测试（来源页记下的缺口）。
- DeepSeek Harness：流的结束原因是 `max-tokens` 时，turn 的结束原因记为 `max-tokens`，并且是"粘性"的：之后的 step 正常完成也不能把 turn 结果降级回 `completed`（[[2026-11-20-deepseek-harness-agent-loop-source]]）。也就是说，它保证"这个 turn 里发生过截断"一定被上报。

两者不冲突但侧重不同：前者规定截断当下怎么对待 tool call，后者规定截断如何体现在停止原因里（见 [[verification-and-observability]]）。

### 4. 悬空 tool call 的补全

不变量：**历史里每个 tool call 都必须有一条结果。**

- Go 练习仓库：一批工具执行到一半被取消，没执行的每个请求也要补一条"已取消"结果（[[2026-11-20-harness-engineering-go-practice]]）。
- DeepSeek Harness：每个 step 用 `ToolCallRecovery` 监听会话事件；step 抛错时，把尚未有结果的 tool call 补写成 `tool/result` 事件，之后的请求仍然合法。补写本身失败时用 `AggregateError` 同时保留原始错误和落盘错误（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- 同一约束在 [[compaction]] 里表现为"切点不能拆开 tool 请求与结果"，在 [[steering-and-cancel]] 里表现为取消时的不变量。

### 5. 半截输出与失败边界

DeepSeek Harness 的做法（[[2026-11-20-deepseek-harness-agent-loop-source]]）：

- 流已开始后被中断，若已有内容块，以 `interrupted: true` 追加 assistant 消息（含 usage）；否则只记一次失败尝试。
- 工具批次部分失败时，已产生的附加上下文先入队，再抛出原始原因。
- 失败在发生的边界通过 `agent/error` 上报一次，然后被 driver 吞掉；agent 回到 idle，进程不崩。

### 6. 环境层的恢复

- **git 作为回退手段。** Anthropic 长任务方案要求每次提交 git，模型可以 revert 坏的改动回到可工作状态；每个 session 开头先跑基础端到端测试，发现上一个 session 留下的坏状态（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **子 agent 的失败不传染。** Go 练习仓库里子 agent 撞上自己的 turn 上限时，主 agent 收到一条含"出错"的工具结果，而不是跟着失败（[[2026-11-20-harness-engineering-go-practice]]）。见 [[subagents]]。
- **日志的容错读取。** 会话日志最后一行损坏就丢弃，中间行损坏则报错（[[2026-11-20-harness-engineering-go-practice]]）。见 [[session-log]]。

## 变体与演进

- 从"loop 里 try/except"到"失败分类 + 策略外置"：教学实现把重试做成包装器，生产取向的实现把决定权交给插件事件（[[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- 兜底上限是另一种恢复：Anthropic 建议加停止条件如最大迭代次数（[[2026-11-20-anthropic-building-effective-agents]]）；Microsoft 的 function invocation 有可配置的每次请求迭代上限（[[2026-11-20-microsoft-learn-agent-harness]]）；Go 练习仓库有 `MaxTurns`（[[2026-11-20-harness-engineering-go-practice]]）。DeepSeek Harness 的 loop 文件里没有内建迭代上限，来源页推断上限被当作插件策略（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 优缺点和权衡

- **把错误交给模型**让 agent 能自己纠正，代价是占上下文、可能陷入反复尝试；所以需要迭代上限或 retry limit 兜底（[[2026-11-20-ai-harness-crash-course]]）。
- **自动重试**提高成功率，代价是时间和费用；对不可重试的错误重试只是浪费（[[2026-11-20-harness-engineering-go-practice]]）。
- **截断后不执行任何 tool call** 是保守选择：宁可多一轮，也不执行参数残缺的调用（[[2026-11-20-harness-engineering-go-practice]]）。
- **吞掉异常**让进程稳定，但调用方只能靠事件和 `turn/end` 的原因得知失败（[[2026-11-20-deepseek-harness-agent-loop-source]]，来源页记下的遗留问题）。

## 不同来源的分歧

> [!warning] 矛盾
> 同一门课程对"错误恢复是否单独成课"说法不同：learn-claude-code 网站首页列 20 课，s11 是 Error Recovery（[[2026-11-20-learn-claude-code-site]]）；仓库 README 的当前 17 课轨道里没有这一课（[[2026-11-20-learn-claude-code-readme]]）。两份都是 2026-11-20 的快照，无法从资料判断哪个更新。引用"s11"时必须注明轨道。

- **停止判据在截断时会分叉。** 一类最小 loop 用 `stop_reason != "tool_use"` 判停（[[2026-11-20-learn-claude-code-site]]、[[2026-11-20-openharness-readme]]），另一类用"响应里有没有 `tool_use` 块"（[[2026-11-20-learn-claude-code-readme]]）。来源页**推断**两者在输出被长度上限截断等边界情形下会分叉，资料本身没有讨论。笔者的进一步推断：截断时前者会直接停下，后者会去执行可能残缺的 tool call，所以两种写法都需要单独处理截断。
- **重试归谁。** 见上文三种做法；OpenHarness 说是 loop 的特性，DeepSeek Harness 把它排除在 loop 之外。
- **重试的粒度。** 本页多数来源讲的是单次模型请求的重试；AI Harness Crash Course 讲的是 workflow 节点级的 retry limit；OpenAI 团队讲的是 CI 层面 flaky test 重跑（[[2026-11-20-openai-harness-engineering]]）。三者不是一回事。

## 采用它的项目

- [[deepseek-harness]]：`agent/request-error` 事件、`ToolCallRecovery`、粘性 `max-tokens`（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- [[openharness]]：指数退避的 API 重试、MCP 自动重连（v0.1.5，2026-04-08）（[[2026-11-20-openharness-readme]]，自述）。
- [[claude-code]]：hook 的 exit code 2 回传 stderr（[[2026-11-20-hooks-in-claude-code]]）；重试与截断处理在本批资料中没有描述。
- [[learn-claude-code]]：网站轨道 s11 Error Recovery（[[2026-11-20-learn-claude-code-site]]）。
- [[microsoft-agent-framework]]：工具错误返回与迭代上限；重试策略本页文档未提及（[[2026-11-20-microsoft-learn-agent-harness]]）。

## 相关概念

[[agent-loop]]、[[tools]]、[[steering-and-cancel]]、[[session-log]]、[[compaction]]、[[verification-and-observability]]、[[long-running-agents]]、[[hooks]]、[[permissions]]、[[subagents]]。
