---
title: Hooks（生命周期钩子）
type: concept
aliases: [hook, 钩子, 生命周期钩子, lifecycle hooks, PreToolUse, PostToolUse]
tags: [agent-harness, hooks, extensibility, deterministic-control]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-the-claude-md-file
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-openharness-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-pi-readme
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-openai-harness-engineering
---

# Hooks（生命周期钩子）

## 定义

hooks（生命周期钩子）是 [[agent-harness|agent harness]] 在 [[agent-loop|agent loop]] 的固定节点上留出的插入点：到了这个节点，harness 一定会运行用户或插件注册的代码，由这段代码观察、改写或否决 loop 接下来要做的事。[[claude-code|Claude Code]] 的官方表述是"在生命周期的不同节点运行命令"（[[2026-11-20-hooks-in-claude-code]]）；learn-claude-code 的表述是"围着循环挂，不改循环"（"Hook around the loop, never rewrite the loop"；[[2026-11-20-learn-claude-code-readme]]）。

## 要解决的问题和动机

- **确定性**：写进 `CLAUDE.md`（[[context-files|context file]]）的指令由模型决定是否照做，官方视频说要求"每次编辑后跑 prettier"时 Claude 多数时候会做、有时不会；hook 由 harness 执行，每次必定发生。结语是"必须每次都发生的事，不要放进 prompt，放进 hook"（厂商自述，没有给出遵守率数据；[[2026-11-20-hooks-in-claude-code]]）。课程大纲把 hooks 定位为"确定性护栏"（[[2026-11-20-claude-code-101-course]]）。
- **横切行为不进循环**：格式化、日志、拦截这类行为如果写进 loop，loop 会越来越乱。learn-claude-code 网站的一句话是"横切行为放在循环周围，不要缠进循环里"（[[2026-11-20-learn-claude-code-site]]）。
- **让第三方能改 loop 的决定**：[[deepseek-harness|DeepSeek Harness]] 的 loop 源码把"插件在哪些点可以改写或否决 loop 的决定"当作要回答的问题之一（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 工作原理

### 事件类型与粒度

各项目暴露的事件粒度不同，大致分两类：

**工具级**（围绕单次工具调用）：

| 项目 | 事件 | 来源 |
|---|---|---|
| [[claude-code\|Claude Code]] | `PreToolUse`（tool call 执行前）、`PostToolUse`（完成后） | [[2026-11-20-hooks-in-claude-code]] |
| [[openharness\|OpenHarness]] | `PreToolUse` / `PostToolUse`（沿用 Claude Code 的命名，项目自述） | [[2026-11-20-openharness-readme]] |
| [[learn-claude-code]] s04 | `PreToolUse` / `PostToolUse` | [[2026-11-20-learn-claude-code-readme]] |
| Go 练习仓库 | `BeforeToolCall`、`AfterToolCall` | [[2026-11-20-harness-engineering-go-practice]] |

**会话、turn 与 step 级**（围绕一次请求或一轮循环）：

| 项目 | 事件 | 作用 | 来源 |
|---|---|---|---|
| Claude Code | `UserPromptSubmit` | 用户提交 prompt 后、Claude 处理之前 | [[2026-11-20-hooks-in-claude-code]] |
| Claude Code | `Notification` | Claude 发出通知时 | [[2026-11-20-hooks-in-claude-code]] |
| Claude Code | `Stop` | Claude 完成回复时 | [[2026-11-20-hooks-in-claude-code]] |
| Go 练习仓库 | `TransformContext` | 只改"这一次发给模型的历史"，不改循环保存的历史 | [[2026-11-20-harness-engineering-go-practice]] |
| [[deepseek-harness\|DeepSeek Harness]] | `agent/pre-step` | 改写本 step 的输入消息，或 `reject` 使 turn 以 `blocked` 结束 | [[2026-11-20-deepseek-harness-agent-loop-source]] |
| DeepSeek Harness | `agent/request` | 提议请求配置，但不允许改 provider、model 或 reasoning effort | [[2026-11-20-deepseek-harness-agent-loop-source]] |
| DeepSeek Harness | `agent/request-error` | 决定失败的模型请求是否重试（见 [[error-recovery]]） | [[2026-11-20-deepseek-harness-agent-loop-source]] |
| DeepSeek Harness | `agent/turn-stopping` | turn 即将结束，处理器可往 next-step 队列塞消息让 turn 继续 | [[2026-11-20-deepseek-harness-agent-loop-source]] |

