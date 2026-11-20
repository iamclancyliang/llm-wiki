---
title: Microsoft Agent Framework
type: entity
kind: project
aliases: [Agent Framework, HarnessAgent, create_harness_agent, Microsoft Agent Framework Harness]
tags: [agent-harness, sdk, microsoft, dotnet, python, go]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-openai-harness-engineering
---

# Microsoft Agent Framework

> [!note] 资料边界
> 本页只覆盖框架的 **Harness 部分**。唯一来源是 Microsoft Learn 上的一页概念文档（页面标注最后更新于 2026-10-28，文末注明在 AI 协助下撰写）。每项能力的机制都在未收录的子页面里；框架的其他部分（workflow、多 agent 编排等）本库没有资料（[[2026-11-20-microsoft-learn-agent-harness]]）。

## 是什么、解决什么问题

Microsoft Agent Framework 是 Microsoft 的 agent 开发框架，有 .NET、Python、Go 三种 SDK。它自带一个"带明确取向、batteries-included"的 Harness，面向研究、编码、数据分析等长时工作：用户提供一个 chat client，再按需开关能力（厂商自述，[[2026-11-20-microsoft-learn-agent-harness]]）。

文档对 [[agent-harness|agent harness]] 的定义：把语言模型变成能干活的 agent 的"运行时脚手架"（runtime scaffolding），驱动模型调用和工具调用、管理会话状态与上下文、应用审批策略（[[2026-11-20-microsoft-learn-agent-harness]]）。

## 关键事实（截至 2026-10-28 的文档，[[2026-11-20-microsoft-learn-agent-harness]]）

- 组织：Microsoft。代码在 `microsoft/agent-framework`（.NET、Python）和 `microsoft/agent-framework-go`。
- 成熟度：Python 的 `create_harness_agent` 已发布；background agents、文件访问、looping 仍为 experimental；shell 工具来自预发布的 `agent-framework-tools` 包。
- 版本号、许可证、首次发布日期：文档未给出。

## 工作原理概要

**不另造运行时。** Harness 只是把框架已有的构件按一套默认值组装起来，产物仍是普通 agent 对象：.NET 是派生自 `AIAgent` 的 `HarnessAgent`，Python 是 `create_harness_agent` 返回的 `Agent`，Go 是用 `harness.AgentConfig` 配置的 `*agent.Agent`。Go 的 `agent/harness` 包明确不引入单独的 agent 类型或工具执行循环（[[2026-11-20-microsoft-learn-agent-harness]]）。

五层组合（[[2026-11-20-microsoft-learn-agent-harness]]）：

| 层 | 职责 | 对应概念 |
|---|---|---|
| Chat client | 把 agent 连到模型 | — |
| Chat pipeline | function invocation、message injection、每次服务调用后的历史持久化、可选 compaction | [[agent-loop\|agent loop]]、[[session-log\|session log]]、[[compaction]] |
| Agent 与 context providers | 会话级的指令、工具、记忆、todo 状态、运行模式 | [[tools]]、[[memory]]、[[planning-and-plan-mode\|plan mode]] |
| Middleware 与 decorators | 审批处理、可观测性、可选的有界循环 | [[permissions]]、[[verification-and-observability]] |
| Application UX | 流式输出、进度、收集输入 | 不属于 harness，仓库里的终端应用只是示例 |

默认值是设计决策的主体（[[2026-11-20-microsoft-learn-agent-harness]]）：

- **默认开启**：function invocation（每次请求有可配置的迭代上限）；每次模型调用后持久化历史；todo tracking；plan / execute 两种 agent mode（Go 默认从 plan 模式开始）；会话文件记忆；tool approval 的 standing approvals 和 auto-approval 规则；OpenTelemetry；chat client 支持时的 web search。
- **有条件或需显式开启**：[[compaction]]（.NET、Python 在提供 token 上限或自定义策略时开启，Go 需显式组合）；[[skills|Agent Skills]]（.NET 和 Go 默认开启，Python 需显式开启）；background agents（.NET、Python 可选，并行委派给具名子 agent，即 [[subagents]]；Go 无打包好的 provider）；共享文件访问；shell execution；looping（由 evaluator 或谓词驱动的有界重新调用，面向 [[long-running-agents|长时工作]]）。
- **两级指令**：harness 指令排在 agent 指令之前，是 [[system-prompt|system prompt]] 分层的一个实现。
- **扩展点**：context provider 和 middleware 两种机制，可逐项关闭（`Disable*` / `disable_*`）、替换内建 provider 或追加自定义 provider。见 [[plugins-and-extensibility]]。
- **文件访问的安全设计**（Python 部分写得最细）：scope 是不透明键而非路径；没有活动 session ID 也没有显式 scope 时 fail closed；`get_read_only_tools_auto_approval_rule()` 只自动批准只读工具，文档建议保持写操作需要审批；行级编辑用 `expected_line` 防止改错行。

