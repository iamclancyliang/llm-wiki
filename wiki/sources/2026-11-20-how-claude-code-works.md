---
title: How Claude Code works（Claude Code 101 第 2 课视频）
type: source
kind: talk
aliases: [How Claude Code works]
tags: [claude-code, agent-harness, agent-loop, permissions, vendor-talk]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/yt-how-claude-code-works.md
author: Anthropic
url: https://www.youtube.com/watch?v=6bs5b4FltCU
---

# How Claude Code works（Claude Code 101 第 2 课视频）

> [!note] 资料性质
> YouTube 视频的自动转录，无标点且有识别错误（"cloud code""claw code" 即 Claude Code，"child applications" 应为 chat applications）。[[anthropic|Anthropic]] 对自家产品的介绍，属于厂商自述。转录中没有作者署名和发布日期。

## 一段话概括

用四个"agentic 概念"解释 [[claude-code|Claude Code]] 的工作方式：agentic loop、受管理的 context window、tools、可配置的 permissions。结论是它能读 codebase、采取行动并验证自己的工作，因此与聊天窗口"根本不同"（自述）。

## 要点

### Agentic loop

[[agent-loop|agentic loop]] 的流程，按资料叙述：

1. 用户输入 prompt。
2. **Gather context**：Claude Code 与 model 交互，model 返回文本或一个 Claude Code 可以执行的 tool call。
3. **Take action**：例如编辑文件或运行命令。
4. **Verify results**：判断结果是否达成 prompt 的目标。达成则结束并等待下一个 prompt；未达成则回到循环，直到结果"完整且可验证"。

循环进行中，用户可以随时补充 context、打断或 steer model（[[steering-and-cancel|steering 与打断]]）。

### Context window 与 compaction

- context window 决定能保存并回看多少对话、文件内容、命令输出等。
- 到达上限时，Claude Code 会 compact 对话：自动决定哪些内容移出、哪些内容改为摘要，把 context window 降下来（[[compaction]]，属于 [[context-management|context management]]）。

### Tools

- [[tools]] 被称为 "agent 工作方式的支柱"：多数 AI 助手只是文本进、文本出，tools 让 agent 决定何时执行代码来推进任务。举例：read file tool、search web tool。
- 资料称 Claude Code "uses semantic searching to determine when to call a tool"。原文只有这一句，没有解释机制；含义不明，引用时需谨慎。

### Permission modes

[[permissions]] 的模式，用 `Shift+Tab` 切换：

| 模式 | 行为 |
|---|---|
| 默认 | 编辑文件或运行 shell 命令前必须明确请求许可 |
| auto accept | 编辑文件不再询问，但运行命令仍然询问 |
| plan mode | 只使用 read-only tools，在动手前汇总出行动计划 |

- 建议：跳过权限要谨慎，放任 Claude Code 自由运行命令意味着错误更难在发生前被拦住。

## 值得记下的论据

- 没有数字或实验，全部是机制描述。
- verify 被列为 loop 的固定一步，而不是可选项（与 [[verification-and-observability|verification]] 相关）。

## 与已有知识的关系

- 展开了 [[2026-11-20-what-is-claude-code]] 中"LLM in a loop"的说法；loop 的三步与 [[2026-11-20-claude-code-101-course]] 大纲一致。
- 与课程大纲的差异：大纲列四种模式（manual、auto-accept、auto mode、Plan Mode），本片只讲三种，没有 auto mode。
- compaction 的细节（会丢信息、`/compact` 手动触发）见 [[2026-11-20-context-management-in-claude-code]]。

## 遗留问题

- "verify" 具体靠什么完成（测试、再读文件、model 自判）本片未说明。
- "semantic searching" 决定何时调用 tool 的说法缺乏解释。
