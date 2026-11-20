---
title: Long-running agents（跨 context window 的长任务）
type: concept
aliases: [long-running agents, 长时运行 agent, 长任务, 跨会话任务, initializer agent, coding agent, feature list, 功能清单]
tags: [agent-harness, long-running, harness-engineering, state]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-openharness-readme
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-pi-readme
---

# Long-running agents（跨 context window 的长任务）

## 定义

Long-running agent 指任务规模超过一个 context window、需要跨多个窗口或多个 session 才能完成的 agent 工作方式。核心难题由 [[anthropic|Anthropic]] 2025-11-26 的文章说得最清楚：agent 只能在离散的 session 里工作，每个新 session 开始时对之前发生的事**没有记忆**；文中的类比是轮班工程师，每班新来的人都不记得上一班发生了什么（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

这里"长"有两种含义，资料里都出现了：

- **跨多个全新上下文接力**：每个 session 从空白上下文开始，靠环境里的工件接上（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **单次运行持续很久**：[[openai|OpenAI]] 团队自述单次 [[codex|Codex]] 运行经常在一个任务上持续工作超过 6 小时（[[2026-11-20-openai-harness-engineering]]，团队自述，未说明其间的上下文如何管理）。

## 要解决的问题和动机

Anthropic 的实验（Opus 4.5，[[claude-agent-sdk|Claude Agent SDK]]，从一句高层 prompt 构建 claude.ai 克隆，跨多个 context window 循环运行；定性观察，未报告 session 数、时长、成本或通过的功能数）观察到三种失败模式（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）：

1. **一次做太多（试图 one-shot）。** 实现到一半上下文用尽，下一个 session 面对半成品且无文档的功能，花大量时间把基本功能重新跑起来。即使有 [[compaction]] 也会发生。
2. **过早宣布整个项目完成。** 后期的 agent 实例看到已有不少进展，就判定任务完成。
3. **过早把单个功能标为完成。** 改了代码、跑了单元测试或 `curl`，但没意识到功能端到端并不能用。

[[learn-harness-engineering]] 课程把同一组问题列为学习目标：跨会话丢失上下文、提前宣告完成、不验证自己的工作；并把 agent 的两种典型偏差概括为"做过头"和"没做完"（[[2026-11-20-learn-harness-engineering-course]]，只摄入了首页，依据是讲义标题）。

## 工作原理：initializer + coding agent

Anthropic 的做法不改模型也不改 harness 代码，只改环境和 prompt（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

**两种 prompt，同一个 harness。** 第一个 session 用 initializer prompt 搭环境；之后每个 session 用 coding prompt 做增量进展。脚注澄清两者被称为不同的 "agent" 只是因为初始 user prompt 不同，[[system-prompt|system prompt]]、工具集和 harness 完全相同。

**环境里的四个工件：**

| 工件 | 内容 | 防的是哪种失败 |
|---|---|---|
| feature list（JSON） | 把用户 prompt 展开成完整功能需求，每条含 `category`、`description`、`steps`（端到端验证步骤）、`passes`，初始全为 `false` | 过早宣布项目完成；一次做太多 |
| 进度文件 `claude-progress.txt` | 各 session 做了什么的记录 | 留下无文档的半成品 |
| git 历史 | 描述性 commit message；初始 commit 展示新增文件 | 同上；并可 revert 回到可工作状态 |
| `init.sh` | 启动 dev server 的脚本 | 每个 session 摸索怎么跑应用 |

claude.ai 克隆的例子里 initializer 生成了 200 多条功能。清单用 JSON 而不是 Markdown，是因为作者观察到模型不恰当地修改或覆盖 JSON 文件的可能性更低（无数字）（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

**每个 session 的开场流程**：`pwd` 确认工作目录 → 读 git log 和进度文件 → 读清单，选优先级最高的未完成功能 → 用 `init.sh` 启动，**先跑一遍基础端到端测试**再开始新功能。最后一步的理由是上一个 session 可能留下了坏状态，直接做新功能会让问题更糟（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

**每个 session 的三条纪律：**

- **每次只做一件事。** 一个 session 一个功能。
- **验证后才改 `passes`。** coding agent 只允许改这一个字段；要用浏览器自动化像人类用户那样测试（见 [[verification-and-observability]]）。
- **干净状态交接。** 结束时提交 git、更新进度文件，把环境留在"可以合并到 main 分支"的状态：没有大 bug，代码有序、有文档（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

