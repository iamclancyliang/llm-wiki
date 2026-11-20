---
title: Agent Harness（Microsoft Agent Framework 文档）
type: source
kind: doc
aliases: [Microsoft Learn Agent Harness, HarnessAgent, create_harness_agent]
tags: [agent-harness, microsoft-agent-framework, sdk, dotnet, python, go]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/microsoft-learn-agent-harness.md
author: Microsoft（Microsoft Learn，未署个人作者）
url: https://learn.microsoft.com/en-us/agent-framework/concepts/harness
---

# Agent Harness（Microsoft Agent Framework 文档）

## 一段话概括

[[microsoft-agent-framework|Microsoft Agent Framework]] 官方概念文档（页面标注最后更新于 2026-10-28，文末注明"作者在 AI 协助下撰写"）。它先给出一个简洁的 [[agent-harness|agent harness]] 定义，然后介绍框架自带的、带明确取向且 batteries-included 的 Harness：面向研究、编码、数据分析等长时工作，用户只需提供一个 chat client，再按需开关能力。关键设计决策是**不另造运行时**——Harness 只是把框架已有的构件（chat client、chat pipeline、context provider、middleware）按一套默认值组装起来，产物仍是普通的 agent 对象。文档分 .NET、Python、Go 三种 SDK 说明，三者的默认值和成熟度并不一致。

## 解决什么问题

- 定义（原文）：agent harness（也叫 AI harness）是"把语言模型变成能干活的 agent 的**运行时脚手架**（runtime scaffolding）"。它驱动模型调用和工具调用、管理会话状态与上下文、应用审批策略，并能让 agent 在多步任务中持续推进。
- 要解决的实际问题：自己从零拼装这些能力成本高；框架给出一套带明确取向的默认组合，同时保留逐项替换和关闭的口子。

## 架构与关键设计决策

### 五层组合

| 层 | 职责 |
|---|---|
| Chat client | 把 agent 连到模型 |
| Chat pipeline | 函数调用（function invocation）、消息注入（message injection）、每次服务调用后的历史持久化、可选的 compaction |
| Agent 与 context providers | 会话级的指令、工具、记忆、todo 状态、运行模式及可选能力 |
| Middleware 与 decorators | 审批处理、可观测性、可选的有界循环 |
| Application UX | 流式输出、展示进度、收集输入（如工具审批） |

- 产物是普通 agent：.NET 中是派生自 `AIAgent` 的 `HarnessAgent`；Python 中是 `create_harness_agent` 返回的 `Agent`；Go 中是用 `harness.AgentConfig` 配置的 provider-backed `*agent.Agent`。session 和 context provider 抽象与其他 agent 完全相同。
- Go 的 `agent/harness` 包明确"不引入单独的 agent 类型或工具执行循环"，工具调用循环由 provider 构造函数持有。
- 可扩展点就是 context provider 和 middleware 两种机制——这是该框架的 [[plugins-and-extensibility|扩展机制]]。

### 能力矩阵（默认值是设计决策的主体）

| 能力 | Harness 行为 | 对应概念 |
|---|---|---|
| Function invocation | 开启，每次请求有可配置的迭代上限 | [[agent-loop\|agent loop]]、[[tools\|工具]] |
| Per-service-call history persistence | 在一次带工具调用的 run 中，**每次模型调用后**都持久化历史 | [[session-log\|session log]] |
| Compaction | .NET、Python 在提供 token 上限或自定义策略时开启；Go 需显式组合 | [[compaction\|compaction]]、[[context-management\|上下文管理]] |
| Todo tracking | 默认开启 | — |
| Agent modes | plan / execute 两种模式默认开启（Go 默认从 plan 模式开始） | — |
| File memory / file access | 会话文件记忆默认开启；共享文件访问需显式开启 | — |
| Tool approval | standing approvals（常设批准）和 auto-approval 规则默认开启 | [[permissions\|权限]] |
| OpenTelemetry | agent 可观测性默认开启 | [[verification-and-observability\|验证与可观测性]] |
| Web search | 所选 chat client 支持时默认加入 | — |
| Agent Skills | .NET 和 Go 默认开启；Python 需通过 provider 或路径显式开启 | [[skills\|skills]] |
| Background agents | .NET、Python 可选：并行委派给具名子 agent；Go 无打包好的 provider | [[subagents\|subagents]] |
| Shell execution | 由 shell 包组合进来；Python 工厂函数可自动接线 | — |
| Looping | 可选：由 evaluator 或谓词驱动的**有界**重新调用 | [[long-running-agents\|长时运行 agent]] |

