---
title: Learn Claude Code 课程网站首页（learn.shareai.run 中文版）
type: source
kind: doc
aliases: [learn.shareai.run, Learn Claude Code 网站]
tags: [agent-harness, harness-engineering, tutorial, claude-code]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/shareai-learn-claude-code-site.md
author: shareAI-lab
url: https://learn.shareai.run/zh/
---

# Learn Claude Code 课程网站首页（learn.shareai.run 中文版）

> 资料是 2026-11-20 导出的网站首页纯文本，共 166 行，只有课程目录、每课一句话摘要、行数和分层视图，没有任何一课的正文。页面没有标注发布日期，frontmatter 不填 `published`。

## 一段话概括

这是 [[learn-claude-code]] 仓库的配套网站首页。它把课程定位为"从 0 到 1 构建 nano Claude Code-like agent，每次只加一个机制"，列出 **20 个**渐进式课程（s01–s20），标注每课示例代码的行数（从 s01 的 102 行增长到 s20 的 1708 行），并把这些课程归入五个"正交关注点"的架构层。首页还有三个入口：学习路径（timeline）、版本对比（compare）、架构层（layers）。

## 解决什么问题

给仓库的读者一个可浏览的目录：按时间线逐课学、对比相邻版本的代码差异、或按架构层横向看某一类机制。它本身不承载机制讲解，价值在于**课程的切分方式和分层方式**。

## 要点

**核心模式。** 首页开头的论断是："所有 AI 编程 Agent 共享同一个循环：调用模型、执行工具、回传结果。生产级系统会在其上叠加策略、权限和生命周期层。" 给出的 [[agent-loop|agent loop]] 骨架：

```python
while True:
    response = client.messages.create(messages=messages, tools=tools)
    if response.stop_reason != "tool_use":
        break
    for tool_call in response.content:
        result = execute_tool(tool_call.name, tool_call.input)
        messages.append(result)
```

（出处：首页 `agent_loop.py`）

这段代码是示意性的：它没有把 assistant 消息追加回 `messages`，直接照抄不能工作。仓库 README 里的版本才是完整写法。另一个差别是停止判据：网站用 `stop_reason != "tool_use"`，README 用"响应里有没有 `tool_use` 块"。两者在正常情况下等价，但在输出被长度上限截断等边界情形下会分叉（推断，资料没有讨论）。

**消息增长的可视化。** 首页有一个动画，展示循环执行时 `messages[]` 按 user → assistant → tool_call → tool_result → assistant → tool_call 增长。它想传达的是：历史只增不减，这正是后面需要 [[context-management|上下文管理]]的原因。

**20 课目录与每课的一句话主张**（英文摘要原文意译，行数为网站标注的示例代码行数）：

| 课 | 主题 | 行数 | 一句话主张 |
|---|---|---|---|
| s01 | The Agent Loop | 102 | 最小可用的 agent 就是调用模型、跑工具、回传结果的循环 |
| s02 | Tool Use | 135 | 循环不变，能力注册进 dispatch table（[[tools]]） |
| s03 | Permission | 180 | 危险操作在 shell 执行前需要一个 harness 决策点（[[permissions]]） |
| s04 | Hooks | 232 | 横切行为放在循环周围，不要缠进循环里（[[hooks]]） |
| s05 | TodoWrite | 236 | 显式计划让长时间的工作可见、可纠正 |
| s06 | Subagent | 304 | 给每个子任务干净的消息历史，同时保住主线程（[[subagents]]） |
| s07 | Skill Loading | 335 | 只在任务真正需要时注入专门知识（[[skills]]） |
| s08 | Context Compact | 414 | 上下文窗口拥挤时靠压缩保持对话可用（[[compaction]]） |
| s09 | Memory | 528 | 有些事实应当挺过摘要和未来的会话 |
| s10 | System Prompt | 166 | [[system-prompt\|system prompt]] 是由策略、工具、skill 和上下文**生成**的产物 |
| s11 | Error Recovery | 287 | 健壮的 harness 会给失败分类，再决定哪种重试值得做（[[error-recovery]]） |
| s12 | Task System | 297 | 任务图把模糊目标变成有序、可观察的工作 |
| s13 | Background Tasks | 379 | 慢活在别处完成，agent 可以继续推理 |
| s14 | Cron Scheduler | 645 | 周期性工作应由 harness 创建，而不是靠模型记住 |
| s15 | Agent Teams | 745 | 常驻队友让工作并行，不必把所有想法塞进一个上下文 |
| s16 | Team Protocols | 709 | 多 agent 系统需要显式的消息契约，"not vibes" |
| s17 | Autonomous Agents | 648 | 队友能自己发现并认领工作时才真正有用 |
| s18 | Worktree Isolation | 802 | 并行 agent 需要隔离的文件系统，正如需要隔离的对话 |
| s19 | MCP Tools | 835 | 外部服务通过标准的发现与调用协议成为 agent 工具（[[mcp]]） |
| s20 | Comprehensive Agent | 1708 | 最终的 harness 仍是一个循环，只是被让它具备生产形态的系统包围 |

