---
title: Verification and observability（验证与可观测性）
type: concept
aliases: [verification, 验证, 完成门槛, completion gate, observability, 可观测性, evaluation, eval, 评估, stop reason, 停止原因, telemetry, 遥测, dry-run]
tags: [agent-harness, verification, observability, evaluation]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-openharness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
---

# Verification and observability（验证与可观测性）

## 定义

本页把四件相邻的事放在一起，因为它们回答的是同一个问题——"怎么知道 agent 做了什么、做得对不对"——只是时间点和受众不同：

| 名称 | 时间点 | 给谁看 | 决定什么 |
|---|---|---|---|
| verification / 完成门槛 | 运行中，agent 想停的时候 | agent 自己和 harness | loop 是否继续 |
| 停止原因（stop reason） | 运行结束时 | 调用方 | 这次运行算什么结果 |
| 事件与遥测 | 运行中持续产生 | 界面、运维、以后的分析 | 不直接决定什么 |
| 事后评估（evaluation） | 运行之后 | harness 的开发者 | harness 或模型要不要改 |

AI Harness Crash Course 把前后两端都叫 "evaluation"（[[2026-11-20-ai-harness-crash-course]]）；本 wiki 把运行时决定 loop 是否继续的叫 verification，把事后衡量质量的叫 evaluation（这一区分来自来源页的观察）。

## 要解决的问题和动机

- **agent 会过早宣布完成。** [[anthropic|Anthropic]] 在长任务实验里观察到两个层次：后期的 agent 实例看到已有进展就判定整个项目完成；以及未充分测试就把单个功能标为完成——没有明确提示时，它会改代码，甚至用单元测试或 `curl` 打 dev server，但意识不到功能端到端并不能用（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]，Opus 4.5 + [[claude-agent-sdk|Claude Agent SDK]]，定性观察）。[[learn-harness-engineering]] 课程把"防止 agent 提前宣告完成"单列一讲（[[2026-11-20-learn-harness-engineering-course]]，仅标题）。
- **agent 需要 ground truth。** agent 每一步都要从环境拿到工具调用结果、代码执行结果来评估进展；编码之所以适合 agent，正是因为方案可由自动化测试验证（[[2026-11-20-anthropic-building-effective-agents]]）。
- **瓶颈转移到人工 QA。** [[openai|OpenAI]] 团队的经验是代码产出速度上去之后，人的 QA 能力成了瓶颈，所以要让 UI、日志、指标直接对 agent 可读（[[2026-11-20-openai-harness-engineering]]，单一团队自述）。
- **过程黑箱。** 不可观测就无法调试（[[2026-11-20-learn-harness-engineering-course]]）。

## 工作原理

### 1. 验证手段

- **verify 是 loop 的固定一步。** [[claude-code|Claude Code]] 把 [[agent-loop|agentic loop]] 描述为 gather context → take action → verify results，结果未达成就回到循环（[[2026-11-20-how-claude-code-works]]、[[2026-11-20-claude-code-101-course]]）。verify 具体靠什么完成该课没有说明；另一课补上了手段：计划里写明什么算正确、项目里要有 test suite、给 agent 能自我验证的工具（[[2026-11-20-explore-plan-code-commit-workflow]]）。
- **测试。** 前提是测试本身可信：Claude 可以代写测试，但交给它之前要确保这些测试是 source of truth，避免 false positives（[[2026-11-20-explore-plan-code-commit-workflow]]）。Anthropic 的 prompt 用强措辞禁止删改测试（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。自动化测试只验证功能，人工 review 对"是否符合更大的系统需求"仍然关键（[[2026-11-20-anthropic-building-effective-agents]]）。
- **浏览器自动化：像人类用户那样测。** Anthropic 用 Puppeteer [[mcp|MCP]] server，agent 测试时自己截图；作者称这"显著提升了表现"（无量化数据），已知盲区是看不到浏览器原生 alert modal（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。OpenAI 团队把 Chrome DevTools Protocol 接入 agent 运行时，并写了处理 DOM 快照、截图、导航的 [[skills]]（[[2026-11-20-openai-harness-engineering]]）。Claude Code 课程建议做 web UI 时装 Claude in Chrome extension（[[2026-11-20-explore-plan-code-commit-workflow]]）。两家独立得出"让 agent 亲眼看运行结果"的结论。
- **fresh-context reviewer。** 提交前跑一个 subagent code reviewer（[[2026-11-20-explore-plan-code-commit-workflow]]）。OpenAI 团队让 Codex 本地自审并请求其他 agent 审查，循环到所有 agent reviewer 满意；如何避免互相放水没有给出机制（[[2026-11-20-openai-harness-engineering]]）。见 [[subagents]]。
- **机械强制的不变量。** OpenAI 团队用自定义 linter 和结构测试强制分层架构与"品味不变量"，错误信息里直接写修复指引（[[2026-11-20-openai-harness-engineering]]）。Claude Code 的 [[hooks]] 是同一思路在 harness 内的版本：必须每次都发生的检查放进 hook 而不是 prompt（[[2026-11-20-hooks-in-claude-code]]）。

