---
title: DeepSeek Harness agent loop 源码（packages/core/agent-loop/src/agent.ts）
type: source
kind: repo
aliases: [ReactLoopAgent, dsh-agent-loop, DeepSeek Harness agent.ts]
tags: [agent-harness, agent-loop, repo, typescript, source-code]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/github-deepseek-harness-agent-loop-agent-ts.md
author: DeepSeek-AI
published:
url: https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/core/agent-loop/src/agent.ts
---

# DeepSeek Harness agent loop 源码（agent.ts）

> 资料性质：GitHub 文件页导出的纯文本，导出日期 2026-11-20。文件 751 行（715 loc，30.5 KB），master 分支，最新提交 `dd54a74`（"refactor(agent): require lifetime signal and cover teardown wakes"，页面显示"2 weeks ago"）。导出把整个文件压成了少数几行，但代码完整可读。本页所有"代码里是这样"的陈述都直接来自该文件；涉及文件之外模块（`inbox.ts`、`dsh-tools`、`dsh-session` 等）的行为均标为推断。片段为排版后的节选。

## 一段话概括

这是 [[deepseek-harness|DeepSeek Harness]] 默认的 [[agent-loop|agent loop]] 实现 `ReactLoopAgent`。文件头注释概括了它的两个设计核心："Default Agent driver over queued turns and step-boundary input. Every request is derived from the session log."——（1）输入不是直接塞进消息数组，而是进 inbox 队列，只在 turn 或 step 的**边界**被领取；（2）发给模型的每个请求都从 [[session-log|session log]]（只追加的事件日志）**派生**，loop 自己不持有消息历史。循环分三层：driver（`kick`）→ turn → step，step 内还有一层请求重试循环。

## 解决什么问题

朴素 loop（`while stop_reason == tool_use`）没有回答的几件事，这个文件逐一给了结构化答案：运行中途用户插话该何时生效；取消后未完成的工具调用和半截输出怎么落盘；失败后日志如何保持可恢复；维护作业（如压缩）与模型 turn 如何互斥；插件在哪些点可以改写或否决 loop 的决定。

## 架构与关键设计决策

### 状态：三态 Phase

```ts
type Phase =
  | { kind: 'idle'; lastTurn: number }
  | { kind: 'maintenance'; abort: AbortController; lastTurn: number; wakeRequested: boolean }
  | { kind: 'running'; abort: AbortController; turn: number; step: number; wakeRequested: boolean }
```

- 对外状态 `status` 只有 `idle | running`；`maintenance` 对外也报告 `idle`。`setPhase` 只在对外状态变化时发 `agent/status` 事件。
- 每个 turn 有自己的 `AbortController`；一个 turn 结束、队列里还有输入时换一个新的 controller 再开下一个 turn。
- `wakeRequested` 是"唤醒锁存"：维护期间或已被 abort 的活动无法交付唤醒，就先记下，收敛后重放。
- 构造函数要求传入 `lifetimeSignal`；它 abort 后 `wakeDriver` 直接返回，保证销毁时不再启动新的模型 turn。
- 其余实例状态都是"投影"而非历史副本：`requestHeaderLogged`、`requestSurfaceGeneration`、`RuntimeContextProjection`、`SystemPromptProjection`、流式帧计数器、已冻结消息的 `WeakSet`。

### 控制流：driver → turn → step

**driver（`wakeDriver` / `kick`）**：idle 时收到唤醒才进入 `running`，然后 `while (await this.turn()) {}`。`kick` 的 `catch` 吞掉异常（注释：已上报的失败和取消在 driver 边界被 contain），`finally` 回到 `idle`，若有锁存的唤醒且 inbox 非空则再启动一次。driver 通过 `loopCtx.agents.withInitiator(this, …)` 运行。

**turn（`turn()`）** 的骨架：