行数不是单调递增的（s10 只有 166 行、s12 是 297 行），说明至少这几课不是在前一课代码上累加，而是回到较小的内核单独演示一个机制（推断）。

## 架构与关键设计决策：五层切分

首页称"五个正交关注点组合成完整的 Agent"：

| 层 | 课数 | 包含 |
|---|---|---|
| Tools & Execution | 4 | s01 Agent Loop、s02 Tool Use、s03 Permission、s04 Hooks |
| Planning & Control | 5 | s05 TodoWrite、s06 Subagent、s07 Skill Loading、s10 System Prompt、s11 Error Recovery |
| Memory Management | 2 | s08 Context Compact、s09 Memory |
| Concurrency & Scheduling | 2 | s13 Background Tasks、s14 Cron Scheduler |
| Multi-Agent Platform | 7 | s12 Task System、s15–s18（Teams、Protocols、Autonomous、Worktree）、s19 MCP Tools、s20 Comprehensive Agent |

值得记下的归类选择：

- Permission 和 Hooks 被放进"工具与执行"层，而不是单独的安全层。也就是说，这套框架把权限看作工具执行管线上的一个决策点。
- Subagent 被归入"规划与控制"，而不是"多 agent 平台"。它在这里的角色是上下文隔离手段，与常驻队友（Teams）是两种东西。
- System Prompt 和 Error Recovery 也在"规划与控制"层。
- Task System 和 MCP Tools 被归入"多 agent 平台"。把 MCP 放在这里而不是"工具与执行"并不直观，"正交"的说法更像是展示上的分组而非严格的架构划分（推断）。

## 适用与不适用的场景

- 适用：作为课程地图；"版本对比"视图（本次未导出）适合看每加一个机制代码改了哪里。
- 不适用：不能当作机制的依据来源。首页每课只有一句话，任何关于具体实现的说法都得去读对应章节。

## 成熟度

- 网站有 EN / 中文 / 日本語三种语言；中文首页的课程标题和摘要仍是英文。
- 没有版本号或更新日期。与仓库 README 的章节数不一致（见下），说明网站与仓库至少有一方滞后。

## 与已有知识的关系

> [!warning] 矛盾
> 同一门课程的两个入口对课程结构说法不同：
> - 网站首页（本页）：**20 课**，含 s10 System Prompt、s11 Error Recovery，团队部分拆成 s15 Agent Teams / s16 Team Protocols / s17 Autonomous Agents / s18 Worktree Isolation，终点是 s20 Comprehensive Agent。
> - 仓库 README（`2026-11-20-learn-claude-code-readme`）：当前规范轨道是 **17 课**，没有 System Prompt 和 Error Recovery 两课，团队相关内容合并为一课 s13 Agent Teams，终点是 s15 Integrated Harness，其后另有 s16 Workflow Runtime 和 s17 Goal Loop（网站目录里没有这两课）；另有一条 12 课的旧轨道。
>
> 两份资料都是 2026-11-20 导出的快照。README 说 `web/` "extracts the root-level course" 并提到网站上有 s16、s17 的视图，这与线上首页显示的 20 课目录对不上。可能的解释是线上站点部署的是另一个版本（推断，无法从资料确认哪个更新）。引用章节号时必须注明是哪条轨道：同一个编号在三条轨道里指不同主题（例如 s10 在网站是 System Prompt，在 README 当前轨道是 Task System，在旧轨道是 Team Protocols）。

- 印证：与 README 一致的部分是前九课的顺序和主题（s01–s09 完全相同），以及"循环不变、机制外挂"的总体主张。
- 补充：网站这一版把 system prompt 组装和错误恢复各立一课，这两项在 README 的 17 课轨道里没有独立位置。

## 涉及的实体和概念

实体：[[learn-claude-code]]、[[claude-code]]。
概念：[[agent-harness]]、[[agent-loop]]、[[tools]]、[[permissions]]、[[hooks]]、[[subagents]]、[[skills]]、[[compaction]]、[[context-management]]、[[system-prompt]]、[[error-recovery]]、[[mcp]]。

## 局限与遗留问题

- 只有首页；timeline、compare、layers 三个子页和 20 课正文都没有导出。
- s10 "system prompt 是生成的产物"具体由哪些片段、按什么顺序拼装？s11 把失败分成哪几类、各自对应什么重试策略？两者都只有标题。
- 20 课版本与 17 课版本谁先谁后、网站是否会同步到 17 课轨道，需要看仓库提交历史或网站源码才能确定。
- "五个正交关注点"是否真的正交（例如 Task System 同时服务单 agent 长任务和多 agent 协作），资料没有论证。
