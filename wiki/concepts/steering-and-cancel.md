---
title: Steering and cancel（运行中插话与取消）
type: concept
aliases: [steering, 插话, 运行中插话, cancel, 取消, interrupt, 打断, follow-up, next-turn, next-step, message injection]
tags: [agent-harness, agent-loop, steering, cancellation]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-openharness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-hooks-in-claude-code
---

# Steering and cancel（运行中插话与取消）

## 定义

- **Steering（插话）**：[[agent-loop|agent loop]] 还在运行时，从外部往里加输入，使 agent 改变方向，而不必等它停下。输入的来源不只是用户，也可以是工具、后台任务或插件。
- **Follow-up（后续消息）**：排队等 agent 做完手头的事再处理的输入。
- **Cancel（取消）**：让正在进行的工作停下，并把会话留在可以继续的状态。

[[claude-code|Claude Code]] 的官方课程把它列为 loop 的基本性质：循环进行中，用户可以随时补充 context、打断或 steer 模型（[[2026-11-20-how-claude-code-works]]）；课程落地页把"在 agent 走偏时如何引导"列为必须理解的三件事之一（[[2026-11-20-claude-code-101-course]]，厂商自述）。

## 要解决的问题和动机

最小的 loop（`while` 到模型不再请求工具为止）没有回答三个问题（[[2026-11-20-deepseek-harness-agent-loop-source]]）：

1. 运行中途用户插话，该在什么时候生效？
2. 取消之后，未完成的工具调用和半截输出怎么落盘？
3. 失败或取消后，日志如何保持可恢复？

难点在于模型接口对历史结构有硬性要求：一条消息不能插进 tool 请求和它的结果之间，每个 tool 请求都必须有结果（[[2026-11-20-harness-engineering-go-practice]]）。所以"随时"插话在实现上必然是"在某个合法的边界"插话。

## 工作原理

### 两个队列

两份有实现细节的资料都用两个语义不同的队列，但命名和粒度不同。

**[[deepseek-harness|DeepSeek Harness]]**（`ReactLoopAgent`，step = 一次模型调用加它引发的工具批次，turn = 若干 step）（[[2026-11-20-deepseek-harness-agent-loop-source]]）：

| 方法 | 队列 | 是否唤醒空闲的 agent | 语义 |
|---|---|---|---|
| `followup` | `next-turn` | 是 | 当前 turn 结束后作为新 turn 处理 |
| `steer` | `next-step` | 是 | 在下一个 step 边界并入当前 turn |
| `inject` | `next-step` | 否 | 同上，但不会唤醒空闲的 agent |

**Go 练习仓库**（turn = 一次模型调用加它引发的一批工具执行）（[[2026-11-20-harness-engineering-go-practice]]）：

| 队列 | 何时取 | 语义 |
|---|---|---|
| `Steering` | 每个 turn 结束后取一次 | 尽快并入当前工作 |
| `FollowUp` | 只在 agent 本来要停下时取 | 等手头的事做完 |

> [!warning] 矛盾
> 两份资料的 "turn" 不是同一个粒度：Go 练习仓库的 turn（一次模型调用 + 一批工具）对应 DeepSeek Harness 的 **step**；DeepSeek Harness 的 turn 是从一次输入到 agent 停下的整段（[[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-deepseek-harness-agent-loop-source]]）。因此"steering 在 turn 边界生效"（Go）和"steer 在 step 边界生效"（DeepSeek Harness）说的是同一件事。本页统一用 next-step 指"下一次模型调用之前"，next-turn 指"agent 本来要停下之后"。

### 边界式注入

- 插话**不打断**正在进行的模型流或工具批次，只在 step 边界被领取（`inbox.claim`）（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- 插话排在工具结果**之后**，不能插进请求和结果之间（[[2026-11-20-harness-engineering-go-practice]]）。
- 模型想停但 next-step 队列里有消息时，必须再跑一步（[[2026-11-20-harness-engineering-go-practice]]）。DeepSeek Harness 在 turn 即将结束时触发 `agent/turn-stopping`，触发后**再检查一次**队列，仍为空才结束，所以该事件的处理器可以通过塞消息让 turn 继续（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- 两者都在排队时的顺序被 Go 练习仓库的测试固定为 `一, 插话, 二, 后续, 三`：follow-up 要等 steering 引出的工作也做完（[[2026-11-20-harness-engineering-go-practice]]）。
- 队列要并发安全：界面线程 `Push`，loop `Drain`（[[2026-11-20-harness-engineering-go-practice]]）。

