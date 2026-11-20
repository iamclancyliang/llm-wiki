---
title: Session log（会话日志）
type: concept
aliases: [session log, 会话日志, session journal, transcript, 会话持久化, session persistence, event-sourced session]
tags: [agent-harness, session, persistence, event-sourcing]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-openharness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-learn-claude-code-readme
---

# Session log（会话日志）

## 定义

Session log 是 [[agent-harness|agent harness]] 对一次会话里发生的事所做的**只追加**记录：用户消息、assistant 消息、tool call 及其结果，有的实现还记录 turn 和 step 的边界、请求配置的变化、失败的尝试。它由 harness 写，不由模型写。

它回答两个问题：进程退出或崩溃后怎么接着干；以及事后怎么知道发生过什么（见 [[verification-and-observability]]）。

### 术语区分：session / state / long-term memory

AI Harness Crash Course 用 Google ADK 的术语给出一个三分（讲者口头介绍，未注明 ADK 版本）（[[2026-11-20-ai-harness-crash-course]]）：

| 名称 | 是什么 | 给谁用 | 本 wiki 对应页面 |
|---|---|---|---|
| session | 对话线程：全部消息、工具调用和结果，即完整 transcript | 模型（作为历史）和恢复逻辑 | 本页 |
| state | 应用的 scratchpad，键值对，代码直接读写，不用翻整段对话 | 应用代码 | [[long-running-agents]]（落盘的任务状态） |
| long-term memory | 从对话里提炼出的事实，带到未来的对话里 | 未来的会话 | [[memory]] |

> [!warning] 矛盾
> "session" 一词在本批资料里有两个不同的含义：
> - ADK 语境：一条可以持久化、隔天整段加载接着干的对话线程（[[2026-11-20-ai-harness-crash-course]]）。
> - [[anthropic|Anthropic]] 长任务文章：agent 的一次运行，基本等同于一个 context window；每个新 session 开始时对之前发生的事没有记忆（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
>
> 前者的 session 可以跨多次进程启动，后者的 session 之间靠文件交接。读资料时要先确认是哪一种。

## 要解决的问题和动机

- **恢复与续跑。** 没有日志，进程一退出，会话就没了。
- **崩溃安全。** 进程可能在任何时刻被杀，包括写到一半和工具执行到一半。
- **可审计。** 需要知道模型当时看到了什么、做了什么、为什么停下。
- **请求的合法性。** 模型接口对历史的结构有要求（每个 tool call 必须有配对的结果）。日志如果留下不配对的记录，带着它再发请求会被拒绝，会话就接不上了（[[2026-11-20-harness-engineering-go-practice]]）。

## 工作原理

### 写入：只追加，一条记录要么完整要么不存在

Go 练习仓库的规格（JSONL，一行一条消息）（[[2026-11-20-harness-engineering-go-practice]]）：

- `Append` 把 JSON 和换行拼成一个字节切片只 `Write` 一次，使一行要么完整写下要么没写；文件权限 `0o600`。
- loop 对每条**新增**消息恰好通知一次；恢复会话时传入的旧历史不再通知，否则会重复写。

[[microsoft-agent-framework|Microsoft Agent Framework]] 的 Harness 把写入时机定为 per-service-call history persistence：在一次带工具调用的 run 中，**每次模型调用后**都持久化历史，而不是等整个 run 结束（[[2026-11-20-microsoft-learn-agent-harness]]）。这样一次长 run 中途崩溃时损失的是一步而不是全部（后半句是笔者推断，文档只陈述行为）。

### 读取：容错不对称

同一规格对 `Load` 的要求（[[2026-11-20-harness-engineering-go-practice]]）：

- 文件不存在是新会话，不是错误。
- **最后一行**不是合法 JSON 就丢弃：进程可能写到一半被杀。
- **中间行**损坏则报错并指出行号："文件坏了，不能假装没事"。
- 要能读回超过 64KB 的行。

### 从日志派生请求（event-sourced）

[[deepseek-harness|DeepSeek Harness]] 的默认 loop 把这一点推到底：文件头注释写着 "Every request is derived from the session log"，loop 自己不持有消息历史（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

- 发给模型的消息来自 `session.deriveMessages()`，结果被深度冻结；loop 的其余实例状态都是"投影"而非历史副本。
- 日志里不只有消息。写入的事件类型有：`turn/start`、`turn/end`、`step/start`、`step/end`、`system/message`、`user/message`、`assistant/message`、`assistant/attempt`、`tool/result`、`developer/message`、`request/header`、`request/context`。
- **请求配置也进日志。** 规范化后的请求 header 与日志里的基线比较，按 `initial / resume / change / series` 追加；工具集增减会追加一条 `developer/message` 让模型知道工具变了；provider、model、`contextWindow` 变化时追加 `request/context`。
- **system prompt 也是事件。** [[system-prompt|system prompt]] 的变更以 `system/message` 写入日志。
- **失败也留痕。** 失败的模型请求记为 `assistant/attempt`；流被中断但已有内容时，以 `interrupted: true` 追加 `assistant/message`。
- **日志必须保持可恢复。** step 抛错时，把尚未有结果的 tool call 补写成 `tool/result`，保证每个 tool call 都有配对结果（见 [[error-recovery]]）；`turn/end { turn, reason }` 在 `finally` 里一定追加。
- 写入 `turn/end` 的取消原因只拷贝白名单字段，因为运行时会往 abort reason 上挂 `stack`，直接落盘会污染日志。