- 文档特意区分两个容易混淆的东西：**background agents** 是把任务委派给子 agent 运行；**background responses** 是用 continuation token 轮询或恢复**同一个** provider 请求。
- 文档还区分了 "Agent Skills"（运行时能力）与 `agent-framework-builder-python`（帮助 coding agent 编写 harness 应用的外部 skill）。

### 两级指令

- harness 级指令与 agent 级指令分开设置：.NET 为 `HarnessInstructions` 与 `ChatOptions.Instructions`，Python 为 `harness_instructions` 与 `agent_instructions`。**harness 指令排在 agent 指令之前**；默认 harness 指令由 `HarnessAgent.DefaultInstructions` / `DEFAULT_HARNESS_INSTRUCTIONS` 提供。这是 [[system-prompt|system prompt]] 分层的一个具体实现："如何操作"与"你是谁"分离。
- 同一组选项里还有 `MaxContextWindowTokens`（示例值 128,000）和 `MaxOutputTokens`（示例值 16,384），compaction 依赖前者触发。

```python
agent = create_harness_agent(
    client=client,
    harness_instructions="Use tools deliberately and report verified results.",
    agent_instructions="You are a research assistant focused on academic sources.",
    max_context_window_tokens=128_000,
)
```
（出处：原文 Python 示例，有删节）

### 定制方式

- 逐项关闭：.NET 有 `DisableTodoProvider`、`DisableAgentModeProvider`、`DisableFileMemory`、`DisableAgentSkillsProvider`、`DisableWebSearch`、`DisableToolAutoApproval`、`DisableOpenTelemetry`、`DisableCompaction`；Python 有对应的 `disable_*` 选项。
- 替换内建 provider（Python 的 `todo_provider`、`mode_provider`）或追加自定义 provider（`AIContextProviders` / `context_providers`）。
- 显式开启：文件访问（`FileAccessStore`）、后台委派（`BackgroundAgents`）、循环（`LoopEvaluators`）。

### 文件访问的安全设计（Python 部分写得最细）

- 默认把提供的 store 当作一个**共享工作区**；`file_access_session_scoped=True` 则按当前 session ID 隔离。
- 跨选定 session 有意共享时，用带 `scope` 的 `FileAccessProvider`；scope 是不透明键，映射到 provider 管理的文件夹，**不是路径**。
- **Fail closed**：既没有活动 session ID 也没有显式 scope 时，scoped 访问直接失败，而不是退回共享根目录。
- 多个文件访问 provider 并存时用 `tool_name_prefix` 避免工具名冲突（如 `workspace_file_access_read`），审批规则要用该 provider 自己的规则工厂生成，才能匹配带前缀的名字。`get_read_only_tools_auto_approval_rule()` 只自动批准只读工具；文档建议除非存储边界和工具输入可信，否则**保持写操作需要审批**。
- 行级编辑协议：`file_access_grep` 找 1-based 行号 → `file_access_read_lines` 读闭区间（每行带"行号 + tab"前缀）→ `file_access_replace_lines` 整行替换，并传入 `expected_line`（不含前缀）。`expected_line` 的作用是防止行号过期或错位时改错行。

### UX 不属于 harness

- Harness 不规定应用界面。仓库里的终端应用（流式输出、显示 todo 和当前模式、弹出工具审批、`/todos` `/mode` `/exit` 命令）是**示例而非随框架发布的组件**。.NET 入口为 `HarnessConsole.RunAgentAsync`，Python 用基于 Textual 的 `console` 包；Go 的交互式 chat CLI 用的是普通 agent，文档明说它不等价于 C# / Python 的 Harness console。

## 值得记下的数据和论据

- `file_access_grep`：大小写不敏感的正则；pattern 最长 **256 字符**；整次搜索预算 **10 秒**；非法或超长 pattern、超时都返回错误，文档建议先缩小目录或 pattern 再重试。
- Go 默认值：文件记忆持久化在 `agent-file-memory` 下、每个 session 一个隔离工作文件夹；skills 从工作目录做基于文件的发现并排除 memory 子树；历史为内存存储 + 每次服务调用持久化；每个 agent 一个 `agent.MessageInjector`；带 skill 脚本的需显式配置 script runner。使用 Foundry 模型部署且由本地历史持有对话时，应设 `DisableStoreOutput: true`。
- 示例代码里的模型和数值（`gpt-4o`、128,000 / 16,384 token）只是示例，不是推荐配置。
- 全文没有性能数据、基准或实现原理的论证；它是 API 概念页，陈述的是"框架做了什么"。

