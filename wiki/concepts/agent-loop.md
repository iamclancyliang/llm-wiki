---
title: Agent loop
type: concept
aliases: [agentic loop, agent 循环, tool-call loop, ReAct loop, 智能体循环]
tags: [agent-loop, agent-harness, control-flow, stop-condition]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-openharness-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-what-is-claude-code
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-pi-readme
---

# Agent loop

## 定义

Agent loop 是 [[agent-harness|agent harness]] 的控制流核心：调用模型 → 模型要么给出最终回复，要么请求[[tools|工具]] → harness 执行工具并把结果追加回消息历史 → 再次调用模型，直到满足停止条件。[[anthropic|Anthropic]] 的说法是 agent "通常只是在循环中根据环境反馈使用工具的 LLM"（[[2026-11-20-anthropic-building-effective-agents]]），官方入门课把它说成"把一个 LLM 放进一个 loop 里"（[[2026-11-20-what-is-claude-code]]）。[[learn-claude-code]] 网站的论断是所有 AI 编程 agent 共享这同一个循环（[[2026-11-20-learn-claude-code-site]]）。

## 要解决的问题和动机

- 单次模型调用是文本进、文本出，做不了需要多步行动的任务。循环让模型能用上一步的真实结果决定下一步：跑构建脚本、看输出、再决定（[[2026-11-20-what-is-claude-code]]）。
- 每一步都要从环境拿到 ground truth（工具调用结果、代码执行结果）来评估进展（[[2026-11-20-anthropic-building-effective-agents]]）。失败的结果同样要回到模型眼前：Crash Course 的例子里，测试显示导出缺了一条记录，这条反馈回到模型后它才去排查（[[2026-11-20-ai-harness-crash-course]]）。
- 步数不可预测、无法硬编码路径的开放式问题才需要这种形态；代价是成本更高、错误会累积（[[2026-11-20-anthropic-building-effective-agents]]）。与预定义路径的对比见 [[workflows-vs-agents]]。

## 工作原理

### 最小循环

learn-claude-code README 给出的完整最小实现（Anthropic Messages API 形态，来源页的等价压缩写法）（[[2026-11-20-learn-claude-code-readme]]）：

```python
def agent_loop(messages):
    while True:
        response = client.messages.create(model=MODEL, system=SYSTEM,
                                          messages=messages, tools=TOOLS)
        messages.append({"role": "assistant", "content": response.content})
        tool_calls = [b for b in response.content if b.type == "tool_use"]
        if not tool_calls:
            return
        results = [{"type": "tool_result", "tool_use_id": b.id,
                    "content": TOOL_HANDLERS[b.name](**b.input)} for b in tool_calls]
        messages.append({"role": "user", "content": results})
```

三条不变式，Go 练习仓库用测试固定了下来：无工具调用时只调一次模型；工具结果必须作为 `tool` 消息回到历史且 ID 与请求对得上；模型无状态，历史由调用方持有，`Run` 接收历史并返回"输入加上新产生的全部消息"（[[2026-11-20-harness-engineering-go-practice]]）。历史只增不减，这是后面需要 [[context-management|上下文管理]]和 [[compaction]] 的原因（[[2026-11-20-learn-claude-code-site]]）。

### Turn 与 step

[[deepseek-harness|DeepSeek Harness]] 的默认 loop `ReactLoopAgent` 把循环分成三层（[[2026-11-20-deepseek-harness-agent-loop-source]]）：

- **driver**：idle 时收到唤醒才开始，反复执行 turn，直到 inbox 里没有待处理输入；异常在这一层被吞掉，agent 回到 idle。
- **turn**：对一次用户输入的完整处理，由若干 step 组成，日志里以 `turn/start`、`turn/end { reason }` 包围。
- **step**：组装请求 → 流式调用模型 → 落盘 assistant 消息 → 有 tool call 则执行整个工具批次。step 内还有一层请求重试循环。

> [!warning] 矛盾
> **"turn" 的粒度不一致。** Go 练习仓库把 turn 定义为"一次模型调用加它引发的一批工具执行"，`MaxTurns=3` 意味着恰好调用 3 次模型（[[2026-11-20-harness-engineering-go-practice]]）。DeepSeek Harness 把这个粒度叫 step，turn 是包含多个 step 的更大单位（[[2026-11-20-deepseek-harness-agent-loop-source]]）。跨资料比较"最大 turn 数"之类的参数时要先确认单位。

### 停止条件

两种常见判据：

| 判据 | 写法 | 使用者 |
|---|---|---|
| 看停止原因 | `if response.stop_reason != "tool_use": break` | learn-claude-code 网站首页（[[2026-11-20-learn-claude-code-site]]）、[[openharness\|OpenHarness]] README 的伪代码（[[2026-11-20-openharness-readme]]） |
| 看内容块 | 响应里没有 `tool_use` 块就返回 | learn-claude-code README（[[2026-11-20-learn-claude-code-readme]]）；DeepSeek Harness 以 assistant 消息里没有 `tool-call` 块作为 `completed` 的条件之一（[[2026-11-20-deepseek-harness-agent-loop-source]]） |

