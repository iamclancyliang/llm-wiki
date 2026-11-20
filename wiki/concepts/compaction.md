---
title: Compaction（上下文压缩）
type: concept
aliases: [compaction, context compaction, 上下文压缩, auto-compact, 压缩]
tags: [agent-harness, context-management, compaction]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-context-management-in-claude-code
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-openharness-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-pi-readme
---

# Compaction（上下文压缩）

## 定义

Compaction 是 [[context-management|上下文管理]]的一种手段：context window 快满时，把较早的对话历史换成更短的表示（摘要，或删掉不必要的工具结果），腾出空间让同一个会话继续。[[claude-code|Claude Code]] 的说法是它"自动决定哪些内容移出、哪些内容改为摘要"（[[2026-11-20-how-claude-code-works]]）。

它与 `/clear` 的区别在于保留"对之前工作的记忆"（[[2026-11-20-context-management-in-claude-code]]）；与 [[memory]] 的区别在于它只服务于当前会话；与 [[session-log]] 的区别在于它改变的是发给模型的内容，而日志是只追加的原始记录。

## 要解决的问题和动机

[[agent-loop|agent loop]] 的消息历史只增不减（[[2026-11-20-learn-claude-code-site]]）。不处理的话，长会话会在窗口上限处中断。learn-claude-code 网站对这一课的一句话主张是"上下文窗口拥挤时靠压缩保持对话可用"（[[2026-11-20-learn-claude-code-site]]）。

## 工作原理

### 触发条件

- **自动**：接近窗口上限时触发。Claude Code 课程没有给出阈值（[[2026-11-20-context-management-in-claude-code]]）。Go 练习仓库的规格是在调用模型**之前**检查 `Size(messages) > MaxContextChars`，其中 `Size` 按字符数粗估而不是 token 数（[[2026-11-20-harness-engineering-go-practice]]）。[[microsoft-agent-framework|Microsoft Agent Framework]] 的 Harness 在 .NET、Python 里提供 token 上限（`MaxContextWindowTokens`）或自定义策略时才开启 compaction，Go 需显式组合（[[2026-11-20-microsoft-learn-agent-harness]]，页面更新于 2026-10-28）。
- **手动**：Claude Code 的 `/compact`。经验法则是还在做同一个功能、上下文快满但要继续时用它（[[2026-11-20-context-management-in-claude-code]]）。
- **互斥**：[[deepseek-harness|DeepSeek Harness]] 的 loop 提供 `runMaintenance(job)`，仅在 agent 空闲时可进入，维护期间到来的唤醒被锁存、作业结束后重放。来源页**推断**压缩就是这样一种维护作业；loop 文件本身不实现压缩（[[2026-11-20-deepseek-harness-agent-loop-source]]）。可以确认的是，压缩不能与一个正在进行的模型 turn 同时改同一份历史。

### 压缩什么、保留什么

Go 练习仓库的测试把一个最小的摘要式压缩固定为以下规格（[[2026-11-20-harness-engineering-go-practice]]）：

1. 保留开头连续的 system 消息。
2. 保留最近 `keepRecent` 条消息原文。
3. 中间那段转成文字，用专门的摘要提示词调一次模型（不带工具）。
4. 结果是 `[system…, user(摘要前缀 + 摘要), 最近的消息…]`。

摘要提示词要求包含五项：用户目标、已完成的事、读过或改过的文件、未完成的事、踩过的坑（[[2026-11-20-harness-engineering-go-practice]]）。Claude Code 的自动 compaction 被描述为"总结重要细节、移除不必要的 tool call 结果"（[[2026-11-20-context-management-in-claude-code]]）。

### 不变量

以下约束来自 Go 练习仓库的测试断言（[[2026-11-20-harness-engineering-go-practice]]），是本批资料里唯一写成可执行规格的一组：

- **不能拆开 tool 请求与结果。** 切点落在 `tool` 消息上就向前挪；否则会出现孤儿 `tool` 消息，模型接口会拒绝请求。
- **没东西可压时不调用模型**（"调一次就花一次钱"）。
- **不修改传入的历史切片**，压缩产出新的历史。
- **写摘要失败要返回错误**，"不能悄悄丢掉历史"。

learn-claude-code 仓库的一条提交说明是 "fix(s08): preserve the complete active request after compaction"（[[2026-11-20-learn-claude-code-readme]] 对应的 raw 文件列表），与"不能拆开一次完整请求"是同一类约束；具体修了什么未摄入。

DeepSeek Harness 一侧多出一条与请求构造有关的约束：loop 记住上次构造请求时 session surface 的代数（`contentGeneration`），发生变化就把下一个请求标为新的 series 并重新提交 [[system-prompt|system prompt]]，代码注释直接写着 "Compaction during the first resumed pre-step must still mark a new series."（[[2026-11-20-deepseek-harness-agent-loop-source]]）。也就是说，压缩之后"请求前缀"被视为换了一代。

## 变体与演进

