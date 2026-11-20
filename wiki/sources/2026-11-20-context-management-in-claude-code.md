---
title: Context management in Claude Code（Claude Code 101 视频）
type: source
kind: talk
aliases: [Context management in Claude Code]
tags: [claude-code, agent-harness, context-management, compaction, vendor-talk]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/yt-context-management-in-claude-code.md
author: Anthropic
url: https://www.youtube.com/watch?v=eW3oTyfeWZ0
---

# Context management in Claude Code（Claude Code 101 视频）

> [!note] 资料性质
> YouTube 视频的自动转录，无标点且有识别错误（"Claw""claw.md""/cle" 即 Claude、`CLAUDE.md`、`/clear`）。[[anthropic|Anthropic]] 对自家产品的介绍，属于厂商自述。转录中没有作者署名和发布日期。

## 一段话概括

讲 [[claude-code|Claude Code]] 的 [[context-management|context management]]：context window 是有限的工作记忆，三个命令（`/compact`、`/clear`、`/context`）用来管理它，另有五条节省 context 的做法（写具体的 prompt、把长期信息放进 `CLAUDE.md`、关掉无关的 MCP servers、用 skills、用 subagents）。

## 要点

### 什么占用 context

每个读过的文件、每条运行的命令、每条用户消息、每个 tool call 及其结果，都追加进 context window；空间有限，所以需要优化。

### 三个命令

| 命令 | 作用 | 何时用（资料的经验法则） |
|---|---|---|
| `/compact` | 手动触发 [[compaction]]：压缩到目前为止的全部内容，腾出空间但保留对之前工作的记忆 | 还在做同一个功能、context 快满但需要继续时；保持 context 与该功能相关 |
| `/clear` | 清除全部内容，从零开始，不保留之前工作的记忆 | 一个计划做完、要开始新功能时；避免旧对话给新工作带来 bias |
| `/context` | 显示 context 总量、占用最多的各类别，以及一张图 | 检查当前是什么在占 context |

- **自动 compaction**：接近上限时自动触发；会总结重要细节、移除不必要的 tool call 结果。资料明确提醒：这**可能丢失**此前对话中的细节。

### 节省 context 的做法

- **放进 `CLAUDE.md`**：希望 Claude 在其他 session 也记得的东西写进 `CLAUDE.md`（[[context-files|context file]]），免得每次从头重新发现。
- **Prompt 要具体**：资料称"讽刺的是"短 prompt 长期看更费 context——不明说，Claude 就得在 codebase 里到处看、自己多想，比多写一两句话占用得多。
- **MCP servers**：[[mcp|MCP]] servers 默认把全部可用 [[tools]] 加载进 context；与项目无关的 server 可以关掉。
- **Skills**：[[skills]] "与 MCP servers 类似，但不会把全部内容放进 context"，因而省空间。
- **Subagents**：[[subagents]] 与主 agent 并行运行，拥有完全独立的 context window。适合"只要答案、不要过程"的任务（例："authentication endpoints 在哪里"），由 subagent 完成并只把摘要返回主 agent。

## 值得记下的论据

- 没有给出 context window 大小、自动 compaction 的触发阈值等任何数字。
- "短 prompt 反而更费 context" 是作者主张，无测量数据。

## 与已有知识的关系

- 补充 [[2026-11-20-how-claude-code-works]]：那里只说 compaction "自动决定移出和摘要什么"，这里补上了会丢细节的风险和手动命令。
- 与 [[2026-11-20-claude-code-101-course]] 大纲中 "subagents 保持主 context 干净" 的定位一致。
- "skills 与 MCP servers 类似" 是一个很粗的类比；课程大纲把 skills 定位为"重复工作流"，两处强调点不同（见课程页）。

## 遗留问题

- `/compact` 之后保留了什么、丢了什么，用户如何得知？
- skills "不把全部内容放进 context" 的具体加载机制未说明。
