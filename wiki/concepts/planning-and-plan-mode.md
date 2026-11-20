---
title: 规划与 plan mode
type: concept
aliases: [planning, plan mode, Plan Mode, 计划模式, TodoWrite, todo 工具, execution plan, exec plan, 执行计划, feature list, 功能清单]
tags: [planning, plan-mode, todo, agent-harness, harness-engineering]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-openharness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-context-management-in-claude-code
---

# 规划与 plan mode

## 定义

本页覆盖三件相关但不同的东西：

- **显式计划**：让 agent 在动手之前把步骤写出来，并在执行中维护它。最常见的载体是一个 todo 工具。
- **Plan mode**：[[agent-harness|harness]] 的一种运行模式，agent 只能用只读工具做调研，产出一份计划交给人审阅，批准后才开始修改（[[2026-11-20-how-claude-code-works]]）。
- **计划作为工件**：把计划写成文件、提交进仓库，让它活得比一次会话长（[[2026-11-20-openai-harness-engineering]]）。

三者的区别在于计划存在哪里、给谁看：对话历史里给模型自己看，harness 状态里给界面和人看，仓库里给以后的 session 和其他 agent 看。

## 要解决的问题和动机

- **不规划的 agent 会漂移**。[[learn-claude-code]] s05 的格言是 "An agent without a plan drifts"（[[2026-11-20-learn-claude-code-readme]]）；网站一版的摘要是"显式计划让长时间的工作可见、可纠正"（[[2026-11-20-learn-claude-code-site]]）。
- **纠偏越早越便宜**。[[claude-code|Claude Code]] 课程主张不要一上来就让 Claude 写代码，否则之后要更多纠偏；审阅计划是最佳纠偏点，因为还没有写任何代码（作者主张，无数据）（[[2026-11-20-explore-plan-code-commit-workflow]]）。见 [[steering-and-cancel]]。
- **计划定义"做完"**。课程对 Plan 一步的定义是"产出行动计划，Claude 用它判断自己是否成功"，并要求在计划里写明什么算正确（[[2026-11-20-explore-plan-code-commit-workflow]]）。
- **透明**。[[anthropic|Anthropic]]《Building effective agents》的三条原则之一是优先 transparency：显式展示 agent 的规划步骤（文中未说明如何实现）（[[2026-11-20-anthropic-building-effective-agents]]）。
- **跨会话接力**。新 session 没有之前的记忆，项目后期的 agent 看到已有不少进展就可能判定任务完成；一份写在环境里的完整清单让它看得到"全部做完"长什么样（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

## 工作原理

### Todo 工具

- learn-claude-code s05 TodoWrite：数据结构是 `TodoItem`，模式是 plan-then-execute，先列步骤再执行（只有章节表里的关键词，章节正文未摄入）（[[2026-11-20-learn-claude-code-readme]]）。
- [[microsoft-agent-framework|Microsoft Agent Framework]] 的 Harness：todo tracking 默认开启，由一个可替换的 context provider 提供（Python 的 `todo_provider`），Go 版是 session-backed 的 todo 工具；可用 `DisableTodoProvider` / `disable_todo` 关闭。示例终端应用会显示 todo 并提供 `/todos` 命令（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 进一步的形态是任务图：learn-claude-code 的 Task System 用 `TaskRecord`、`blockedBy` 和落盘的任务图表达依赖关系，网站摘要是"任务图把模糊目标变成有序、可观察的工作"（[[2026-11-20-learn-claude-code-readme]]、[[2026-11-20-learn-claude-code-site]]）。

### Plan mode

Claude Code 的 plan mode（厂商自述）：

- 只使用 read-only tools，Claude 不能编辑文件；在动手前汇总出行动计划（[[2026-11-20-how-claude-code-works]]）。
- 用 `Shift+Tab` 切换进入，与默认模式、auto accept 并列，属于 [[permissions|权限]]模式（[[2026-11-20-how-claude-code-works]]、[[2026-11-20-explore-plan-code-commit-workflow]]）。课程大纲列了四种模式（manual、auto-accept、auto mode、Plan Mode），视频只讲了三种（[[2026-11-20-claude-code-101-course]]）。
- 流程：给一个调研性的 prompt（例：弄清 WebP 转换应放在哪、是否需要新依赖、如何实现）→ Claude 读相关文件、做 web search → 给出计划 → 用户审阅，不满意就让它补充或修改 → approve 后 Claude 逐项执行，可选择 auto accept 文件编辑或每次询问（[[2026-11-20-explore-plan-code-commit-workflow]]）。
- 课程称 plan mode 的另一个好处是计划完成后，context 里留有"如何得到结果"的过程，有助于后续决策（[[2026-11-20-explore-plan-code-commit-workflow]]）。一个计划做完、开始新功能时应 `/clear`（[[2026-11-20-context-management-in-claude-code]]）。