### 同一条通道的其他用户

next-step 队列不只服务用户插话：

- **工具追加上下文。** DeepSeek Harness 的工具可以返回 `additionalContexts`，被排进 next-step 队列，下一步作为用户侧消息进入（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- **后台任务完成通知。** learn-claude-code 的 Background Tasks 一章：慢命令在后台线程执行，完成后通过 notification queue 注入（[[2026-11-20-learn-claude-code-readme]]）。
- **完成门槛。** 验证失败时把失败输出作为一条 user 消息交还，loop 继续（[[2026-11-20-harness-engineering-go-practice]]）。见 [[verification-and-observability]]。
- **Message injection。** [[microsoft-agent-framework|Microsoft Agent Framework]] 的 chat pipeline 层列有 message injection，Go SDK 每个 agent 一个 `agent.MessageInjector`；文档只列了名字，没有解释用途，把它对应到 steering 是来源页的推断（[[2026-11-20-microsoft-learn-agent-harness]]）。

### 唤醒

"往队列里放消息"和"让空闲的 agent 开始工作"是两件事。DeepSeek Harness 把它们分开（[[2026-11-20-deepseek-harness-agent-loop-source]]）：

- `steer` 与 `inject` 的唯一区别是是否唤醒。
- 维护期间（如压缩，后者是来源页的推断）或活动已被 abort 时无法交付唤醒，就先锁存（`wakeRequested`），收敛后若队列非空再启动。
- 如果要求唤醒时当前活动已被 abort，`next-step` 会被改判为 `next-turn`：唤醒输入不能加入一个已 abort 的活动。
- agent 销毁后（`lifetimeSignal` abort）不再启动新的模型 turn。

### 取消

**取消时的不变量**（两份资料一致）：

1. **每个未执行的 tool 请求都要有结果。** 一批工具执行到一半被取消，没执行的每个请求也要补一条"已取消"结果；否则带着这份历史再调模型会报错，会话接不上（[[2026-11-20-harness-engineering-go-practice]]）。DeepSeek Harness 用 `ToolCallRecovery` 在 step 抛错时补写 `tool/result`（[[2026-11-20-deepseek-harness-agent-loop-source]]）。见 [[error-recovery]]。
2. **已经产生的东西留下。** 工具执行期间被取消，当前结果留在历史里（[[2026-11-20-harness-engineering-go-practice]]）；流被中断但已有内容块时，以 `interrupted: true` 追加 assistant 消息（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
3. **取消后不再调模型。** 取消信号已触发时一次模型都不调，返回取消错误（[[2026-11-20-harness-engineering-go-practice]]）。
4. **结束一定被记录。** `turn/end { turn, reason }` 在 `finally` 里追加，原因为 `aborted` 并附带取消原因（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

**传播方式。** 协作式取消：同一个取消信号传给工具解析、prompt 组装、模型调用和工具执行，每个 await 之后、每个流 chunk 之后都检查（[[2026-11-20-deepseek-harness-agent-loop-source]]）。Go 版本用 `ctx`，并传到子 agent（[[2026-11-20-harness-engineering-go-practice]]）。重试的等待期间被取消要立刻返回，取消错误不重试（[[2026-11-20-harness-engineering-go-practice]]）。

**取消原因。** DeepSeek Harness 的 cause 是封闭联合 `user | parent | disposed | hook(reason)`（[[2026-11-20-deepseek-harness-agent-loop-source]]）：

- `user`：用户取消。
- `parent`：来源页推断指父 agent 取消子 agent（与 [[subagents]] 相关）。
- `disposed`：agent 被销毁。
- `hook`：插件带理由取消（来源页推断步数上限之类的策略可以经此实现）。

写入日志时只拷贝白名单字段，避免运行时挂在 abort reason 上的 `stack` 污染日志。