与之对照，Go 练习仓库和 learn-claude-code 的最小 loop 是"调用方持有消息数组，日志是它的旁路副本"：`Run` 接收历史、返回新历史，`OnMessage` 回调负责落盘（[[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-learn-claude-code-readme]]）。

### 恢复与续跑

- [[openharness|OpenHarness]] 提供 `-c/--continue`、`-r/--resume`、`/resume`，README 没讲存储格式（[[2026-11-20-openharness-readme]]）。
- DeepSeek Harness 的 header 有 `resume` 这一种追加原因，说明恢复时会重新比对请求配置（[[2026-11-20-deepseek-harness-agent-loop-source]]）；仓库 commit 信息里出现 "session journal"，来源页据此**推断**会话以 journal 形式持久化（[[2026-11-20-deepseek-harness-readme]]）。
- ADK 的 session 加持久化存储后可以隔天整段加载接着干（[[2026-11-20-ai-harness-crash-course]]）。
- [[pi|Pi]] 有独立的 `pi-durable` 包（durable 的 conversation、task、document 运行时），README 只有一句话，"durable" 的语义未知（[[2026-11-20-pi-readme]]）。

## 变体与演进

| 形态 | 真相来源 | 日志里有什么 | 代表 |
|---|---|---|---|
| 消息数组 + 旁路 JSONL | 内存里的消息数组 | 消息 | Go 练习仓库（[[2026-11-20-harness-engineering-go-practice]]） |
| 每次模型调用后持久化 | 框架的 session 抽象 | 历史 | Microsoft Agent Framework（[[2026-11-20-microsoft-learn-agent-harness]]） |
| 事件溯源 | 日志本身 | 消息 + 边界 + 请求配置 + 失败尝试 | DeepSeek Harness（[[2026-11-20-deepseek-harness-agent-loop-source]]） |
| 可恢复的 workflow journal | journal | 编排步骤 | learn-claude-code s16（[[2026-11-20-learn-claude-code-readme]]，仅关键词） |

## 与压缩后历史的关系

只追加的日志和会改写历史的 [[compaction]] 之间有张力：压缩之后，日志里是原文，模型看到的是摘要。

- Go 练习仓库没有回答：测试只断言模型看到的是压缩后的历史、输入切片不被修改；恢复会话时加载原文还是摘要是来源页标出的未决设计点（[[2026-11-20-harness-engineering-go-practice]]）。
- 事件溯源的形态给出了一个方向：日志保持只追加，"发给模型的视图"是日志的派生物，压缩只改变派生结果。DeepSeek Harness 的 loop 用 session surface 的代数（`contentGeneration`）感知这种变化，并把下一个请求标为新 series（[[2026-11-20-deepseek-harness-agent-loop-source]]）。压缩结果本身如何记入日志不在该文件里，属于未知。
- OpenHarness 自述压缩时保留任务状态和 channel 日志，具体形式未说明（[[2026-11-20-openharness-readme]]）。

## 优缺点和权衡

- 事件溯源的好处是恢复、审计和取消后的一致性都有单一依据；代价是复杂度：DeepSeek Harness 的 loop 文件约 700 行，大半花在状态机、日志一致性和取消语义上（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- 旁路 JSONL 简单，但"内存历史"和"磁盘日志"是两份，压缩后如何对应需要另外决定（[[2026-11-20-harness-engineering-go-practice]]）。
- **隐私。** 工具输出即使在本机产生，也可能被存进 session 历史和日志；要考虑数据允许去哪、保留多久（[[2026-11-20-ai-harness-crash-course]]）。Go 练习仓库把日志文件权限设为 `0o600`，并在测试里用 hook 把输出中的密钥抹掉再交给模型（[[2026-11-20-harness-engineering-go-practice]]）。

## 不同来源的分歧

- **日志 vs 进度文件。** Anthropic 长任务方案里的 `claude-progress.txt` 是 agent 自己写在工作目录里的摘要，不是 harness 记录的会话历史；两者都能让下一个会话接上，但一个靠 harness 保证完整，一个靠 prompt 约定（这一区分是来源页的推断）（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。该方案里每个 session 用全新上下文，不恢复上一段对话。
- **谁持有历史。** "调用方持有、模型无状态"（[[2026-11-20-harness-engineering-go-practice]]）对"日志持有、loop 只做投影"（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- **历史存在哪一侧。** Microsoft 文档提到使用 Foundry 模型部署且由本地历史持有对话时应设 `DisableStoreOutput: true`（Go SDK 的说明），说明还存在"服务端持有对话"的选项（[[2026-11-20-microsoft-learn-agent-harness]]）。

## 采用它的项目

[[deepseek-harness]]（事件溯源）、[[microsoft-agent-framework]]（per-service-call persistence）、[[openharness]]（session resume，格式未知）、[[pi]]（`pi-durable`，机制未知）、[[learn-claude-code]]（s16 的 resumable journal）。[[claude-code|Claude Code]] 的会话存储在本批资料中没有描述。

## 相关概念

[[context-management]]（枢纽页）、[[compaction]]、[[memory]]、[[long-running-agents]]、[[error-recovery]]、[[steering-and-cancel]]、[[verification-and-observability]]、[[agent-loop]]。