其他实现：

| 实现 | 形态 | 细节 |
|---|---|---|
| [[openharness\|OpenHarness]]（项目自述） | 三种权限模式之一 | 禁止一切写操作，用于大型重构先审后做；另有 `EnterPlanMode` / `ExitPlanMode` 工具和 `/plan` 命令（[[2026-11-20-openharness-readme]]） |
| Microsoft Agent Framework | agent modes | plan / execute 两种模式默认开启，由 mode provider 提供，可替换或用 `DisableAgentModeProvider` 关闭；Go 版默认从 plan 模式开始；示例应用有 `/mode` 命令（[[2026-11-20-microsoft-learn-agent-harness]]） |
| [[pi\|Pi]] | 不内置 | 见下文分歧 |

Microsoft 文档没有解释为什么这些默认开启、为什么 Go 从 plan 模式开始，也没有说明 plan 模式下限制了哪些工具（[[2026-11-20-microsoft-learn-agent-harness]]）。

### 把计划当作一等工件

[[openai|OpenAI]] 团队的做法（团队自述）（[[2026-11-20-openai-harness-engineering]]）：

- 小改动用临时的轻量计划；复杂工作写 execution plan，附进度和决策日志，并提交进仓库。
- 活跃计划、已完成计划、已知技术债都版本化并集中存放（`docs/` 下有 exec-plans 目录和 PLANS 文档），让 agent 不依赖外部上下文就能运行。
- 背后的原则是 agent 可读性：运行时上下文里访问不到的东西等于不存在，可执行计划是 agent 能看到的仓库内工件之一。

Anthropic 长时运行实验里的 feature list 是同类工件，但更结构化（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）：

- 由第一个 session 的 initializer agent 把用户的高层 prompt 展开成 JSON 文件，每条含 `category`、`description`、`steps`（端到端验证步骤）和 `passes`，初始全部为 `false`。claude.ai 克隆的例子里有 200 多条。
- 之后每个 session 的 coding agent 读清单、选一个未完成的 feature 做，验证后才改 `passes`；prompt 用强措辞禁止删除或修改条目。
- 用 JSON 而不是 Markdown，因为作者观察到模型不恰当地修改或覆盖 JSON 文件的可能性更低（基于试验的观察，无数字）。
- 配套的进度文件记录各 session 做了什么，与 git 历史一起让新 session 快速了解状态。

[[learn-harness-engineering|Learn Harness Engineering]] 把功能清单称为 harness 的 primitive，认为它同时约束"做过头"和"没做完"两种偏差（仅讲义标题，正文未摄入）（[[2026-11-20-learn-harness-engineering-course]]）。更多见 [[long-running-agents]] 与 [[harness-engineering]]。

## 变体与演进

按计划的存放位置和约束强度排列：

| 形态 | 计划存在哪 | 谁来约束 | 例子 |
|---|---|---|---|
| 模型自己在回复里列步骤 | 对话历史 | 无 | — |
| todo 工具 | 对话历史或 harness 的会话状态 | harness 记录并展示 | learn-claude-code s05、Microsoft todo provider |
| plan mode | 对话历史，经人批准 | harness 禁用写工具；人审阅 | Claude Code、OpenHarness、Microsoft |
| 仓库内的计划文件 | 版本化文件 | 约定，加 linter 和 CI 保鲜 | OpenAI exec plans |
| 结构化清单加代码校验 | 版本化文件 | 代码 | Go 练习仓库的 `CheckEdit` |

（[[2026-11-20-learn-claude-code-readme]]、[[2026-11-20-microsoft-learn-agent-harness]]、[[2026-11-20-how-claude-code-works]]、[[2026-11-20-openharness-readme]]、[[2026-11-20-openai-harness-engineering]]、[[2026-11-20-harness-engineering-go-practice]]；这张表的排列方式是笔者的归纳）

最后一行的细节：Go 练习仓库的 `CheckEdit(before, after)` 只允许把 `Passes` 从 false 改成 true，项数变化、描述被改写、true 改回 false 都报错；驱动器在每个会话后校验清单，不合规就用会话前的版本覆盖回去。测试里有一个"作弊会话"把未完成项直接删掉，断言清单被恢复、任务不算完成（截至 2026-11-20 的快照，`CheckEdit` 还是待实现的桩，规格来自测试）（[[2026-11-20-harness-engineering-go-practice]]）。这是把 Anthropic 用强措辞 prompt 表达的软约束改写成了硬约束。

## 优缺点和权衡

