---
title: Memory（跨会话持久记忆）
type: concept
aliases: [memory, 记忆, long-term memory, 长期记忆, 持久记忆, MEMORY.md, file memory, 文件记忆]
tags: [agent-harness, memory, context-management]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-the-claude-md-file
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-context-management-in-claude-code
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-openharness-readme
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-harness-engineering-go-practice
---

# Memory（跨会话持久记忆）

## 定义

Memory 指在一个会话结束之后仍然存在、并能在以后的会话里重新进入模型上下文的信息。learn-claude-code 网站对这一课的一句话主张最贴切："有些事实应当挺过摘要和未来的会话"（[[2026-11-20-learn-claude-code-site]]）。

本批资料里"memory"这个词被用在至少四种东西上，先分清：

| 用法 | 是什么 | 谁写 | 何时进入上下文 | 来源 |
|---|---|---|---|---|
| `CLAUDE.md` 当 memory | 项目根目录或用户配置目录下的 markdown，被称为"persistent memory""memory files" | 人，或人让 agent "save to memory" | 每次启动 session 自动读取 | [[2026-11-20-the-claude-md-file]] |
| `MEMORY.md` | 与 `CLAUDE.md` 分开的持久记忆文件，由独立的 `memory/` 子系统管理 | 未说明 | 未说明 | [[2026-11-20-openharness-readme]] |
| file memory（文件记忆） | harness 提供给 agent 的文件存储，由 context provider 承载 | agent（通过工具） | 由 provider 决定 | [[2026-11-20-microsoft-learn-agent-harness]] |
| long-term memory | 从对话里提炼出的事实，下次对话被检索出来加入上下文 | 提炼过程（谁、何时未说明） | 检索命中时 | [[2026-11-20-ai-harness-crash-course]] |

[[anthropic|Anthropic]]《Building effective agents》把 memory 列为 augmented LLM 的三项增强之一（检索、工具、记忆），但全文没有展开（[[2026-11-20-anthropic-building-effective-agents]]）。

## 要解决的问题和动机

- 没有持久记忆，agent 每个会话都从头开始：重新探索 codebase、弄清依赖和已实现的功能，有时只能靠假设（[[2026-11-20-the-claude-md-file]]）。
- 同一个纠正要反复说。[[claude-code|Claude Code]] 课程的建议是：不得不纠正 Claude 时，明确要求它 save to memory；Claude 反复遇到同一问题时，让它把解法存进 `CLAUDE.md`（[[2026-11-20-the-claude-md-file]]、[[2026-11-20-explore-plan-code-commit-workflow]]）。
- [[compaction]] 会丢细节（[[2026-11-20-context-management-in-claude-code]]），需要有一个不受压缩影响的地方放必须留下的事实。

## 工作原理

### 文件即记忆（始终注入）

`CLAUDE.md` 的机制被描述为"内容被 append 到你自己的 prompt 上"，Claude Code 每次启动 session 时自动读取（[[2026-11-20-the-claude-md-file]]；该资料没有区分注入位置是 system prompt 还是用户消息）。存在按受众区分的层级：project level（项目根目录，随版本控制与团队共享）和 user level（用户配置目录，跨所有项目生效）（[[2026-11-20-the-claude-md-file]]）。

这种记忆的特点是**不检索**：文件整个进上下文，所以必须小。课程建议新项目先不写，观察哪里需要反复纠正再补，以保持精简（[[2026-11-20-the-claude-md-file]]）。文件组织方式见 [[context-files]]。

### 仓库即记忆

[[openai|OpenAI]] 团队把这一思路扩大到整个仓库：只有仓库内版本化的工件对 agent 可见，所以设计文档、execution plan（附进度和决策日志）、技术债清单都提交进仓库，入口文件只当目录（[[2026-11-20-openai-harness-engineering]]）。这里没有独立的"记忆子系统"，记忆就是文档，靠 linter、CI 和定期运行的 doc-gardening agent 保鲜。