注意：网站首页那段代码是示意性的，没有把 assistant 消息追加回 `messages`，照抄不能工作（[[2026-11-20-learn-claude-code-site]]）。

两种判据正常情况下等价，但在输出被长度上限截断时会分叉。这一点是来源页的推断，两份 learn-claude-code 资料都没有讨论（[[2026-11-20-learn-claude-code-site]]）。按这一推断展开：截断时停止原因不是 `tool_use`，第一种写法会直接停下，留下半截输出；第二种写法若看到一个参数只写了一半的工具请求，会照常去执行它。有明确规格的是另外两份资料：

- Go 练习仓库：assistant 消息 `FinishReason == "length"` 且带工具调用时，一个都不执行，每个请求回一条提示模型"把内容拆小重来"的结果，循环继续。纯文本被截断（无工具调用）时怎么办没有测试覆盖（[[2026-11-20-harness-engineering-go-practice]]）。
- DeepSeek Harness：`max-tokens` 是独立的 turn 结束原因，并且是"粘性"的，之后的 step 正常完成也不能把 turn 结果降级回 `completed`（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

模型判定之外的停止原因：

| 原因 | DeepSeek Harness `TurnEndReason` | Go 练习仓库 `StopReason` |
|---|---|---|
| 模型不再请求工具 | `completed`（工具结果 `concluded` 为真也算，即工具可以宣告 turn 结束） | `completed` |
| 输出被截断 | `max-tokens` | 无对应项（截断在循环内处理） |
| 迭代上限 | 无（该文件没有 max-steps / max-turns） | `max-turns` |
| 被策略否决 | `blocked`（`agent/pre-step` 返回 reject） | 无对应项 |
| 取消 | `aborted`，附带 cancel cause | `aborted` |
| 其他失败 | `error` | `error` |

（[[2026-11-20-deepseek-harness-agent-loop-source]]、[[2026-11-20-harness-engineering-go-practice]]）

### 谁决定停止

模型的"不再请求工具"只是默认答案，各实现在它上面加了几种覆盖手段：

- **模型想停，harness 不让停**：完成门槛 `Verify` 在模型不再请求工具时运行，失败就把输出作为 user 消息交还，循环继续；排队的 steering 和 follow-up 消息同样会让循环再跑（[[2026-11-20-harness-engineering-go-practice]]）。DeepSeek Harness 在 turn 即将结束时串行触发 `agent/turn-stopping`，处理器往 next-step 队列塞消息就能续跑（[[2026-11-20-deepseek-harness-agent-loop-source]]）。learn-claude-code README 的 s17 Goal Loop 用独立 evaluator 审查每次"想停"（只有章节表里的一句话）（[[2026-11-20-learn-claude-code-readme]]）。[[microsoft-agent-framework|Microsoft Agent Framework]] 的 looping 是可选的、由 evaluator 或谓词驱动的有界重新调用（[[2026-11-20-microsoft-learn-agent-harness]]）。[[claude-code|Claude Code]] 有 `Stop` hook 事件，在 Claude 完成回复时触发，但它能否阻止停止，课程没有说明（[[2026-11-20-hooks-in-claude-code]]）。
- **模型不想停，harness 让它停**：迭代上限、取消、策略否决。Anthropic 建议加最大迭代次数之类的停止条件以保持控制（[[2026-11-20-anthropic-building-effective-agents]]）。
- **人随时介入**：Claude Code 的循环进行中，用户可以补充 context、打断或 steer（[[2026-11-20-how-claude-code-works]]）。输入在什么边界生效见 [[steering-and-cancel]]：DeepSeek Harness 的插话只在 step 边界被领取，不打断正在进行的流或工具批次（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 变体与演进

- **官方的三步叙述**：Claude Code 课程把循环讲成 gather context → take action → verify results，verify 是固定一步；它具体靠什么完成，课程没有说明（[[2026-11-20-how-claude-code-works]]、[[2026-11-20-claude-code-101-course]]）。
- **从消息数组到事件日志**：最小循环自己持有 `messages[]`；DeepSeek Harness 的每个请求都从只追加的 [[session-log|session log]] 派生，loop 不持有消息历史（[[2026-11-20-deepseek-harness-agent-loop-source]]）。Microsoft 的 Harness 在一次带工具调用的 run 里每次模型调用后都持久化历史（[[2026-11-20-microsoft-learn-agent-harness]]）。
- **循环不变、机制外挂**：learn-claude-code 的主张是工具注册进 dispatch map、[[hooks]] "围着循环挂，不改循环"（[[2026-11-20-learn-claude-code-readme]]）。Go 练习仓库更进一步，重试器自己实现 `Model` 接口包在模型外面，循环完全不知道它存在（[[2026-11-20-harness-engineering-go-practice]]）。
- **嵌套**：把"再开一个循环"包装成一个工具就是 [[subagents|subagent]]（[[2026-11-20-harness-engineering-go-practice]]）。