- **收益缺少数据**。learn-claude-code s05 的格言说"先列步骤，完成率翻倍"，没有给出任务集、指标或对照条件，只能当作未证实的自述（[[2026-11-20-learn-claude-code-readme]]）。Claude Code 课程的"跳过此流程意味着更多纠偏"同样是主张（[[2026-11-20-explore-plan-code-commit-workflow]]）。
- **多一轮人工**。plan mode 把一次交互拆成调研、审阅、执行三段；课程也说可以不进 plan mode、直接让 Claude explore codebase（[[2026-11-20-explore-plan-code-commit-workflow]]）。
- **计划会过时**。写进仓库的计划需要像文档一样保鲜；OpenAI 团队为此用 linter、CI 和 doc-gardening agent（[[2026-11-20-openai-harness-engineering]]）。Anthropic 的 feature list 由 initializer 一次生成，需求变化或发现遗漏后如何增补，原文没有讨论（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **清单可以被钻空子**。Go 练习仓库的 `CheckEdit` 规格不校验 `Steps`，模型可以改写验证步骤让功能更容易"通过"；第一个会话写出的清单也不经过校验。这两点是来源页读代码后的推断（[[2026-11-20-harness-engineering-go-practice]]）。
- **固定流程对自主性**。内置 plan mode 等于 harness 规定了一种工作节奏，这正是 Pi 反对的（[[2026-11-20-pi-readme]]）。见 [[workflows-vs-agents]]。

## 不同来源的分歧

> [!warning] 矛盾
> **plan mode 该不该由 harness 内置。**
> - 内置：Claude Code 把它作为官方推荐工作流的核心（[[2026-11-20-explore-plan-code-commit-workflow]]）；OpenHarness 内置 Plan Mode（[[2026-11-20-openharness-readme]]）；Microsoft 的 Harness 默认开启 plan / execute 模式和 todo（[[2026-11-20-microsoft-learn-agent-harness]]）。
> - 不内置：Pi 的 README 明文 "Pi ships with powerful defaults but skips features like sub-agents and plan mode. Ask Pi to build what you want, or install a package that does it your way."，理由是让 Pi 适应用户的工作流而不是反过来；README 没有进一步论证（[[2026-11-20-pi-readme]]）。

- **plan mode 属于哪个子系统**：Claude Code 和 OpenHarness 把它当作一种权限模式（[[2026-11-20-how-claude-code-works]]、[[2026-11-20-openharness-readme]]）；Microsoft 把它当作由 context provider 提供的 agent 运行模式，与审批规则分开（[[2026-11-20-microsoft-learn-agent-harness]]）。
- **计划放在 harness 里还是环境里**：Microsoft 的 todo 是 harness 内建的会话状态（[[2026-11-20-microsoft-learn-agent-harness]]）；Anthropic 和 OpenAI 把清单与计划写成工作目录里的文件，harness 本身不变（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]、[[2026-11-20-openai-harness-engineering]]）。
- **人是否审阅计划**：Claude Code 的流程里人批准计划后才执行（[[2026-11-20-explore-plan-code-commit-workflow]]）；Anthropic 长时运行实验里 feature list 由 initializer agent 生成后直接被后续 session 使用，文中没有提到人工审阅环节（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **教学课程的覆盖**：learn-claude-code 把 TodoWrite 放在第 5 课（[[2026-11-20-learn-claude-code-readme]]）；Go 练习仓库 README 验收表的第 3–14 课里没有 todo 工具或 plan mode，规划只以长任务清单的形式出现（第 15–16 课内容未知）（[[2026-11-20-harness-engineering-go-practice]]）。

## 采用它的项目

- todo 工具：[[learn-claude-code]]（[[2026-11-20-learn-claude-code-readme]]）、[[microsoft-agent-framework|Microsoft Agent Framework]]（[[2026-11-20-microsoft-learn-agent-harness]]）。
- plan mode：[[claude-code|Claude Code]]（[[2026-11-20-how-claude-code-works]]）、[[openharness|OpenHarness]]（[[2026-11-20-openharness-readme]]）、Microsoft Agent Framework（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 计划工件：OpenAI 团队的 [[codex|Codex]] 仓库（[[2026-11-20-openai-harness-engineering]]）；Anthropic 基于 [[claude-agent-sdk|Claude Agent SDK]] 的实验（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；[[learn-harness-engineering]] 的模板（[[2026-11-20-learn-harness-engineering-course]]）；Go 练习仓库的 `longrun` 包（[[2026-11-20-harness-engineering-go-practice]]）。
- 明确不内置：[[pi|Pi]]（[[2026-11-20-pi-readme]]）。

## 相关概念

[[workflows-vs-agents]]、[[permissions]]、[[long-running-agents]]、[[harness-engineering]]、[[context-files]]、[[steering-and-cancel]]、[[verification-and-observability]]、[[agent-loop]]、[[subagents]]、[[memory]]、[[开源-harness-设计取向对比]]