git 在这里同时是**检查点**和 [[error-recovery|错误恢复]]手段：模型可以用它 revert 坏的改动。

### 把约定变成代码

Anthropic 用强措辞的 prompt 约束"只改 `passes` 字段"，这是软约束，文章没说违反频率（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。Go 练习仓库的 `longrun` 包把同一套做法写成了驱动器和校验（[[2026-11-20-harness-engineering-go-practice]]；该仓库此部分是带测试的规格，实现仍是桩）：

- `NextPrompt`：清单不存在 → initializer prompt；全部通过 → 完成；否则 → coding prompt。**完成与否由清单判定，不由模型的一句话判定。**
- `CheckEdit(before, after)`：只允许把 `Passes` 从 false 改成 true；项数变化、描述被改写、true 改回 false 都报错。
- `Drive`：每轮开一个全新上下文的会话，会话后校验清单，不合规就用会话前的清单覆盖回去；开满 `maxSessions` 返回错误。测试里有一个"作弊会话"把未完成项直接删掉，断言清单被恢复、任务不算完成。
- 单个会话用完 turn 数不算失败：进度在磁盘上，下一个会话接着做。

注释里的设计理由："提示词是请求，模型可能不照做；代码是规则，模型绕不过去。"来源页同时指出这份规格的两个漏洞（推断）：不校验 `Steps`，模型可以改写验证步骤；initializer 写出的第一份清单不经过校验。

### 落盘的任务图

功能清单是一张扁平的表。learn-claude-code 的 Task System 一章（README 轨道 s10）把它推广为带依赖的任务图：关键词是 `TaskRecord` / `blockedBy` / 落盘的任务图，README 的阶段划分把它归入"跑长任务"，一句话是 "Task systems let goals persist beyond a single conversation"（[[2026-11-20-learn-claude-code-readme]]）。网站对同一课的主张是"任务图把模糊目标变成有序、可观察的工作"（[[2026-11-20-learn-claude-code-site]]）。具体数据结构需读章节原文。

同一组里的相邻机制：后台任务（慢命令在别处执行，完成后通过 notification queue 注入）、cron 调度（"周期性工作应由 harness 创建，而不是靠模型记住"）、goal loop（独立 evaluator 审查每次"想停"）（[[2026-11-20-learn-claude-code-readme]]、[[2026-11-20-learn-claude-code-site]]）。

## 变体与演进

- **仓库即记录系统。** OpenAI 团队把 execution plan 当一等工件：复杂工作写计划，附进度和决策日志，提交进仓库；活跃计划、已完成计划、技术债清单都版本化（[[2026-11-20-openai-harness-engineering]]）。与 Anthropic 的进度文件是同一思路的团队级版本。
- **闭环图。** learn-harness-engineering 首页的流程是：明确目标（`AGENTS.md`）→ 初始化检查（`init.sh`）→ 运行任务 ⇄ 运行反馈 → 验证与评审 → 未通过回到运行、通过则清理与交接（`claude-progress.md`）（[[2026-11-20-learn-harness-engineering-course]]；箭头走向是来源页根据边标签重建的推断）。
- **有界 looping。** [[microsoft-agent-framework|Microsoft Agent Framework]] 的 Harness 提供可选的 looping：由 evaluator 或谓词驱动的**有界**重新调用，标注为 experimental（[[2026-11-20-microsoft-learn-agent-harness]]，页面更新于 2026-10-28）。
- **靠压缩撑长会话。** [[openharness|OpenHarness]] 自述 Auto-Compaction 让 agent 跑多天的会话（[[2026-11-20-openharness-readme]]）。
- **常驻型。** learn-claude-code 自述它教的是"用完即弃"式 harness；常驻助手需要的 heartbeat、cron 自调度放在姊妹仓库里（[[2026-11-20-learn-claude-code-readme]]）。
- **持久化运行时。** [[pi|Pi]] 有 `pi-durable` 包，机制未知（[[2026-11-20-pi-readme]]）；[[deepseek-harness|DeepSeek Harness]] 的事件溯源 loop 被来源页评价为适合作可恢复长任务的参考实现（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

文件名在各处略有不同：Anthropic 用 `claude-progress.txt`，learn-harness-engineering 用 `claude-progress.md`，Go 练习仓库用 `progress.md`（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]、[[2026-11-20-learn-harness-engineering-course]]、[[2026-11-20-harness-engineering-go-practice]]）。