| 变体 | 做法 | 来源 |
|---|---|---|
| 摘要式 | 中段历史 → 一条摘要消息，保留头尾 | [[2026-11-20-harness-engineering-go-practice]] |
| 分级式 | `tool_result_budget` / `snip_compact` / `micro_compact` / `compact_history` 四步：先削减工具结果，仍超限再总结历史 | [[2026-11-20-learn-claude-code-readme]] |
| 保留任务状态的自动压缩 | 压缩时保留任务状态和 channel 日志 | [[2026-11-20-openharness-readme]]（自述，v0.1.6，2026-04-10） |
| 可插拔策略 | token 上限或自定义 compaction 策略，放在 chat pipeline 层 | [[2026-11-20-microsoft-learn-agent-harness]] |
| 维护作业式 | 压缩在 loop 之外，以维护作业与 turn 互斥 | [[2026-11-20-deepseek-harness-agent-loop-source]]（推断） |

- 分级式的顺序有道理：工具结果通常是历史里最大、最可再生的部分（可以重新读文件），先动它们损失最小。这一句是笔者推断；四步各自的具体做法需要读 learn-claude-code s08 的章节原文，本批资料只有关键词（[[2026-11-20-learn-claude-code-readme]]）。
- 与单个工具输出的截断（见 [[context-management]]）是两回事：截断发生在结果进入历史之前，压缩发生在历史已经太长之后。

## 优缺点和权衡

- **会丢细节。** Claude Code 课程明确提醒 compaction 可能丢失此前对话中的细节（[[2026-11-20-context-management-in-claude-code]]）。用户无从得知丢了什么，这是该来源页记下的遗留问题。
- **花钱。** 摘要式压缩要多一次模型调用（[[2026-11-20-harness-engineering-go-practice]]）。
- **摘要质量是瓶颈。** [[anthropic|Anthropic]] 的观察是 compaction "并不总是把足够清晰的指示传给下一个 agent"（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **对缓存前缀的影响。** 压缩改写了历史前部，DeepSeek Harness 因此把它当作新 series 的起点；来源页推断这类机制与保持请求前缀稳定以利于 prompt cache 有关，文件中没有明说（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

### 为什么仅靠 compaction 不够支撑长任务

Anthropic 2025-11-26 的文章给出了本批资料里最直接的论据（实验设定：Opus 4.5，[[claude-agent-sdk|Claude Agent SDK]]，从一句高层 prompt 构建 claude.ai 克隆，跨多个 context window 循环运行；定性观察，无对照数据）（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）：

1. agent 倾向于一次做太多，实现到一半上下文用尽；下一个窗口面对半成品且无文档的功能，只能猜发生了什么。作者指出即使有 compaction 也会发生。
2. 项目后期，新的 agent 实例看到已有不少进展，就判定任务完成。

两种失败都不是"窗口不够大"，而是"压缩后的历史没有说清楚工作状态"。对策是把状态写进环境（功能清单、进度文件、git），见 [[long-running-agents]]。

## 不同来源的分歧

> [!warning] 矛盾
> - Anthropic：理论上 compaction 足以让 agent 无限期工作，实际上"不够"（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
> - [[openharness|OpenHarness]] 自述：Auto-Compaction 之后 agent "可以跑多天的会话而无需手动 compact/clear"（[[2026-11-20-openharness-readme]]）。
>
> 后者是项目自述，没有说明触发阈值、摘要策略、"保留任务状态"的具体形式，也没有数据；前者是内部实验的定性结论。可能的调和是 OpenHarness 的压缩把任务状态单独保留，等于在压缩里做了一部分"状态落盘"的事，但这是笔者推断，需读源码确认。

- **压缩后的历史与会话日志的关系没有定论。** Go 练习仓库的测试只断言模型看到的是压缩后的历史、输入切片不被修改，没有规定 `Run` 返回哪份历史，也没有规定恢复会话时加载原文还是摘要（[[2026-11-20-harness-engineering-go-practice]]，来源页标为未决设计点）。DeepSeek Harness 的方向是日志只追加、请求从日志派生（[[2026-11-20-deepseek-harness-agent-loop-source]]）。详见 [[session-log]]。
- **默认开不开。** Claude Code 自动触发（[[2026-11-20-how-claude-code-works]]）；Microsoft 的 Harness 要给了 token 上限才开，Go SDK 不自动加入（[[2026-11-20-microsoft-learn-agent-harness]]）。

## 采用它的项目

- [[claude-code]]：自动 compaction 与 `/compact`（[[2026-11-20-claude-code-101-course]]、[[2026-11-20-context-management-in-claude-code]]）。
- [[claude-agent-sdk]]：自带 compaction（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- [[openharness]]：Auto-Compact（[[2026-11-20-openharness-readme]]，自述）。
- [[microsoft-agent-framework]]：chat pipeline 的可选 compaction，可用 `DisableCompaction` / `disable_compaction` 关闭（[[2026-11-20-microsoft-learn-agent-harness]]）。
- [[learn-claude-code]]：s08 Context Compact，README 把 context compaction 列为 Claude Code 的组成机制之一（作者的逆向归纳，非官方描述）（[[2026-11-20-learn-claude-code-readme]]）。
- [[deepseek-harness]]：loop 只提供协作接口，实现在别处（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- [[pi]]：README 未描述压缩（[[2026-11-20-pi-readme]]）。

## 相关概念

[[context-management]]（枢纽页）、[[session-log]]、[[memory]]、[[long-running-agents]]、[[subagents]]（另一种腾空间的办法：不让过程进入主上下文）、[[agent-loop]]、[[system-prompt]]。