### harness 管理的文件记忆

[[microsoft-agent-framework|Microsoft Agent Framework]] 的 Harness 把会话文件记忆做成默认开启的 context provider，可用 `DisableFileMemory` 关闭；共享文件访问需显式开启（[[2026-11-20-microsoft-learn-agent-harness]]，页面更新于 2026-10-28）。Go SDK 的默认值写得最具体：文件记忆持久化在 `agent-file-memory` 下，每个 session 一个隔离的工作文件夹，skills 的文件发现会排除 memory 子树（[[2026-11-20-microsoft-learn-agent-harness]]）。

注意这份默认配置的记忆是**按 session 隔离**的；跨选定 session 共享要用带 `scope` 的文件访问 provider，scope 是映射到 provider 管理的文件夹的不透明键而不是路径，且既没有活动 session ID 也没有显式 scope 时直接失败（fail closed）（[[2026-11-20-microsoft-learn-agent-harness]]）。所以它的"file memory"默认更接近"会话工作区"，而不是本页定义的跨会话记忆。

### 提炼与检索式记忆

- ADK 的 long-term memory：从对话里提炼出事实，带到未来的对话里。例子是用户说过"我喜欢用图表看数据"，下周新对话里被检索出来加入上下文（[[2026-11-20-ai-harness-crash-course]]）。提炼由谁在什么时候做、怎样检索，资料只有一句带过。
- learn-claude-code s09 Memory 的关键词是 selection / extraction / consolidation 三个子系统（[[2026-11-20-learn-claude-code-readme]]）。按字面可以读作"选哪些记忆进上下文、从会话里抽取什么、怎样合并整理"，但这是笔者对关键词的解读，章节正文未摄入。

### 写入路径

- 人手写，或人让 agent 写（"save to memory"）（[[2026-11-20-the-claude-md-file]]）。
- `/init` 让 Claude 基于 codebase 生成一份（[[2026-11-20-the-claude-md-file]]）。
- agent 按约定在会话结束时写：见 [[long-running-agents]] 的进度文件。
- 从对话里自动提炼（[[2026-11-20-ai-harness-crash-course]]）。

## 与相邻概念的区别

| 概念 | 存什么 | 生命周期 | 谁写 | 是否进上下文 |
|---|---|---|---|---|
| [[session-log\|session log]] | 一次会话的完整原始记录 | 单个会话（可恢复） | harness，自动 | 作为历史或其派生视图 |
| [[compaction]] 的摘要 | 当前会话较早部分的有损摘要 | 当前会话 | harness 调模型生成 | 替换掉被压缩的历史 |
| [[context-files\|context file]] | 项目规则、约定、命令 | 长期，随仓库版本化 | 主要是人 | 每次启动注入 |
| 进度文件 / 功能清单 | 某个长任务做到哪了 | 任务期间 | agent，按 prompt 约定 | 新会话开头由 agent 读取 |
| memory（本页） | 可复用的事实、偏好、教训 | 跨会话、跨任务 | 人、agent 或提炼过程 | 始终注入或检索命中时 |

边界并不干净：Claude Code 的官方课程直接把 `CLAUDE.md` 叫作 memory（"hierarchy of memory files"）（[[2026-11-20-the-claude-md-file]]）；[[openharness|OpenHarness]] 则把 `CLAUDE.md` 注入和 `MEMORY.md` 持久记忆分成两项能力、两个目录（`prompts/` 与 `memory/`）（[[2026-11-20-openharness-readme]]）。本 wiki 的处理是：静态的项目规则写在 [[context-files]]，会随使用增长的事实写在本页。

Anthropic 长任务文章里的 `claude-progress.txt` 属于"任务状态"而不是通用记忆：它只对这一个任务有意义（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

## 变体与演进