## 优缺点和权衡

- 每个 session 的开场流程要花 token 和时间重建状态；Anthropic 称 `init.sh` 等工件反过来省了一些 token，未量化（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- 清单由 initializer 一次生成，需求变化或发现遗漏时如何增补未讨论；"优先级最高"没有对应字段（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]，来源页记下的遗留问题）。
- 验证能力决定上限：通过 Puppeteer MCP 看不到浏览器原生 alert modal，依赖它的功能 bug 更多（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- 错误会累积（compounding errors）是自主 agent 的一般代价（[[2026-11-20-anthropic-building-effective-agents]]）；长任务把这个问题放大，所以才要求每个 session 先验证再动手（后半句是笔者推断）。
- 证据强度有限：Anthropic 自己的定位是 "one possible set of solutions"，demo 只针对全栈 web app；OpenAI 强调其端到端自主高度依赖该仓库的特定结构，不应假定可泛化（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]、[[2026-11-20-openai-harness-engineering]]）。

## 不同来源的分歧

> [!warning] 矛盾
> **状态放在 harness 里还是环境里。**
> - 放在环境里：Anthropic 的 harness 不变，功能清单、进度、检查点都是工作目录里的普通文件和 git，靠 prompt 约定维护（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；OpenAI 团队和 learn-harness-engineering 同一取向（[[2026-11-20-openai-harness-engineering]]、[[2026-11-20-learn-harness-engineering-course]]）。
> - 放在 harness 里：Microsoft Agent Framework 把 todo 追踪、文件记忆、plan/execute 模式做成默认开启的内建 provider，长时工作靠 compaction 加 looping，文档没有讨论跨 session 交接（[[2026-11-20-microsoft-learn-agent-harness]]）；learn-claude-code 的任务图由 harness 的 task system 落盘（[[2026-11-20-learn-claude-code-readme]]）。
>
> 两种取向并不互斥：Go 练习仓库的状态在环境里（两个文件），校验在 harness 里（`CheckEdit`、`Drive`）（[[2026-11-20-harness-engineering-go-practice]]）。

> [!warning] 矛盾
> **仅靠 compaction 够不够。** Anthropic 说不够（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；OpenHarness 自述靠 Auto-Compaction 可跑多天（[[2026-11-20-openharness-readme]]，无数据）。详见 [[compaction]]。

> [!warning] 矛盾
> **质量门该多严。** Anthropic 要求每个 session 留下可合并的干净状态、测试通过才标完成（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；OpenAI 团队主张减少阻塞性合并门、flaky test 重跑了事，理由是"纠错成本低，等待成本高"，并明说在低吞吐环境里这样做是不负责任的（[[2026-11-20-openai-harness-engineering]]）。场景不同（单 agent 串行 vs 多 agent 高吞吐加持续垃圾回收），未必是直接矛盾。

- **单 agent 还是多 agent。** Anthropic 把它列为开放问题：专门的测试、QA、清理 agent "似乎有理由"做得更好，未验证（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。OpenAI 团队已经在用 agent 审 agent 的循环和后台清理 agent（[[2026-11-20-openai-harness-engineering]]）。

## 采用它的项目

- [[claude-agent-sdk]]：Anthropic 实验所用的 harness（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- [[codex]]：OpenAI 团队的长时运行与 execution plan（[[2026-11-20-openai-harness-engineering]]）。
- [[learn-harness-engineering]]：把 initializer、功能清单、干净交接各立一讲，并提供模板（[[2026-11-20-learn-harness-engineering-course]]）。
- [[learn-claude-code]]：Task System、Background Tasks、Cron Scheduler、Goal Loop（[[2026-11-20-learn-claude-code-readme]]）。
- [[microsoft-agent-framework]]：todo provider、looping（[[2026-11-20-microsoft-learn-agent-harness]]）。
- [[openharness]]：Auto-Compaction 与 `ohmo`（[[2026-11-20-openharness-readme]]，自述）。

## 相关概念

[[context-management]]（枢纽页）、[[compaction]]、[[session-log]]、[[memory]]、[[verification-and-observability]]、[[error-recovery]]、[[planning-and-plan-mode]]、[[context-files]]、[[subagents]]、[[workflows-vs-agents]]、[[harness-engineering]]。
