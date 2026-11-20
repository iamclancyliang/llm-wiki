---
title: Claude Code 101（Claude Academy 课程介绍页）
type: source
kind: doc
aliases: [Claude Code 101, Claude Academy Claude Code 101]
tags: [claude-code, agent-harness, course, vendor-doc]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/claude-academy-claude-code-101.md
author: Anthropic（Claude Academy）
url: https://academy.claude.com/courses/claude-code-101
---

# Claude Code 101（Claude Academy 课程介绍页）

> [!note] 资料性质
> 这是 [[anthropic|Anthropic]] 官方课程的**落地页**（课程简介 + 大纲），不含各课正文；属于厂商自述。页面无发布日期，仅有页脚 "© 2026 Anthropic PBC"。

## 一段话概括

[[claude-code|Claude Code]] 的官方入门课程，自称"从第一性原理"讲起：先建立 agentic loop、context window、tools、permissions 四者如何协同的心智模型，再讲安装、提示、日常工作流，最后讲定制。规模为 12 课、1.5 小时、1 个测验、结业徽章。

## 解决什么问题

资料主张：仅仅安装 agent 并输入请求得不到真实价值，需要理解 agent 如何思考、能看到什么 context、以及在它走偏时如何引导（[[steering-and-cancel|steering]]）。面向刚入行的开发者和尚未用过 coding agent 的资深工程师。

## 课程结构（即官方给出的概念划分）

| 章节 | 课数 | 内容 |
|---|---|---|
| What is Claude Code? | 2 | coding agent 与 chat 助手的区别；[[agent-loop\|agentic loop]]（gather context → take action → verify results）以及约束每一步的 [[tools]] 和 [[permissions]] |
| Your first prompt | 2 | 在 terminal、VS Code、JetBrains、Claude Desktop、web 五种环境安装；四种模式：manual mode、auto-accept、auto mode、Plan Mode，用于选择监督程度 |
| Daily workflows | 3 | Explore → Plan → Code → Commit 工作流；[[context-management\|context management]] 命令 `/compact`、`/clear`、`/context`；code review（自己过目 + 一个 fresh-context reviewer，提交前进行） |
| Customizing Claude Code | 5 | `CLAUDE.md`（[[context-files\|context file]]，跨 session 的项目记忆）；[[subagents]]；[[skills]]；[[mcp\|MCP]] servers；[[hooks]] |

## 要点

- 把 Claude Code 定位为"住在 terminal 里的 agentic coding tool"，能读代码、跑命令、改文件。
- 对各定制机制的一句话定位：
  - `CLAUDE.md`：让 Claude 跨 session 记住项目约定。
  - subagents：委派任务，并"保持主 context 干净"。
  - skills：用于经常重复的任务或工作流。
  - MCP servers：接入外部工具和数据源。
  - hooks：提供 deterministic（确定性）控制，用于 formatting、command blocking、notifications，即"确定性护栏"。
- `/compact` 对应 [[compaction]]，课程把它与 `/clear`、`/context` 并列为让长 session 保持高效的手段。
- 前置条件：熟悉编辑器和命令行；需要 Claude 账号（Pro、Max、Ultra、Team 或 Enterprise）或 API key。

## 成熟度与适用范围

- 入门级材料；落地页只给大纲，机制细节在各课视频中（本库已摄入其中 6 课的转录，见下）。
- 评价性说法（"以前要一个下午的任务现在一个 session 完成""第一次就得到好结果"）均为厂商自述，无数据支撑。

## 与已有知识的关系

- 是以下各课来源页的总目录：[[2026-11-20-what-is-claude-code]]、[[2026-11-20-how-claude-code-works]]、[[2026-11-20-explore-plan-code-commit-workflow]]、[[2026-11-20-context-management-in-claude-code]]、[[2026-11-20-the-claude-md-file]]、[[2026-11-20-hooks-in-claude-code]]。
- 补充：本页列出四种权限模式（含 auto mode），而 [[2026-11-20-how-claude-code-works]] 的视频只讲了 default、auto-accept、plan mode 三种，没有提 auto mode。

## 遗留问题

- auto mode 与 auto-accept 的区别，落地页没有说明。
- Installing Claude Code、Your first prompt、Code review、Subagents、Skills、MCP 六课的正文未摄入。