文档特意区分 background agents（委派给子 agent）与 background responses（用 continuation token 轮询或恢复同一个 provider 请求）（[[2026-11-20-microsoft-learn-agent-harness]]）。

本页文档没有提到的：[[hooks]] 式生命周期事件、[[mcp|MCP]] 接入、AGENTS.md 一类[[context-files|上下文文件]]、[[sandboxing|沙箱]]。只能说未提及，不能断定不支持（[[2026-11-20-microsoft-learn-agent-harness]]）。"message injection" 可能对应 [[steering-and-cancel|steering]]，这是来源页的推断。

## 优缺点与适用场景

- 适用：已经在用或打算用 Agent Framework，想快速得到带规划、记忆、审批、可观测性的通用 agent（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 需注意：想要开箱即用终端产品的人（console 只是示例）；Go 用户需要 compaction、looping、shell 或后台委派时要自己组合；对默认自动批准不放心的场景需要 `DisableToolAutoApproval` 或自定义规则（[[2026-11-20-microsoft-learn-agent-harness]]）。
- "适合 long-running work"是厂商自述，文档没有给出证据或案例；也没有解释各默认值的取舍理由（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 三个 SDK 的默认值和成熟度不一致，Go 最精简（[[2026-11-20-microsoft-learn-agent-harness]]）。

> [!warning] 矛盾
> 与 [[anthropic|Anthropic]] 的两处取向分歧：
> - **框架**：《Building effective agents》建议少用框架、直接用 API、减少抽象层（[[2026-11-20-anthropic-building-effective-agents]]）；本框架提供默认开启十来项能力的组合（[[2026-11-20-microsoft-learn-agent-harness]]）。来源页认为"产物仍是普通 agent"可以读作对抽象遮蔽批评的回应，这是推断。
> - **长任务的状态放哪里**：Anthropic 把进度和任务清单放在工作目录的普通文件里，并指出仅靠 compaction 不足以支撑跨 context window 的长任务（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；本框架把 todo、文件记忆、模式做成 harness 内建的 provider，以 compaction 加 looping 作为长时工作的手段，没有讨论跨 session 交接（[[2026-11-20-microsoft-learn-agent-harness]]）。

> [!warning] 矛盾
> "harness" 的层次：本文档把 harness 限定为运行时程序（[[2026-11-20-microsoft-learn-agent-harness]]）；OpenAI 的 [[harness-engineering|harness engineering]] 文章谈的是团队在 agent 之外搭建的仓库级环境（[[2026-11-20-openai-harness-engineering]]）。同一个词指不同层次。

## 同类替代品

- [[claude-agent-sdk|Claude Agent SDK]]：同为 SDK 形态的 harness，本库资料不足以细比。
- [[pi|Pi]] 的 SDK 与 `pi-agent-core`、[[openharness|OpenHarness]]、[[deepseek-harness|DeepSeek Harness]]。对比见 [[开源-harness-设计取向对比]]。

## 演进时间线

资料只有一个时间点：文档页最后更新于 2026-10-28（[[2026-11-20-microsoft-learn-agent-harness]]）。

## 未解问题

- standing approvals 的作用域和有效期、auto-approval 默认规则具体放行哪些工具，直接关系默认配置的安全性（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 迭代上限的默认值、looping 的"有界"是多少（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 文件访问细节出现在 Python 部分，.NET 是否有相同限制未说明（[[2026-11-20-microsoft-learn-agent-harness]]）。
