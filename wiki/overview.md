---
title: 综述
type: overview
aliases: [overview, 总览]
tags: [agent-harness, harness-engineering]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-pi-readme
  - 2026-11-20-openharness-readme
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-what-is-claude-code
---

# 综述：Agent Harness 与 Harness Engineering

本知识库当前的主题是 **agent harness**（把模型变成 agent 的那层东西）和 **harness engineering**（设计这层东西的工程实践）。截至 2026-11-20 已摄入 20 份资料：两篇 [[anthropic|Anthropic]] 文章、一篇 [[openai|OpenAI]] 文章、一份 Microsoft 文档、四个开源 harness 的仓库页面和一份源码、三套教程、七份 [[claude-code|Claude Code]] 官方课程资料，以及一个本地 Go 练习仓库。

## 主线

**1. "harness" 有两层含义，读资料时要先分清在说哪一层。**

- **运行时层**：包住模型的程序，驱动模型与工具调用、管理会话与上下文、执行审批策略。Microsoft 文档、[[learn-claude-code]]、[[pi|Pi]]、[[deepseek-harness|DeepSeek Harness]] 和本地练习仓库说的都是这一层（[[2026-11-20-microsoft-learn-agent-harness]]、[[2026-11-20-learn-claude-code-readme]]）。
- **仓库/环境层**：团队在 agent 之外搭建的规则文件、状态文件、linter、测试与验证流程。OpenAI 的文章和 [[learn-harness-engineering]] 课程说的是这一层（[[2026-11-20-openai-harness-engineering]]、[[2026-11-20-learn-harness-engineering-course]]）。

两层的分界并不清晰：Anthropic 的长时运行文章把 Claude Agent SDK 称为 harness，但它报告的改进全部落在 prompt 和工作目录的文件上（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。详见 [[agent-harness]] 与 [[harness-engineering]]。

**2. 运行时层的核心很小：一个循环加一圈机制。**

各资料对最小 agent 的描述一致：模型在循环里调用工具，根据环境反馈决定下一步（[[2026-11-20-anthropic-building-effective-agents]]、[[2026-11-20-what-is-claude-code]]）。围绕 [[agent-loop|agent loop]] 的机制，各教程和实现列出的清单高度重合，可以当作这门学问的目录：

| 机制 | 页面 |
|---|---|
| 给模型用的工具及其接口设计 | [[tools]] |
| 什么能做、要不要问人 | [[permissions]]、[[sandboxing]] |
| 在生命周期节点上确定性地插入逻辑 | [[hooks]] |
| 记录发生过什么、能恢复和续跑 | [[session-log]]、[[memory]] |
| 有限的 context window 怎么用 | [[context-management]]、[[compaction]] |
| 指令从哪来、怎么组装 | [[system-prompt]]、[[context-files]]、[[skills]] |
| 先想再做 | [[planning-and-plan-mode]] |
| 人中途介入 | [[steering-and-cancel]] |
| 出错与截断 | [[error-recovery]] |
| 分工与上下文隔离 | [[subagents]] |
| 怎么算做完、怎么看见过程 | [[verification-and-observability]] |
| 跨多个会话完成一件事 | [[long-running-agents]] |
| 接外部能力、扩展 harness 本身 | [[mcp]]、[[plugins-and-extensibility]] |

**3. 仓库/环境层的核心是让 agent 能读懂环境、并用机械手段约束它。**

OpenAI 团队的经验是：agent 在上下文里访问不到的知识等于不存在，所以知识要进仓库；一个巨大的 AGENTS.md 行不通，要改成约 100 行的目录加结构化文档；架构和"品味"靠自定义 linter 和结构测试强制，而不是靠提示词（[[2026-11-20-openai-harness-engineering]]）。Anthropic 的长时运行方案走的是同一条路：用 feature list、进度文件和 git 提交让每个新会话快速接上（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

**4. 确定性的东西交给代码，不要交给提示词。**

这是跨资料反复出现的一条原则：hooks 每次必定执行，而 CLAUDE.md 里的指令只是多数时候被遵守（[[2026-11-20-hooks-in-claude-code]]）；安全控制必须由软件强制（[[2026-11-20-ai-harness-crash-course]]）；feature list 只允许改一个字段并由代码校验（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；架构不变量用 linter 强制（[[2026-11-20-openai-harness-engineering]]）。

## 主要分歧

资料之间没有统一答案的问题，各概念页里有展开：