1. 追加 `turn/start`。
2. 循环：`preStep` 领取输入并做准入 → 追加 `step/start` → `step()` → 追加 `step/end` → 释放本 step 的 `toolSet`。
3. turn 有了结束原因且 `inbox.nextStep` 为空时，串行触发 `agent/turn-stopping`；触发后**再检查一次**队列，仍为空才 break。也就是说，turn-stopping 的处理器可以通过往 next-step 队列塞消息让 turn 继续（类似 [[claude-code|Claude Code]] 的 Stop hook，这一类比是我的推断）。
4. `finally` 里一定追加 `turn/end { turn, reason }`。
5. 返回值：inbox 还有待处理输入则返回 `true`（开下一个 turn），否则 `false`。

**step（`step()`）**：组装请求 → 流式调用模型 → 落盘 assistant 消息 → 有 tool call 则执行工具批次。返回 `{kind:'completed'}`、`{kind:'max-tokens'}` 或 `null`（`null` 表示需要下一个 step）。

### 停止条件

`TurnEndReason` 在这个文件里出现五种：

| reason | 触发位置 |
|---|---|
| `completed` | assistant 消息里没有 `tool-call` 块；或 `tools.execute` 的结果 `concluded` 为真（工具可以宣告 turn 结束）；或首个 step 没有任何消息可发（不花模型调用） |
| `max-tokens` | 流的 `finish.kind === 'max-tokens'`。它是"粘性"的：之后的 step 正常完成也不能把 turn 结果降级回 completed |
| `blocked` | `agent/pre-step` 的决定是 `reject` |
| `aborted` | turn 的 signal 被 abort，附带 cancel cause |
| `error` | 其他异常，结构化为 `LlmError.failure` 或 `{ message, code }`（`ToolActivationError` 保留其 code，其余为 `UNKNOWN`） |

值得注意：**这个文件里没有 max-steps / max-turns 之类的迭代上限**。限制步数只能由 pre-step 处理器 reject，或以 `hook` cause 调用 `cancel` 来实现（推断：上限被当作插件策略而非 loop 内建）。

### 输入、插话与取消

三个入口都落到 `send(message, target, wakeup)`（见 [[steering-and-cancel]]）：

| 方法 | 队列 | 是否唤醒 | 语义 |
|---|---|---|---|
| `followup` | `next-turn` | 是 | 当前 turn 结束后作为新 turn 处理 |
| `steer` | `next-step` | 是 | 在下一个 step 边界并入当前 turn |
| `inject` | `next-step` | 否 | 同上，但不会唤醒空闲的 agent |

- 插话**不打断**正在进行的流或工具批次，只在 step 边界被 `inbox.claim` 领取——这是"边界式 steering"。
- 如果要求唤醒时当前活动已被 abort，`next-step` 会被改判为 `next-turn`（注释：唤醒输入不能加入一个已 abort 的活动）。
- `cancel(cause, { keepInbox })`：默认先清空 inbox，再在 `finally` 里 abort 当前 controller（注释：队列持久化失败不得阻止取消已准入的工作）。cause 是封闭联合：`user | parent | disposed | hook(reason)`。`parent` 暗示父 agent 可取消子 agent（与 [[subagents|subagent]] 相关，推断）；`hook` 允许插件带理由取消。
- cancel cause 写入 `turn/end` 前只拷贝白名单字段，因为 Node 的 fetch 会往 abort reason 上挂 `stack`，直接落盘会污染日志。
- 取消的传播方式是到处 `signal.throwIfAborted()`：每个 await 之后、每个流 chunk 之后都检查，同一个 signal 也传给工具解析、prompt 组装、LLM 调用和工具执行。

### 请求构造：一切从 session log 派生