**队列怎么办。** DeepSeek Harness 的 `cancel` 默认先清空 inbox，再 abort；可用 `keepInbox` 保留。清队列写在 `try`、abort 写在 `finally`，注释是"队列持久化失败不得阻止取消已准入的工作"（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 变体与演进

- **事前纠偏。** Claude Code 课程认为最佳纠偏点在写代码之前：plan mode 下审阅计划，不满意就让它改（[[2026-11-20-explore-plan-code-commit-workflow]]）。这是把 steering 前移到 [[planning-and-plan-mode|计划阶段]]。
- **审批也是一种暂停。** 对敏感操作，harness 暂停并请求人批准后再执行工具（[[2026-11-20-ai-harness-crash-course]]）；Go 练习仓库里无人值守时按拒绝处理，拒绝后 loop 继续（[[2026-11-20-harness-engineering-go-practice]]）。见 [[permissions]]。
- **确定性的拦截。** Claude Code 的 `PreToolUse` hook 可以阻止单个 tool call 并把原因回传给模型（[[2026-11-20-hooks-in-claude-code]]）；这是对单个动作的"取消"，不是对整个运行的取消。见 [[hooks]]。
- **准入否决。** DeepSeek Harness 的 `agent/pre-step` 可以 `reject`，使 turn 以 `blocked` 结束（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 优缺点和权衡

- **边界式 vs 抢占式。** 边界式注入保证历史始终合法、实现简单，代价是延迟：一个长时间运行的工具或一段长输出结束前，插话不生效。想立刻停下只能取消（这一句是笔者根据两份实现的行为做的归纳）。Go 练习仓库的 `bash` 有 30 秒超时，等于给这个延迟设了上限（[[2026-11-20-harness-engineering-go-practice]]）。
- **取消默认清队列**符合"我要它停"的直觉，但会丢掉已排队的后续消息，所以留了 `keepInbox`（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- **复杂度。** DeepSeek Harness 的 loop 文件约 700 行，大半是状态机、日志一致性和取消语义；它的最近一次提交仍在调整销毁与唤醒语义（[[2026-11-20-deepseek-harness-agent-loop-source]]，仓库处于 developer preview）。

## 不同来源的分歧

- **停不停由谁决定。** learn-claude-code 的 README 强调模型决定何时停，代码只执行（[[2026-11-20-learn-claude-code-readme]]）。有了 steering 队列、follow-up、turn-stopping 事件和取消，停不停就不完全由模型决定：它们能在模型想停时让 loop 继续，也能在模型不想停时让它停下（[[2026-11-20-harness-engineering-go-practice]]）。这个分歧在 [[verification-and-observability]] 里以矛盾块标出。
- **多个"想停时介入"的机制之间的顺序**没有定论：Go 练习仓库只测了 steering 先于 follow-up，验证与两者的先后未规定（[[2026-11-20-harness-engineering-go-practice]]，来源页记下的缺口）。
- **多数 README 不谈这件事。** [[openharness|OpenHarness]] 的 README 完全没有提到取消与插话；[[pi|Pi]] 的 README 不描述 loop（[[2026-11-20-openharness-readme]]、[[2026-11-20-pi-readme]]）。Go 练习仓库的注释说 hook 和事件的命名与 Pi 保持一致（[[2026-11-20-harness-engineering-go-practice]]），但 Pi 自身的 steering 机制本批资料无法确认。

## 采用它的项目

- [[deepseek-harness]]：`followup` / `steer` / `inject` / `cancel`，本批资料里唯一有源码依据的实现（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- [[claude-code]]：运行中可补充 context、打断、steer；机制未描述（[[2026-11-20-how-claude-code-works]]）。
- [[microsoft-agent-framework]]：message injection（用途未说明）（[[2026-11-20-microsoft-learn-agent-harness]]）。
- [[learn-claude-code]]：后台任务的 notification queue（[[2026-11-20-learn-claude-code-readme]]）。

## 相关概念

[[agent-loop]]、[[error-recovery]]、[[session-log]]、[[verification-and-observability]]、[[hooks]]、[[permissions]]、[[planning-and-plan-mode]]、[[subagents]]、[[compaction]]（维护作业与 turn 的互斥）、[[plugins-and-extensibility]]。
