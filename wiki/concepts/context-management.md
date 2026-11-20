---
title: Context management（上下文管理）
type: concept
aliases: [context management, 上下文管理, context engineering, context window 管理]
tags: [agent-harness, context-management, context-window]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-context-management-in-claude-code
  - 2026-11-20-what-is-claude-code
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-the-claude-md-file
  - 2026-11-20-pi-readme
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-openharness-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-ai-harness-crash-course
---

# Context management（上下文管理）

本页是"上下文与状态"这一组概念的枢纽页。细分页面：[[compaction]]（压缩）、[[session-log]]（会话日志）、[[memory]]（跨会话记忆）、[[long-running-agents]]（跨 context window 的长任务）；相邻页面：[[context-files]]、[[skills]]、[[subagents]]、[[system-prompt]]。

## 定义

Context management 指 [[agent-harness|agent harness]] 决定"每一次模型调用时，context window 里放什么、不放什么"的全部手段。context window 被当作模型的**有限工作记忆**：能装很多，但装不下全部（[[2026-11-20-what-is-claude-code]]）。每个读过的文件、每条命令输出、每条用户消息、每个 tool call 及其结果都会追加进去（[[2026-11-20-context-management-in-claude-code]]）。

"存什么、取回什么由你决定"——这是 harness 设计者的责任，而不是模型的（[[2026-11-20-ai-harness-crash-course]]）。

## 要解决的问题和动机

- **历史只增不减。** [[agent-loop|agent loop]] 每转一圈，`messages[]` 就按 user → assistant → tool_call → tool_result 增长，迟早撞上窗口上限（[[2026-11-20-learn-claude-code-site]]）。
- **上下文是稀缺资源，不只是"会不会满"的问题。** [[openai|OpenAI]] 团队的一手经验：巨大的指令文件会挤掉任务、代码和相关文档，agent 要么漏掉关键约束，要么去优化错误的约束；"一切都重要"时 agent 只会做局部模式匹配（[[2026-11-20-openai-harness-engineering]]，单一团队自述）。该文把上下文管理列为让 agent 胜任大型复杂任务的最大挑战之一。
- **旧内容会带来偏差。** [[claude-code|Claude Code]] 课程建议做完一个计划、开始新功能时清空上下文，理由是避免旧对话给新工作带来 bias（[[2026-11-20-context-management-in-claude-code]]，厂商自述）。
- **窗口之外的东西等于不存在。** 从 agent 的角度看，运行时访问不到的知识（聊天记录、人脑里的共识）不存在，只有仓库内版本化的工件可见（[[2026-11-20-openai-harness-engineering]]）。所以上下文管理有两个方向：把窗口里的东西**减下来**，以及让窗口外的东西**在需要时进得来**。

## 工作原理：手段总览

| 手段 | 做什么 | 代价 / 边界 | 详见 |
|---|---|---|---|
| 压缩（compact） | 把较早的历史换成摘要，或先削减工具结果 | 会丢细节；摘要质量决定后续表现 | [[compaction]] |
| 清空（clear） | 丢掉全部历史从零开始 | 不保留之前工作的记忆，需要靠文件接上 | [[long-running-agents]] |
| 查看占用 | Claude Code 的 `/context` 显示总量和各类别占用 | 只是诊断手段 | 本页 |
| 截断工具输出 | 对单个工具结果设上限，并告诉模型"被截断了" | 模型需要再发一次调用取后续内容 | [[tools]] |
| 持久信息放文件 | 跨会话要记住的东西写进 `CLAUDE.md` / `AGENTS.md` 或记忆文件 | 文件本身也占上下文，过大会失效 | [[context-files]]、[[memory]] |
| 渐进式披露 | 入口文件只当目录，指向按需读取的文档 | 依赖 agent 主动去读 | [[context-files]] |
| 按需加载 skills | system prompt 里只放名字和描述，正文用到再读 | 模型可能没想到去读 | [[skills]] |
| 精简工具面 | 关掉无关的 MCP server | 少了能力 | [[mcp]] |
| subagent 隔离 | 子任务在独立上下文里跑，只回传结论 | 主 agent 看不到过程 | [[subagents]] |
| 写具体的 prompt | 少让 agent 自己到处找 | 人要多写一两句 | 本页 |

各手段的要点：