- `preStep`：`inbox.claim` → 取当前 model selection（没有则抛错）→ `tools.resolve` 得到本 step 的 `toolSet` → `systemPrompt.assemble` → waterfall 事件 `agent/pre-step`（默认实现是把运行时上下文段渲染成一条消息附在领取到的消息之后）。
- `prepareRequest`：waterfall 事件 `agent/request` 让插件提议请求配置，但**不允许**在此改 provider、model 或 reasoning effort——改了就抛错，并提示"应在 step 准备之前用 `agent.model.select()`"。
- `buildRequest`：把 `{ config, adapterDefaults, tools }` 规范化为 header，与日志里的基线比较，按 `initial / resume / change / series` 追加 `request/header`；工具集增减会追加一条来源为 `tool-registry` 的 `developer/message`（`tool-addition` / `tool-removal`），让模型知道工具变了；provider、model、`contextWindow`、`systemPromptUpdate` 变化时追加 `request/context`。
- 最终消息来自 `session.deriveMessages()`，并被 `deepFreeze`：

```ts
const request = markAgentLoopRequest(Object.freeze({
  ...header.config,
  messages: boundaryMessages,          // session.deriveMessages()
  toolHistory: session.toolHistory(),
  ...(header.tools !== undefined ? { tools: header.tools } : {}),
  sessionId: this.session.id,
  signal,
}))
```

- [[system-prompt|system prompt]] 也是投影：`SystemPromptProjection.project` 产出需要提交的变更，以 `system/message` 事件写入日志；适配器可以声明 `systemPromptUpdate === 'in-history'`（在历史中更新而非替换）。这些机制的目的应是保持请求前缀稳定以利于 prompt cache（推断，文件中没有明说）。

### 工具执行

```ts
const result = await this.loopCtx.tools.execute({
  calls: toolCalls, signal, agent: this, log: { turn, step },
  maxParallelToolCalls, toolSet: decision.toolSet,
})
for (const context of result.additionalContexts)
  this.inbox.splice('next-step', this.inbox.nextStep.length, 0, [context])
return result.concluded ? { kind: 'completed' } : null
```

- 一个 step 的全部 tool call 作为一个批次交给 [[tools|工具]]服务，并发度由配置 `maxParallelToolCalls` 控制；loop 本身不逐个调用工具。
- `toolSet` 在 pre-step 解析、step 结束后 dispose：声明给模型的工具和实际可分发的工具用的是同一份"准入"，不会出现声明了却调不到的情况。
- 工具可以返回 `additionalContexts`，被排进 next-step 队列，下一个 step 作为用户侧消息进入——工具向模型追加上下文走的是和 steering 同一条通道。
- [[permissions|权限]]检查不在这个文件里；推断在 `tools.execute` 内部或由其他插件承担。

### 错误处理与恢复

见 [[error-recovery]]。几个具体机制：

- **模型请求失败不在 loop 里重试，而是询问插件**：流结束为 `error` 或 `aborted` 时，先追加 `assistant/attempt`（失败的尝试也留痕），再 waterfall `agent/request-error`，传入 `failure` 和适配器的 `retryPolicy`；只有返回 `{ kind: 'retry' }` 才 `continue` 重新组装请求，否则抛 `LlmError`。退避、次数上限都不在此文件。
- **半截输出不丢**：流已开始后被 abort，若已有内容块，则以 `interrupted: true` 追加 `assistant/message`（含 usage）；否则只记 `assistant/attempt`。
- **悬空 tool call 补结果**：每个 step 用 `ToolCallRecovery` 监听 `session/event`；step 抛错时，把尚未有结果的 tool call 补写成 `tool/result` 事件，保证日志里每个 tool call 都有配对结果，之后的请求仍然合法。
- **工具批次部分失败**：`ToolBatchExecutionError` 携带 `partial.additionalContexts`，先入队再抛出原始 cause。
- 落盘本身失败时用 `AggregateError` 同时保留原始错误和落盘错误。
- 失败在发生的边界通过 `agent/error { turn, step, error }` 上报一次，然后由 driver 吞掉；agent 回到 idle，不会让进程崩溃。

### 事件与钩子点

loop 通过一个在构造时建好的"融合 dispatcher"发事件（见 [[hooks]]、[[plugins-and-extensibility]]）：

