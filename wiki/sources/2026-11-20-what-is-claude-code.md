---
title: What is Claude Code?（Claude Code 101 第 1 课视频）
type: source
kind: talk
aliases: [What is Claude Code]
tags: [claude-code, agent-harness, ai-agent, vendor-talk]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/yt-what-is-claude-code.md
author: Anthropic
url: https://www.youtube.com/watch?v=fl1DSmwQKKY
---

# What is Claude Code?（Claude Code 101 第 1 课视频）

> [!note] 资料性质
> YouTube 视频的自动转录，无标点且有识别错误（"cloud Code""Claw desktop app""Jetrains" 应为 Claude Code、Claude desktop app、JetBrains）。[[anthropic|Anthropic]] 对自家产品的介绍，属于厂商自述。转录中没有作者署名和发布日期。

## 一段话概括

入门短片：把 [[claude-code|Claude Code]] 定义为一个 agentic coding tool，说明它与聊天产品 Claude.ai 的区别在于能直接访问文件、terminal 和整个 codebase，并给出使用前要知道的三个概念：context window、默认请求许可、会犯错。

## 要点

- **定义**：Claude Code 理解 codebase、编辑文件、运行命令，并与现有开发工具集成。可用环境：terminal、Visual Studio Code、Claude desktop app、web、JetBrains IDEs。
- **与 Claude.ai 的区别**：不需要来回复制粘贴代码，它自己进去完成工作；"最简单的区分"是 Claude Code 以 AI agent 的方式工作。
- **AI agent 的定义**（资料原话的意思）：能与环境交互并执行动作以完成既定目标的软件；最基本的实现方式是"把一个 large language model 放进一个 loop 里"（即 [[agent-loop|agent loop]]）。agent 可以访问 [[tools]]、外部服务或其他 AI agents。
- **能力举例**：
  - 读懂 codebase：解释某个功能，或在代码中追踪 bug。
  - 执行 build script、跑测试、装包，并**用输出决定下一步**。
  - 需要最新 API 文档时搜索 web。
- **使用前要知道的三件事**：
  1. context window 是 Claude 的"工作记忆"，能装很多但装不下全部；agentic 的意义在于用策略在 codebase 里找答案，而不是把整个 codebase 塞进 context（参见 [[context-management|context management]]）。
  2. 默认请求许可：运行命令或修改 codebase 前会先问用户（[[permissions]]）；用户可以选择更 hands-on 或更被动。
  3. 会犯错：可能误解意图、引入新 bug、或 overengineer 方案。

## 值得记下的论据

- 没有任何数字或实验。"help you ship faster""you're always in control" 是厂商自述的评价性说法。
- "把 LLM 放进 loop + tools" 作为 agent 的最小定义，是官方口径的直接表述，可用于概念页。

## 与已有知识的关系

- 是 [[2026-11-20-claude-code-101-course]] 第一章第 1 课；第 2 课 [[2026-11-20-how-claude-code-works]] 把这里的 loop 展开为 gather context → take action → verify results。
- 小不一致：片头列出 5 种可用环境（含 web），片尾 recap 只列 4 种（没有 web）。

## 遗留问题

- "其他 AI agents" 作为 agent 可访问的资源，本片没有展开（对应 [[subagents]]，课程另有专课）。