- **compact / clear / context 三个命令。** Claude Code 把 `/compact`（压缩但保留对之前工作的记忆）、`/clear`（全部清除）、`/context`（查看占用）并列为保持长 session 高效的手段。经验法则：还在做同一个功能、上下文快满就 compact；计划做完、换新功能就 clear（[[2026-11-20-context-management-in-claude-code]]、[[2026-11-20-claude-code-101-course]]）。接近上限时 compaction 会自动触发（[[2026-11-20-how-claude-code-works]]）。
- **工具结果要有预算。** Go 练习仓库把单个工具输出上限定为 20000 字符，按 rune 截断并追加一句说明总长度和保留长度的提示，理由是不告诉模型"内容不完整"它会以为看到了全部；读文件默认一次 200 行，并提示用 `offset` 取后续内容（[[2026-11-20-harness-engineering-go-practice]]）。learn-claude-code 的压缩章节同样是先削减工具结果、仍超限再总结历史（[[2026-11-20-learn-claude-code-readme]]）。
- **把持久信息放进文件。** 希望其他 session 也记得的东西写进 `CLAUDE.md`，免得每次重新发现（[[2026-11-20-context-management-in-claude-code]]）；没有它时 Claude Code 每次都要重新探索 codebase（[[2026-11-20-the-claude-md-file]]）。
- **渐进式披露（progressive disclosure）。** OpenAI 团队的 `AGENTS.md` 约 100 行，只作目录，指向结构化的 `docs/`："给 Codex 一张地图，而不是一本 1000 页的说明书"（[[2026-11-20-openai-harness-engineering]]）。同一思路用在 skills 上：Go 练习仓库的 system prompt 只放 skill 的名字、描述和路径，测试断言正文不出现在 prompt 里，两个 skill 的清单不超过 600 个字符（[[2026-11-20-harness-engineering-go-practice]]）。Claude Code 课程对 skills 的说法是"与 MCP servers 类似，但不会把全部内容放进 context"（[[2026-11-20-context-management-in-claude-code]]；来源页指出这是很粗的类比）。
- **工具定义也占上下文。** MCP servers 默认把全部可用工具加载进 context，与项目无关的可以关掉（[[2026-11-20-context-management-in-claude-code]]）。
- **subagent 是上下文隔离手段。** subagent 拥有完全独立的 context window，适合"只要答案、不要过程"的任务，只把摘要返回主 agent（[[2026-11-20-context-management-in-claude-code]]）。Go 练习仓库的测试把这一点固定为数字：子 agent 产生三万字输出后，主历史只有 4 条消息（[[2026-11-20-harness-engineering-go-practice]]）。learn-claude-code 网站据此把 Subagent 归入"规划与控制"层而非"多 agent 平台"层（[[2026-11-20-learn-claude-code-site]]）。
- **prompt 写具体。** Claude Code 课程称短 prompt 长期看反而更费 context，因为 agent 得自己到处看（[[2026-11-20-context-management-in-claude-code]]；作者主张，无测量数据）。
- **只改"这一次发出去的"历史。** Go 练习仓库的 `TransformContext` hook 只改写本次发给模型的消息，不改循环保存的历史（[[2026-11-20-harness-engineering-go-practice]]）。[[deepseek-harness|DeepSeek Harness]] 更彻底：loop 不持有消息历史，每个请求都从 [[session-log]] 派生（[[2026-11-20-deepseek-harness-agent-loop-source]]）。两者都把"保存的历史"与"发给模型的视图"分开。

## 变体与演进

- **运行时内的管理 vs 仓库层的管理。** learn-claude-code、Go 练习仓库、[[microsoft-agent-framework|Microsoft Agent Framework]] 讲的是运行时怎么裁剪消息（压缩、截断、provider）；OpenAI 文章和 [[learn-harness-engineering]] 课程讲的是怎么组织仓库里的文档，让 agent 能按需找到（[[2026-11-20-openai-harness-engineering]]、[[2026-11-20-learn-harness-engineering-course]]）。后者的标题层面主张是"一个巨大的指令文件会失败"（该课程只摄入了首页，正文论点未核实）。
- **从"压缩够用"到"压缩不够"。** [[anthropic|Anthropic]] 2025-11 的文章指出仅靠 compaction 不足以支撑跨多个 context window 的长任务，需要把状态写进环境里的文件（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。见 [[long-running-agents]]。
- **默认值的差异。** Microsoft Agent Framework 的 Harness 中，compaction 在 .NET、Python 里提供 token 上限或自定义策略时才开启，Go 需显式组合；`MaxContextWindowTokens` 的示例值 128,000 只是示例（[[2026-11-20-microsoft-learn-agent-harness]]，页面更新于 2026-10-28）。

