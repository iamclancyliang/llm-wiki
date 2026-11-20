---
title: Claude Agent SDK
type: entity
kind: project
aliases: [Agent SDK, Anthropic Agent SDK]
tags: [agent-harness, sdk, anthropic, long-running-agents]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-pi-readme
---

# Claude Agent SDK

> [!note] 资料边界
> 本库没有 Claude Agent SDK 自己的文档或源码。它只在两篇 [[anthropic|Anthropic]] 文章里被提到，下面是这两处的全部信息。API 形态、支持语言、版本、许可证，资料均未提及。

## 是什么、解决什么问题

Anthropic 的长时运行文章把 Claude Agent SDK 称为"强大的、通用的 [[agent-harness|agent harness]]"，擅长编码，也适用于其他需要模型用工具收集 context、规划和执行的任务（厂商自述，[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

《Building effective agents》在"让 agentic 系统更容易实现的框架"列表里列出了它。该文首发于 2024-12-19，页面后来被修订过，无法判断这一条是原文还是之后加入的（[[2026-11-20-anthropic-building-effective-agents]]）。

## 关键事实

- 组织：Anthropic（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- 首次发布、当前版本、许可证：资料未提及。

## 工作原理概要

资料只给出一项能力：自带 [[context-management|上下文管理]]能力，例如 [[compaction]]；文章称理论上这足以让 agent 无限期工作（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

[[agent-loop|agent loop]]、[[tools]]、[[permissions]]、[[hooks]]、[[subagents]] 等在 SDK 中如何提供，资料未提及。

## 已知的使用案例与观察到的局限

唯一的案例是 Anthropic 自己的内部实验（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）：

- 设定：Claude Agent SDK + Opus 4.5，跨多个 context window 循环运行，从一句高层 prompt 构建 claude.ai 克隆。未报告 session 数、时长、成本或最终通过的 feature 数。
- 观察：只靠 SDK 自带的 compaction 不够。出现两种失败模式：试图 one-shot 导致 context 用尽后留下半成品；项目后期新的 agent 实例过早宣布完成。作者指出 compaction "并不总是把足够清晰的指示传给下一个 agent"。
- 对策不改 SDK：harness、[[system-prompt|system prompt]] 和工具集保持不变，只换初始 user prompt（initializer agent 与 coding agent），把状态放进工作目录的文件（feature list、`claude-progress.txt`、`init.sh`、git 历史）。这是 [[long-running-agents|长时运行 agent]] 的一种做法。
- 验证用的是 Puppeteer [[mcp|MCP]] server，说明 SDK 上的 agent 可以接 MCP 工具（从实验设定得出的推断，资料没有描述 SDK 的 MCP 接口）。

以上是定性的内部实验结论，没有对照数据；作者自己的定位是 "one possible set of solutions"（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

## 与 Claude Code 的关系

资料没有正面说明。能确认的只有：长时运行文章以 SDK 为 harness，致谢中提到 [[claude-code|Claude Code]] 团队参与（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。"SDK 是 Claude Code 所用 harness 的可编程形态"这类说法在本库资料中**没有依据**，不应写成事实。

## 优缺点与适用场景

- 优点（厂商自述）：通用、自带 compaction（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- 局限（同一文章的实验观察）：开箱即用时不足以支撑跨多个 context window 的大型构建任务，需要在环境和 prompt 上另做工作（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

> [!warning] 矛盾
> Anthropic 对框架的态度存在张力：《Building effective agents》建议先直接用 LLM API、少加抽象层，称"对底层的错误假设是客户出错的常见来源"（[[2026-11-20-anthropic-building-effective-agents]]）；同一篇文章修订后的框架列表又列出了自家的 Claude Agent SDK，长时运行文章也直接以它为基础（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。来源页认为两者未必矛盾（前文也说框架可用于起步），但出发点不同。

## 同类替代品

- [[microsoft-agent-framework|Microsoft Agent Framework]] 的 Harness：同为 SDK 形态、提供 compaction（[[2026-11-20-microsoft-learn-agent-harness]]）。两者的具体能力对比在本库资料中无法展开，因为 Claude Agent SDK 一侧缺资料。
- [[pi|Pi]] 的 TypeScript SDK 与 `pi-agent-core`（[[2026-11-20-pi-readme]]）。
- 《Building effective agents》同一列表中的 Strands Agents SDK、Rivet、Vellum（本库无进一步资料，[[2026-11-20-anthropic-building-effective-agents]]）。

## 未解问题

- 与 Claude Code 的确切关系。
- compaction 的触发条件和摘要方式。
- 配套代码在 anthropics/claude-quickstarts 的 autonomous-coding 目录，未收录（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- 《Building effective agents》页面顶部提到的 Claude Managed Agents 与 SDK 是什么关系，资料未说明（[[2026-11-20-anthropic-building-effective-agents]]）。