### 2. 完成门槛：模型说"做完了"不算数

把验证从"建议"变成 loop 的条件，有四种形态：

| 形态 | 做法 | 来源 |
|---|---|---|
| Verify 钩子 | 只在模型不再请求工具时调用 `Verify(ctx) (ok, output)`；失败则把输出作为一条 user 消息交还，loop 继续；验证永远不过由 `MaxTurns` 兜底。命令行里就是跑一条 shell 命令看退出码 | [[2026-11-20-harness-engineering-go-practice]] |
| 清单判定 | 功能清单的 `passes` 字段全为 true 才算完成；由驱动器读清单判定，不听模型的一句话 | [[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]、[[2026-11-20-harness-engineering-go-practice]] |
| 独立 evaluator | goal gate：独立 evaluator 审查每次"想停"；不可能、失败或超限的目标把控制权交还用户 | [[2026-11-20-learn-claude-code-readme]]（s17，仅 README 描述） |
| 停止前事件 | `Stop` hook 在 Claude 完成回复时触发；`agent/turn-stopping` 的处理器可以塞消息让 turn 继续 | [[2026-11-20-hooks-in-claude-code]]、[[2026-11-20-deepseek-harness-agent-loop-source]] |

补充：

- [[microsoft-agent-framework|Microsoft Agent Framework]] 的可选 looping 是由 evaluator 或谓词驱动的**有界**重新调用（experimental，页面更新于 2026-10-28）（[[2026-11-20-microsoft-learn-agent-harness]]）。
- Anthropic 的 evaluator-optimizer 模式是这类门槛的 workflow 版本：一个调用生成，另一个评估并反馈；适用条件是评估标准清晰且迭代有可度量价值（[[2026-11-20-anthropic-building-effective-agents]]）。
- workflow 层的门：两个检查并行（单元测试、浏览器测试），任一失败就把反馈送回 coding agent，都通过才进入 review（[[2026-11-20-ai-harness-crash-course]]）。
- `Stop` hook 能否阻止停止，Claude Code 课程的转录没有说明（[[2026-11-20-hooks-in-claude-code]]）；把 `agent/turn-stopping` 类比为 Stop hook 是来源页的推断（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

### 3. 停止原因

运行结束时要说清"为什么停"，否则调用方分不清做完了还是放弃了。

| 实现 | 原因集合 |
|---|---|
| Go 练习仓库 | `completed`、`max-turns`、`aborted`、`error`（[[2026-11-20-harness-engineering-go-practice]]） |
| [[deepseek-harness\|DeepSeek Harness]] | `completed`、`max-tokens`、`blocked`、`aborted`、`error`（[[2026-11-20-deepseek-harness-agent-loop-source]]） |

- DeepSeek Harness 的 `max-tokens` 是粘性的；`blocked` 来自 pre-step 的否决；`aborted` 附带取消原因；`turn/end` 在 `finally` 里一定写入日志。它的 loop 文件里**没有** max-steps 之类的迭代上限（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- Go 练习仓库保证无论怎么结束，最后一个事件都是带原因的 `agent_end`（[[2026-11-20-harness-engineering-go-practice]]）。
- 迭代上限作为停止条件是通行做法：Anthropic 建议加最大迭代次数以保持控制（[[2026-11-20-anthropic-building-effective-agents]]）；Microsoft 的 function invocation 有可配置的迭代上限（[[2026-11-20-microsoft-learn-agent-harness]]）；[[openharness|OpenHarness]] 有 `--max-turns`（[[2026-11-20-openharness-readme]]）。

### 4. 事件与遥测

- **事件流。** Go 练习仓库把一次带一个工具调用的运行的事件序列固定为：`agent_start`，`turn_start`、`message_end`、`tool_execution_start`、`tool_execution_end`、`message_end`、`turn_end`，`turn_start`、`message_end`、`turn_end`，`agent_end`；注释说名字与 [[pi|Pi]] 一致（[[2026-11-20-harness-engineering-go-practice]]）。DeepSeek Harness 发出 `agent/status`、`agent/assistant-stream`、`agent/error` 等事件（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- **日志即数据源。** DeepSeek Harness 的 [[session-log]] 同时是恢复依据和可观测性数据源：turn/step 边界、请求配置变化、失败的尝试都在里面（[[2026-11-20-deepseek-harness-agent-loop-source]]）。Claude Code 的 hooks 可以记录所有执行过的命令以满足合规（[[2026-11-20-hooks-in-claude-code]]）。
- **OpenTelemetry。** Microsoft 的 Harness 默认开启 agent 可观测性，放在 middleware 层，可用 `DisableOpenTelemetry` 关闭（[[2026-11-20-microsoft-learn-agent-harness]]）。Pi 有独立的 `pi-telemetry` 包：厂商中立的遥测契约、参考适配器、一致性测试、类型化 schema，机制 README 未展开（[[2026-11-20-pi-readme]]）。
- **成本。** OpenHarness 自述 loop 带 token 计数与成本跟踪（[[2026-11-20-openharness-readme]]）。
- **可脚本化输出。** OpenHarness 的非交互模式支持 `text | json | stream-json`（[[2026-11-20-openharness-readme]]）；Pi 有 print / JSON 模式和 RPC（[[2026-11-20-pi-readme]]）。

### 5. 给 agent 用的可观测性栈

上一节的遥测是给人看的。OpenAI 团队做的是反过来：让**应用**的日志、指标、trace 对 agent 可读（[[2026-11-20-openai-harness-engineering]]）。

- 应用可以按 git worktree 启动，每次改动有一个独立实例。
- 每个 worktree 配一套临时的本地可观测性栈，任务结束即销毁；agent 用 LogQL 查日志、PromQL 查指标。
- 作者称有了这些，"确保服务启动在 800ms 内完成""四个关键用户旅程中任何 span 不得超过两秒"这类 prompt 才变得可执行。

learn-harness-engineering 的闭环图里对应的节点是"运行反馈（CLI / Logs）"（[[2026-11-20-learn-harness-engineering-course]]）。

### 6. 事后评估

AI Harness Crash Course 的三分法（概念讲解，无实验）（[[2026-11-20-ai-harness-crash-course]]）：

| 方式 | 做法 | 适合 |
|---|---|---|
| deterministic evaluation | 定义清晰的要求，用代码检查 | 明确的要求（下载的文件是否包含同样 10 个客户） |
| LLM-as-a-judge | 把产物交给另一个模型，告诉它看什么 | 清晰度之类的品质 |
| human evaluation | 人亲自试 | 自动检查覆盖不到的体验问题 |

要点：想让 judge 检查准确性，就要给它"功能实际如何工作"的证据；judge 会出错，应拿它的判断与人工评审对比校准；三种可以混用。

与之相关的数据来源：learn-claude-code 主张部署轨迹是训练信号，harness 工程师要收集 trajectory data（[[2026-11-20-learn-claude-code-readme]]）；Pi 的作者呼吁公开分享真实编码会话，认为比 "toy benchmarks" 更能改进 agent（[[2026-11-20-pi-readme]]）。两者都是作者主张。

### 7. dry-run

OpenHarness 的 `--dry-run`（README 标为 Unreleased）是运行**之前**的验证：不调用模型、不执行工具、不派生 subagent、不连接 MCP server，只解析设置、认证状态、prompt 组装、skills、命令、工具，给出 `ready / warning / blocked` 结论和下一步建议（[[2026-11-20-openharness-readme]]）。它验证的是 harness 的配置，而不是 agent 的产出。

## 变体与演进

- 从"提示模型去测试"（Anthropic 的 prompt）到"harness 强制测试"（Verify 钩子、清单校验）。Go 练习仓库注释的说法是"提示词是请求，代码是规则"（[[2026-11-20-harness-engineering-go-practice]]）。
- 从工具层的 ACI 扩大到整个仓库的 agent legibility（[[2026-11-20-anthropic-building-effective-agents]]、[[2026-11-20-openai-harness-engineering]]）。
- 持续的后台验证：OpenAI 团队定期运行后台 agent 扫描偏差、更新质量评分、发起重构 PR（[[2026-11-20-openai-harness-engineering]]）。

## 优缺点和权衡

- 完成门槛越严，越不容易出现假完成，但可能永远过不了，所以必须配迭代上限（[[2026-11-20-harness-engineering-go-practice]]）。
- 验证能力有盲区（alert modal）（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；门槛本身可被绕过：Go 练习仓库的清单校验不检查验证步骤是否被改写（来源页推断）（[[2026-11-20-harness-engineering-go-practice]]）。
- LLM judge 便宜但会错（[[2026-11-20-ai-harness-crash-course]]）。
- 遥测和日志带来隐私成本：工具输出可能进入日志（[[2026-11-20-ai-harness-crash-course]]）。
- 证据强度：本页多数结论是定性观察或自述，没有一份资料给出"有无某种验证手段"的对照数据。

## 不同来源的分歧

> [!warning] 矛盾
> **停不停由谁决定。**
> - 模型决定：learn-claude-code README 强调模型决定何时调用工具、何时停止，代码只执行；并称 Claude Code 的优雅在于"不替模型做决策"（[[2026-11-20-learn-claude-code-readme]]，作者立场）。OpenHarness 的伪代码里停止条件只有 `stop_reason` 不是 `tool_use`（[[2026-11-20-openharness-readme]]）。
> - harness 参与决定：AI Harness Crash Course 说 harness 管理"何时继续、何时停止、何时求助"（[[2026-11-20-ai-harness-crash-course]]）；Go 练习仓库的 `Verify`、`MaxTurns` 能推翻模型的决定（[[2026-11-20-harness-engineering-go-practice]]）。
> - learn-claude-code 自己的 s17 Goal Loop 用独立 evaluator 审查每次"想停"（[[2026-11-20-learn-claude-code-readme]]），与其宣言部分存在张力。

> [!warning] 矛盾
> **质量门该多严。** Anthropic：测试通过才标完成，每个 session 留下可合并的干净状态（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。OpenAI 团队：减少阻塞性合并门，flaky test 重跑，"纠错成本低，等待成本高"，并明说这只适用于高吞吐环境（[[2026-11-20-openai-harness-engineering]]）。

- **验证是否是 harness 的核心组成。** learn-claude-code 的五要素公式（Tools + Knowledge + Observation + Action Interfaces + Permissions）没有把验证单列，Observation 指模型看到的环境反馈（[[2026-11-20-learn-claude-code-readme]]）；AI Harness Crash Course 把 evaluation 列为四个设计方面之一（[[2026-11-20-ai-harness-crash-course]]）；learn-harness-engineering 把验证和可观测性各立一讲（[[2026-11-20-learn-harness-engineering-course]]）。
- **迭代上限放哪。** 多数实现内建；DeepSeek Harness 的 loop 不内建（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 采用它的项目

[[claude-code]]（verify 步骤、hooks、fresh-context reviewer）、[[claude-agent-sdk]]（Anthropic 实验中配 Puppeteer MCP）、[[codex]]（OpenAI 团队的 CDP 与可观测性栈）、[[microsoft-agent-framework]]（OpenTelemetry、looping evaluator）、[[openharness]]（dry-run、stream-json、成本跟踪，自述）、[[pi]]（`pi-telemetry`）、[[deepseek-harness]]（事件与 turn 结束原因）、[[learn-claude-code]]（Goal Loop）、[[learn-harness-engineering]]。

## 相关概念

[[agent-loop]]、[[long-running-agents]]、[[error-recovery]]、[[steering-and-cancel]]、[[session-log]]、[[hooks]]、[[subagents]]、[[tools]]、[[workflows-vs-agents]]、[[planning-and-plan-mode]]、[[harness-engineering]]、[[sandboxing]]（worktree 级的隔离实例）；横向对比见 [[开源-harness-设计取向对比]]。