## 优缺点和权衡

- 核心判定确实只有几行，但生产实现的复杂度在别处：DeepSeek Harness 这个文件约 700 行，花在状态机、日志一致性、取消语义上（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- 取消和失败后必须保持历史合法：一批工具执行到一半被取消，没执行的每个请求也要补一条结果，否则带着这份历史再调模型会报错（[[2026-11-20-harness-engineering-go-practice]]）；DeepSeek Harness 用 `ToolCallRecovery` 给悬空的 tool call 补写结果（[[2026-11-20-deepseek-harness-agent-loop-source]]）。见 [[error-recovery]]。
- 没有上限的循环可能不自行停止；上限太紧又会截断正常的长任务。Go 练习仓库的长任务入口把"单个会话用完 turn 数"不算失败，因为进度在磁盘上（[[2026-11-20-harness-engineering-go-practice]]）。

## 不同来源的分歧

> [!warning] 矛盾
> **迭代上限是否内建。** Microsoft 的 function invocation 每次请求有可配置的迭代上限（默认值未给出）（[[2026-11-20-microsoft-learn-agent-harness]]）；OpenHarness 有 `--max-turns`（[[2026-11-20-openharness-readme]]）；Go 练习仓库有 `MaxTurns`（[[2026-11-20-harness-engineering-go-practice]]）。DeepSeek Harness 的 loop 文件里没有任何 max-steps 或 max-turns；来源页推断上限被当作插件策略，是否有默认插件兜底未知（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

> [!warning] 矛盾
> **停止由谁说了算。** learn-claude-code README："停不停由模型决定，代码只执行"（[[2026-11-20-learn-claude-code-readme]]）。AI Harness Crash Course：harness 管理"何时继续、何时停止、何时求助"，retry limit 用尽时 workflow 停下并求助（[[2026-11-20-ai-harness-crash-course]]）。上面"谁决定停止"一节列出的机制说明，多数实现实际落在两者之间。

**职责边界**，即 loop 自己管多少：

| 实现 | loop 内做什么 | loop 外做什么 |
|---|---|---|
| OpenHarness（README 伪代码，非源码） | 逐个工具调用走"权限检查 → PreToolUse hook → 执行 → PostToolUse hook" | —（[[2026-11-20-openharness-readme]]） |
| Go 练习仓库 | `Run` 的 `Options` 里挂权限、hooks、压缩触发、验证、队列，零值即关闭；权限在前、hook 在后 | 重试包在模型外面（[[2026-11-20-harness-engineering-go-practice]]） |
| DeepSeek Harness | 只管边界、日志和取消传播 | 工具批次整体交给工具服务；重试由 `agent/request-error` 的订阅者决定；压缩是 idle 时才能进入的维护作业（[[2026-11-20-deepseek-harness-agent-loop-source]]） |
| Microsoft Agent Framework | Harness 不另造循环；Go 包明确"不引入单独的工具执行循环" | 工具调用循环由 chat pipeline 或 provider 构造函数持有；审批和有界循环在 middleware（[[2026-11-20-microsoft-learn-agent-harness]]） |

DeepSeek Harness 里权限检查在工具服务内部、工具级钩子在工具服务一侧，这两点都是来源页的推断（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 采用它的项目

[[claude-code|Claude Code]]（[[2026-11-20-how-claude-code-works]]）、[[openharness|OpenHarness]] 的 `engine/`（[[2026-11-20-openharness-readme]]）、[[deepseek-harness|DeepSeek Harness]] 的 `packages/core/agent-loop`（[[2026-11-20-deepseek-harness-agent-loop-source]]）、[[pi|Pi]] 的 `pi-agent-core`（README 只说它负责 tool calling 与状态管理，不讲实现）（[[2026-11-20-pi-readme]]）、[[learn-claude-code]] 的 s01（[[2026-11-20-learn-claude-code-readme]]）、[[microsoft-agent-framework|Microsoft Agent Framework]]（[[2026-11-20-microsoft-learn-agent-harness]]）。

## 相关概念

[[agent-harness]]、[[tools]]、[[workflows-vs-agents]]、[[steering-and-cancel]]、[[error-recovery]]、[[session-log]]、[[context-management]]、[[compaction]]、[[hooks]]、[[permissions]]、[[subagents]]、[[verification-and-observability]]、[[long-running-agents]]、[[planning-and-plan-mode]]