| 事件 | 方式 | 作用 |
|---|---|---|
| `agent/status` | emit | idle / running 切换 |
| `agent/pre-step` | waterfall | 改写本 step 的输入消息，或 `reject` 使 turn 以 `blocked` 结束 |
| `agent/request` | waterfall | 提议请求配置（不可改 provider/model/effort） |
| `agent/assistant-stream` | emit | 流式帧，供 UI 渲染 |
| `agent/request-error` | waterfall | 决定是否重试 |
| `agent/turn-stopping` | serial | turn 即将结束，可塞入 next-step 消息续跑 |
| `agent/error` | emit | 失败上报 |

写入 session log 的事件类型：`turn/start`、`turn/end`、`step/start`、`step/end`、`system/message`、`user/message`、`assistant/message`、`assistant/attempt`、`tool/result`、`developer/message`、`request/header`、`request/context`。这份日志同时是恢复依据和[[verification-and-observability|可观测性]]数据源。注意：这里没有 PreToolUse / PostToolUse 级别的事件，工具级钩子应在工具服务一侧（推断）。

### 上下文压缩与维护

- 本文件**不实现** [[compaction|上下文压缩]]，只提供与它协作的接口（属于 [[context-management]] 的边界设计）：
  - `runMaintenance(job)`：仅在 `idle` 时可进入，否则抛 "already has active work"；维护期间到来的唤醒被锁存，作业结束后若 inbox 非空再启动 driver。压缩很可能就是这样一种维护作业（推断）。
  - `session.surface.contentGeneration`：loop 记住上次构造请求时的 surface 代数，变化了就把下一个请求标为新 series（`startsSeries`）并重新提交 system prompt。代码注释直接提到："Compaction during the first resumed pre-step must still mark a new series."
  - `request/context` 记录 `contextWindow`，供别处判断何时该压缩（推断）。
- 运行时上下文（时间、环境等动态段）通过 `RuntimeContextProjection` 以 `user/message` 追加，每次重试前 `refreshContext`，而不是改写 system prompt。

## 适用与不适用场景

- 适合作为"事件溯源式 agent loop"的参考实现：需要可恢复、可审计、支持中途插话和干净取消的 [[long-running-agents|长时间运行 agent]]。
- 不适合直接拿来当入门示例：它依赖 Cordis 上下文、session、tools、llm、system-prompt 等多个服务，单看这一个文件跑不起来；策略（重试、步数上限、权限、压缩）都在文件之外。

## 成熟度

- 所属仓库处于 developer preview（见同批来源页 `2026-11-20-deepseek-harness-readme`），接口会变。
- 代码中有多处 `v8 ignore` 覆盖率注释和 `assertNever` 穷尽检查，说明该文件有较严格的覆盖率与类型约束（观察）。最近一次提交仍在调整销毁与唤醒语义。

## 与已有知识的关系

- 补充：给 [[agent-harness]] 中"loop 很简单"的常见说法加了一个反例维度——核心判定（有无 tool call）确实简单，但状态机、日志一致性和取消语义占了 700 行。
- 对照：[[openharness|OpenHarness]] README 的伪代码把"权限 → hook → 执行 → hook"写在 loop 里；这里 loop 只管边界和日志，工具管线整体外包给工具服务。

## 局限与遗留问题

- `ReactLoopInbox`（`inbox.ts`）的持久化方式、`claim` 的原子性未见；`AssistantStreamAttempt`、`RuntimeContextProjection` 也只看到用法。
- `tools.execute` 内部如何做权限确认、并发调度、`concluded` 由什么工具触发，未知。
- 谁订阅 `agent/request-error` 并实现退避重试、谁实现压缩并调用 `runMaintenance`，需要读对应插件。
- 没有内建步数上限，若没有插件兜底，模型持续发 tool call 时 turn 不会自行停止——是否有默认插件提供该保护，未知。
- `kick` 吞掉异常后，调用方只能靠 `agent/error` 事件和 `turn/end` 的 reason 得知失败；`whenIdle()` 不会 reject。这对上层编排（如父 agent 等待子 agent）意味着什么，待查。