- Claude Code 的五个事件名是来源页根据转录读音还原的写法；视频没有说这五个是否为全集（[[2026-11-20-hooks-in-claude-code]]）。
- DeepSeek Harness 的 loop 文件里没有 PreToolUse / PostToolUse 级别的事件；工具级钩子是否在工具服务一侧，来源页标为推断（[[2026-11-20-deepseek-harness-agent-loop-source]]）。它另有只通知不干预的事件：`agent/status`、`agent/assistant-stream`、`agent/error`。
- `agent/turn-stopping` 与 Claude Code 的 `Stop` hook 类似，这是来源页的推断；视频没有说 `Stop` hook 能否阻止或改写行为（[[2026-11-20-deepseek-harness-agent-loop-source]]、[[2026-11-20-hooks-in-claude-code]]）。

### 配置方式

- **Claude Code**：在 `settings.json` 里配置，三个要素是 event、可选的 matcher（限定适用于哪些[[tools|工具]]）、要运行的 command；也可以通过 `/hooks` 配置。项目级 settings 文件里的 hooks 可以提交进仓库，全团队自动获得相同的 hooks；command 里用环境变量 `CLAUDE_PROJECT_DIR` 引用项目内的脚本，这样不受当前工作目录影响（[[2026-11-20-hooks-in-claude-code]]）。
- **OpenHarness**：`hooks/` 是固定子系统；插件可以通过 `hooks/hooks.json` 携带 hooks（项目自述；[[2026-11-20-openharness-readme]]）。
- **Go 练习仓库**：hooks 是 `Options` 里的 Go 函数字段，留空即不启用（[[2026-11-20-harness-engineering-go-practice]]）。
- **DeepSeek Harness**：loop 在构造时建好一个"融合 dispatcher"，按 emit、waterfall、serial 三种方式分发事件（[[2026-11-20-deepseek-harness-agent-loop-source]]）。从用法看，emit 只通知，waterfall 让处理器改写或否决一个决定，serial 让处理器逐个串行执行；这三条语义是笔者按源码用法作的归纳，dispatcher 的实现不在已摄入的文件里。

### 协议：hook 怎样把决定告诉 loop

- **Claude Code 的退出码协议**：`PreToolUse` hook 从 stdin 收到 JSON 形式的 tool name 和 input。exit code `0` 放行；exit code `2` 阻止该动作，stderr 的内容反馈给 Claude，让它知道为什么被拦并调整。非 0 非 2 的退出码如何处理，视频没有说明（[[2026-11-20-hooks-in-claude-code]]）。
- **Go 练习仓库的返回值协议**：`BeforeToolCall` 返回非 nil 即拦截，`Block.Reason` 成为工具结果；`AfterToolCall` 返回改写后的结果（[[2026-11-20-harness-engineering-go-practice]]）。

```go
type Hooks struct {
    BeforeToolCall   func(ctx context.Context, call llm.ToolCall) *Block
    AfterToolCall    func(ctx context.Context, call llm.ToolCall, output string) string
    TransformContext func(ctx context.Context, messages []llm.Message) []llm.Message
}
```
（出处：Go 练习仓库 `agent/` 包，转引自 [[2026-11-20-harness-engineering-go-practice]]）

两种协议的共同点：拦截的理由要回到模型眼前，而不是让调用悄悄消失。

### hook 与权限的先后

- [[permissions|权限]]在前，hook 在后。OpenHarness 的 loop 伪代码写的是"Permission check → Hook → Execute → Hook → Result"（示意伪代码；[[2026-11-20-openharness-readme]]）；Go 练习仓库的测试约定权限已拒绝的调用不再触发 `BeforeToolCall`（[[2026-11-20-harness-engineering-go-practice]]）。
- Claude Code 自身两者的先后，本批资料没有说明。

## 典型用途