## 作者主张与可核实的事实

- **可核实的事实（文档陈述，可对照代码）**：各 SDK 的默认开关、选项名、工具名和限制值。
- **厂商自述**："opinionated, batteries-included"、适合"research, coding, data analysis, and other long-running work"——没有给出支持长时工作的证据或案例。
- **没有给理由的设计决策**：为什么 todo、plan/execute 模式、auto-approval 默认开启而 skills 在 Python 默认关闭；为什么 Go 默认从 plan 模式开始。文档只描述行为，不解释取舍。

## 适用与不适用的场景

- 适用：已经在用或打算用 Agent Framework，想快速得到一个带规划、记忆、审批、可观测性的通用 agent；需要逐项替换默认能力的团队。
- 不适用 / 需注意：想要开箱即用终端产品的人（console 只是示例）；Go 用户需要 compaction、looping、shell 或后台委派时要自己组合；对默认自动批准不放心的场景需要 `DisableToolAutoApproval` 或自定义规则。

## 成熟度

- 截至 2026-10-28（页面最后更新日期）：Python 的 `create_harness_agent` **已发布**；background agents、文件访问、looping 仍为 **experimental**；shell 工具来自**预发布**的 `agent-framework-tools` 包。
- 三个 SDK 能力不对齐：Go 最精简（无打包的后台 agent、compaction/looping/shell 不自动加入）。
- 文档未给出版本号和许可证；.NET 与 Python 代码在 `microsoft/agent-framework`，Go 在 `microsoft/agent-framework-go`。

## 与同批资料的关系

- **定义层面**：本文的定义把 harness 限定为运行时程序（驱动调用、管状态、施加审批）。OpenAI 的 harness engineering 文章谈的则是团队在 agent 之外搭建的仓库级环境（文档、lint、可观测性栈）。两者用同一个词指不同层次。
- **取向相反**：Anthropic《Building effective agents》建议少用框架、直接用 API、减少抽象层；本文提供的正是默认开启十来项能力的组合式框架。不过本文"组合既有构件、产物仍是普通 agent"的做法，也可以读作对"抽象遮蔽底层"这一批评的回应（笔者推断）。
- **状态放哪里**：Anthropic 长时运行文章把进度和任务清单放在工作目录的普通文件里，靠 prompt 约定维护；本文把 todo、文件记忆、模式做成 harness 内建的 provider。Anthropic 文章指出仅靠 compaction 不足以支撑跨 context window 的长任务，本文则把 compaction 加 looping 作为长时工作的手段，没有讨论跨 session 的交接问题。

## 涉及的实体和概念

[[microsoft-agent-framework]]、[[agent-harness]]、[[agent-loop]]、[[tools]]、[[permissions]]、[[session-log]]、[[context-management]]、[[compaction]]、[[system-prompt]]、[[skills]]、[[subagents]]、[[verification-and-observability]]、[[plugins-and-extensibility]]、[[long-running-agents]]

"message injection" 可能对应 [[steering-and-cancel|steering（运行中插话）]]，但本页文档只列出名字、未解释用途，此为笔者推断。

## 局限与遗留问题

- 这是一页总览，每项能力的机制都在链接出去的子页面里（compaction 策略、looping 的 evaluator、审批规则语义、background agents），本批资料未收录这些子页。
- raw 文本是带语言切换的页面导出，三种语言的内容首尾相接，个别段落归属哪种 SDK 需靠上下文判断（例如文件访问细节出现在 Python 部分，.NET 是否有相同限制未说明）。
- "standing approvals" 的作用域和有效期、auto-approval 默认规则具体放行哪些工具，本页没有说明——这直接关系到默认配置的安全性。
- 迭代上限的默认值、looping 的"有界"是多少，没有给出。
- 没有 [[hooks|hooks]] 式的生命周期事件、[[mcp|MCP]] 接入、上下文文件（AGENTS.md 一类）的描述；不能据此断定框架不支持，只能说本页未提及。
- 页面注明由 AI 协助撰写，细节应以仓库代码为准。