- **loop 该管多少事。** [[openharness|OpenHarness]] 把权限、hook、重试、压缩都算进 loop/engine；DeepSeek Harness 的 loop 只管 turn/step 边界和日志一致性，其余交给插件（[[2026-11-20-openharness-readme]]、[[2026-11-20-deepseek-harness-agent-loop-source]]）。见 [[agent-loop]] 和 [[开源-harness-设计取向对比]]。
- **谁决定停止。** learn-claude-code 强调模型决定何时停；但验证钩子、独立 evaluator、最大轮数和取消都能推翻模型的决定（[[2026-11-20-learn-claude-code-readme]]、[[2026-11-20-harness-engineering-go-practice]]）。见 [[verification-and-observability]]。
- **权限系统还是沙箱。** OpenHarness 和 Claude Code 内置多级权限；Pi 明确不做权限系统，把隔离交给容器或 micro-VM（[[2026-11-20-pi-readme]]）。见 [[permissions]] 与 [[sandboxing]]。
- **subagent 和 plan mode 是否属于 harness 核心。** OpenHarness、Claude Code、Microsoft 内置；Pi 认为应由用户或扩展包实现。见 [[subagents]]、[[planning-and-plan-mode]]。
- **compaction 够不够支撑长任务。** Anthropic 明确说不够，需要跨会话的交接工件；Microsoft 把 compaction 加 looping 当作长时工作的手段（[[2026-11-20-microsoft-learn-agent-harness]]）。见 [[long-running-agents]]。
- **状态放在 harness 里还是环境里。** Microsoft 把 todo、文件记忆做成内建组件；Anthropic 和 OpenAI 把进度和计划放进仓库的普通文件。
- **质量门的松紧。** Anthropic 要求每个会话留下可合并的干净状态；OpenAI 主张少设阻塞性合并门，靠后台 agent 持续清理。
- **要不要框架。** Anthropic 劝人从最简单的方案开始、少用抽象层；Microsoft 提供默认开启十来项能力的组合式 harness。见 [[workflows-vs-agents]]。

## 术语陷阱

同一个词在不同资料里指不同的东西，跨资料比较前要先对齐：

- **harness**：运行时程序，或仓库级环境（见上文主线 1）。
- **turn**：Go 练习仓库的一个 turn 是一次模型调用加一批工具；DeepSeek Harness 把这个粒度叫 step，turn 指从用户输入到 agent 停下的整段（见 [[agent-loop]]）。
- **session**：有的资料指可持久化、可隔天续跑的对话线程，Anthropic 长时运行文章里指一次运行，约等于一个 context window（见 [[session-log]]）。
- **memory**：至少指四种东西——CLAUDE.md、MEMORY.md、harness 管理的文件记忆、提炼检索式的长期记忆（见 [[memory]]）。
- **auto 模式**：Claude Code 的 auto-accept 只免去文件编辑的确认，OpenHarness 的 Auto 是全部放行（见 [[permissions]]）。

## 证据的成色

读这批资料时要注意：

- 几乎没有对照实验或第三方验证。OpenAI 的"约 100 万行、零人工手写"和 Anthropic 的长时运行方案都是团队自述；Anthropic 的作者自己把方案定位为"一组可能的解法"。
- 开源项目的页面多为 README 自述，只有 DeepSeek Harness 的 agent loop 有一份源码可查。star 数、版本号都是 2026-11-20 导出时的页面数据。
- learn-claude-code 对 Claude Code 的"一个循环加若干机制"是第三方逆向归纳，不是 Anthropic 的官方描述。
- 视频转录稿有识别错误，部分配置项写法是还原的，来源页里有标注。

## 尚未解决的问题

- 单 agent 还是多 agent 更适合长任务？Anthropic 认为尚无定论，OpenAI 已在生产中大量使用 agent 审 agent。
- 压缩后的历史与只追加的会话日志如何对应、如何恢复？只有 DeepSeek Harness 的源码给了一种答案。
- prompt injection 怎么防？资料只说沙箱不够，没有给出完整方案。
- 怎么评估一个 harness 的好坏？只有入门视频提了三种评估方式，没有资料给出方法或数据。
- OpenAI 那套做法在多大程度上依赖其团队和代码库的特殊条件？作者自己说端到端自主不应假定可泛化。

## 资料缺口

- [[learn-harness-engineering]] 课程的 14 讲正文和"前沿 Harness 拆解"栏目未导出，目前只有欢迎页。
- Claude Code 101 课程里 Subagents、Skills、MCP 等 6 课的正文不在资料里。
- DeepSeek Harness 的 `docs/architecture.md` 和 Cordis 论文未摄入，该项目的架构描述多为推断。
- 笔记本里有一个 YouTube 视频（`jKErNxuxPXg`）处于报错状态，没有内容。
- [[codex|Codex]] 和 Claude Agent SDK 没有一手文档，只有其他资料的侧面描述。