- **从"一个文件"到"子系统"。** learn-claude-code 从 12 课扩到 17 课时新增了 s09 Memory 一章，并把 memory persistence 列为 Claude Code 的组成机制之一（后者是作者的逆向归纳，非官方描述）（[[2026-11-20-learn-claude-code-readme]]）。
- **人格与用户画像。** OpenHarness 之上的个人 agent `ohmo` 的工作区含 `soul.md`（长期人格与行为）、`user.md`（用户画像）和 `memory/` 目录（[[2026-11-20-openharness-readme]]，自述）。
- **不做记忆。** Go 练习仓库明确没有 memory，跨会话的东西只有 context file 和长任务的状态文件（[[2026-11-20-harness-engineering-go-practice]]）。

## 优缺点和权衡

- **始终注入的记忆占上下文。** 文件越大，挤掉的任务内容越多；OpenAI 团队的大 `AGENTS.md` 因此失败，且"立刻腐烂"成陈旧规则的坟场（[[2026-11-20-openai-harness-engineering]]）。
- **记忆会过期。** 没有机械检查的记忆文件无法判断哪些还有效（[[2026-11-20-openai-harness-engineering]]）。
- **记忆是建议，不是强制。** 见下面的矛盾。
- **隐私。** 工具输出可能被存进 long-term memory；要考虑保留多久（[[2026-11-20-ai-harness-crash-course]]）。
- **自动提炼的可靠性**在本批资料里没有任何数据。

## 不同来源的分歧

> [!warning] 矛盾
> 写进 `CLAUDE.md` 的东西模型是否每次都遵守，同一门官方课程的两课说法不同：
> - The CLAUDE.md file 一课：把纠正 save to memory 之后，下次回到项目时 Claude 就知道（[[2026-11-20-the-claude-md-file]]）。
> - Hooks 一课：写在 `CLAUDE.md` 里的指令 Claude "多数时候"会做，但有时不会；必须每次都发生的事不要放进 prompt，要放进 hook（[[2026-11-20-hooks-in-claude-code]]）。
>
> 两者可以调和为"知道"不等于"每次照做"，但前一课没有做这个区分。实用结论：记忆负责让模型知道，[[hooks]] 和 [[permissions]] 负责强制。

- **记忆放在 harness 里还是环境里。** Microsoft 把文件记忆做成 harness 内建的 provider（[[2026-11-20-microsoft-learn-agent-harness]]）；Anthropic 长任务文章和 OpenAI 文章把要记住的东西放在工作目录的普通文件里，靠约定维护（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]、[[2026-11-20-openai-harness-engineering]]）。同一分歧在 [[long-running-agents]] 里展开。
- **memory 是否是 harness 的必备件。** learn-claude-code 网站把它与压缩并列为"Memory Management"层（[[2026-11-20-learn-claude-code-site]]）；AI Harness Crash Course 把它与 context 合成四个设计方面之一（[[2026-11-20-ai-harness-crash-course]]）；Go 练习仓库不做（[[2026-11-20-harness-engineering-go-practice]]）。

## 采用它的项目

- [[claude-code]]：`CLAUDE.md`（project / user 两级）、`/init`、save to memory（[[2026-11-20-the-claude-md-file]]、[[2026-11-20-claude-code-101-course]]）。
- [[openharness]]：`MEMORY.md` 与 `memory/` 子系统；`ohmo` 的 `soul.md`、`user.md`（[[2026-11-20-openharness-readme]]，自述）。
- [[microsoft-agent-framework]]：file memory provider（[[2026-11-20-microsoft-learn-agent-harness]]）。
- [[codex]]（OpenAI 团队的用法）：仓库内文档与 execution plan 充当记忆（[[2026-11-20-openai-harness-engineering]]）。
- [[learn-claude-code]]：s09 Memory（[[2026-11-20-learn-claude-code-readme]]）。

## 相关概念

[[context-management]]（枢纽页）、[[context-files]]、[[session-log]]、[[compaction]]、[[long-running-agents]]、[[hooks]]、[[skills]]（另一种"按需进入上下文的知识"）、[[system-prompt]]。