- **编辑后自动格式化**（官方称"最常见的 hook"）：`PostToolUse` hook，matcher 为 `Edit` 或 `MultiEdit`，command 按文件扩展名运行 prettier、gofmt 或 ruff（[[2026-11-20-hooks-in-claude-code]]）。
- **阻止危险操作**：`PreToolUse` hook 阻止写入生产配置目录、阻止含 `rm -rf` 的 bash 命令（[[2026-11-20-hooks-in-claude-code]]）。
- **合规日志**：记录所有执行过的命令（[[2026-11-20-hooks-in-claude-code]]）。
- **通知**：Claude 完成任务时发通知（[[2026-11-20-hooks-in-claude-code]]）。
- **脱敏**：Go 练习仓库的测试用 `AfterToolCall` 把输出里的密钥抹掉，并断言模型下一次调用看不到原文（[[2026-11-20-harness-engineering-go-practice]]）。
- **续跑与步数上限**：DeepSeek Harness 的 loop 没有内建 max-steps；限制步数只能由 pre-step 处理器 `reject` 或以 `hook` 为 cause 调用 `cancel`（"上限被当作插件策略"是来源页的推断；[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 变体与演进

- **外部命令 vs 进程内函数**：Claude Code 的 hook 是一条 shell command，靠 stdin 和退出码通信（[[2026-11-20-hooks-in-claude-code]]）；Go 练习仓库和 DeepSeek Harness 的 hook 是进程内的函数或事件处理器（[[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- **hook 作为插件系统的地基**：DeepSeek Harness 里事件就是插件介入 loop 的方式，见 [[plugins-and-extensibility]]。
- **没有 hooks 的框架**：[[microsoft-agent-framework|Microsoft Agent Framework]] 的 Harness 文档没有描述 hooks 式的生命周期事件，审批处理和可观测性由 middleware 承担；不能据此断定框架不支持，只能说该页未提及（[[2026-11-20-microsoft-learn-agent-harness]]）。
- [[pi|Pi]] 的 README 不描述 hooks 或 extension 的事件模型（[[2026-11-20-pi-readme]]）。

## 优缺点和权衡

- 优点是确定性和团队共享：规则提交进仓库后人人一致（[[2026-11-20-hooks-in-claude-code]]）。
- hook 只在它挂的事件上生效。只暴露工具级事件的 harness，拦不住"模型想停"这一刻；只暴露 step 级事件的 loop，要靠别处提供工具级拦截（笔者推断，依据是上面两张事件表）。
- "规则写成代码还是写成 prompt"是更一般的取舍，hook 是其中一种落点。Go 练习仓库在长任务部分的注释是"提示词是请求，模型可能不照做；代码是规则，模型绕不过去"（[[2026-11-20-harness-engineering-go-practice]]）；[[openai|OpenAI]] 团队的做法是"文档不够时，把规则变成代码"，落点是自定义 linter 而不是 hook（[[2026-11-20-openai-harness-engineering]]）；Anthropic 的长时运行实验则只用强措辞 prompt 约束"只改 `passes` 字段"，没有用 hooks 或权限机制做硬约束（后半句是来源页的观察；[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

## 不同来源的分歧

> [!warning] 矛盾
> `CLAUDE.md` 里的指令是否每次都被遵守，Anthropic 同一门课的两个视频说法不同：
> - Hooks 一课：`CLAUDE.md` 里的指令"不完美"，Claude 多数时候会做、有时不会（[[2026-11-20-hooks-in-claude-code]]）。
> - CLAUDE.md 一课：把纠正保存到 memory 后，下次回到项目时 Claude 就知道（[[2026-11-20-the-claude-md-file]]）。
>
> 两者可以调和（"知道"不等于"每次照做"），但资料没有明说；两边都没有数据。

- **粒度**：Claude Code 视频列了五个事件，OpenHarness 和 learn-claude-code 只提两个工具级事件，DeepSeek Harness 的 loop 只有 step 与 turn 级事件（[[2026-11-20-hooks-in-claude-code]]、[[2026-11-20-openharness-readme]]、[[2026-11-20-learn-claude-code-readme]]、[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- **命名的出处存疑**：Go 练习仓库的注释说三个插入点的名字与 Pi 保持一致，但 Pi 的 README 不含事件模型，本批资料无法核实（[[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-pi-readme]]）。
- **归类**：learn-claude-code 网站把 Hooks 放在 "Tools & Execution" 层（[[2026-11-20-learn-claude-code-site]]）；官方课程把它放在"定制"一章（[[2026-11-20-claude-code-101-course]]）。

## 采用它的项目

[[claude-code|Claude Code]]（[[2026-11-20-hooks-in-claude-code]]）、[[openharness|OpenHarness]]（[[2026-11-20-openharness-readme]]）、[[learn-claude-code]] s04（[[2026-11-20-learn-claude-code-readme]]）、Go 练习仓库（规格与测试，实现待完成；[[2026-11-20-harness-engineering-go-practice]]）、[[deepseek-harness|DeepSeek Harness]]（事件形式；[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 相关概念

[[permissions]]、[[plugins-and-extensibility]]、[[context-files]]、[[tools]]、[[agent-loop]]、[[error-recovery]]、[[steering-and-cancel]]、[[verification-and-observability]]；横向比较见 [[开源-harness-设计取向对比]]。