## 优缺点和权衡

- **保留 vs 丢弃。** 压缩和清空都在用信息换空间。Claude Code 课程明确提醒自动 compaction 可能丢失此前对话的细节（[[2026-11-20-context-management-in-claude-code]]）。
- **预先注入 vs 按需加载。** 预先注入保证模型一定看到，但占空间且会腐烂；按需加载省空间，但依赖模型主动去读。OpenAI 团队给出的大文件四种失效方式（挤占、等于没有指导、立刻腐烂、难以验证）是偏向按需加载的一手论据（[[2026-11-20-openai-harness-engineering]]）。
- **隔离 vs 可见性。** subagent 保住主上下文，代价是主 agent 看不到中间过程（[[2026-11-20-harness-engineering-go-practice]]）。
- **度量是粗的。** Go 练习仓库用字符数近似 token 数（[[2026-11-20-harness-engineering-go-practice]]）；Claude Code 课程没有给出窗口大小和自动压缩阈值的任何数字（[[2026-11-20-context-management-in-claude-code]]）。

## 不同来源的分歧

> [!warning] 矛盾
> 仅靠运行时的压缩能否支撑长任务，说法不一：
> - Anthropic：compaction "不够"，它并不总是把足够清晰的指示传给下一个 agent（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]，内部实验的定性观察，Opus 4.5 + Claude Agent SDK）。
> - [[openharness|OpenHarness]] 自述：v0.1.6（2026-04-10）起 Auto-Compaction 保留任务状态和 channel 日志，agent 可以跑多天的会话而无需手动 compact/clear（[[2026-11-20-openharness-readme]]，项目自述，无数据）。
> - Microsoft 文档把 compaction 加 looping 作为长时工作的手段，没有讨论跨 session 交接（[[2026-11-20-microsoft-learn-agent-harness]]）。
>
> 三者任务和度量都不同，不能直接比较；详见 [[compaction]] 与 [[long-running-agents]]。

- **`CLAUDE.md` 该写多少。** Claude Code 课程一面提供 `/init` 自动生成，一面建议新项目先不写、按纠错逐步积累以保持精简（[[2026-11-20-the-claude-md-file]]）；OpenAI 团队的结论是入口文件只当目录（[[2026-11-20-openai-harness-engineering]]）。两者都指向"小"，但一个靠克制，一个靠拆分。
- **"上下文管理"归哪一层。** learn-claude-code 网站把 Context Compact 和 Memory 合成"Memory Management"层，把 Skill Loading、Subagent 放在"Planning & Control"层（[[2026-11-20-learn-claude-code-site]]）；本页按功能把它们都算作上下文管理手段，这是本 wiki 的归类，不是来源的说法。

## 采用它的项目

- [[claude-code]]：`/compact`、`/clear`、`/context`、自动 compaction、`CLAUDE.md`、skills、subagents（[[2026-11-20-claude-code-101-course]]）。
- [[claude-agent-sdk]]：被 Anthropic 称为自带 compaction 等上下文管理能力的通用 harness（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- [[codex]]（OpenAI 团队的用法）：短 `AGENTS.md` + 结构化 `docs/` + 机械保鲜的 linter 和 doc-gardening agent（[[2026-11-20-openai-harness-engineering]]）。
- [[openharness]]：Auto-Compact、`CLAUDE.md` 注入、`MEMORY.md`、按需 skills（[[2026-11-20-openharness-readme]]，自述）。
- [[microsoft-agent-framework]]：chat pipeline 里的可选 compaction，context provider 承载记忆与 todo（[[2026-11-20-microsoft-learn-agent-harness]]）。
- [[deepseek-harness]]：请求从 session log 派生，压缩作为维护作业与 loop 协作（后半句是来源页的推断）（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- [[learn-claude-code]]：s06 Subagent、s07 Skill Loading、s08 Context Compact、s09 Memory（[[2026-11-20-learn-claude-code-readme]]）。
- [[pi]] 的 README 不描述压缩和会话存储，无法归类（[[2026-11-20-pi-readme]]）。

## 相关概念

[[compaction]]、[[session-log]]、[[memory]]、[[long-running-agents]]、[[context-files]]、[[skills]]、[[subagents]]、[[mcp]]、[[system-prompt]]、[[tools]]、[[agent-loop]]、[[harness-engineering]]；横向对比见 [[开源-harness-设计取向对比]]。
