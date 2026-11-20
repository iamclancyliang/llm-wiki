---
title: learn-claude-code
type: entity
kind: project
aliases: [Learn Claude Code, shareAI-lab/learn-claude-code, learn.shareai.run, "Bash is all you need"]
tags: [agent-harness, harness-engineering, tutorial, claude-code, python]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-learn-harness-engineering-course
---

# learn-claude-code

> [!note] 资料边界
> 两份来源：仓库首页导出和配套网站首页导出。各章正文和 `code.py` 都没有摄入，章节表里的"机制要点"只是关键词（[[2026-11-20-learn-claude-code-readme]]、[[2026-11-20-learn-claude-code-site]]）。

## 是什么、解决什么问题

shareAI-lab 的教学仓库，副标题 "Bash is all you need — A nano claude code–like agent harness, built from 0 to 1"。它从一个 `while True` 循环出发，每章只加一个机制，每章一个可独立运行的 `code.py`，最终拼出一个类似 [[claude-code|Claude Code]] 的 [[agent-harness|agent harness]]。面向想理解 coding agent 内部构造的工程师：不读 Claude Code 源码，而是自己写一遍（[[2026-11-20-learn-claude-code-readme]]）。

配套网站 learn.shareai.run 提供课程目录、每课示例代码行数、学习路径（timeline）、版本对比（compare）和架构层（layers）三个入口，有 EN / 中文 / 日本語三种语言（[[2026-11-20-learn-claude-code-site]]）。

## 关键事实（2026-11-20 导出时的页面数据，[[2026-11-20-learn-claude-code-readme]]）

- 组织：shareAI-lab，64 位贡献者。
- 许可证：MIT。语言：Python 70.4%、TypeScript 28.8%（`web/` 是网站）。
- Star 80.6k，Fork 12.9k；252 次提交；0 个 tag，没有版本号。
- 最近提交在导出前 3 天；最早的提交约在 9 个月前。
- 依赖 `ANTHROPIC_API_KEY`。

## 核心主张与工作原理概要

以下是作者的立场或自述，README 没有实验支撑（[[2026-11-20-learn-claude-code-readme]]）：

- **Agency 是训练出来的，不是编码出来的**；工程师能做的是 [[harness-engineering|harness engineering]]，给模型造"车"。
- **Agent 产品 = Model + Harness**，`Harness = Tools + Knowledge + Observation + Action Interfaces + Permissions`。
- **循环不变，机制外挂**：[[agent-loop|agent loop]] 的最小实现里，停不停由模型决定（响应里没有 `tool_use` 块就返回），代码只执行工具并把结果追加回 `messages[]`。总结句："The loop belongs to the agent. The mechanisms belong to the harness."
- **对 Claude Code 的拆解**：一个 agent loop 加 11 项机制（工具、按需加载 skill、context compaction、subagent、task system、mailbox 团队协作、worktree、权限治理、hooks、memory、MCP）。这是作者的逆向归纳，不是 [[anthropic|Anthropic]] 官方描述。
- s05 格言称"先列步骤，完成率翻倍"，没有任务集、指标或对照条件，只能当作未证实的自述。

README 当前轨道的章节对应的概念：s02 [[tools]]、s03 [[permissions]]、s04 [[hooks]]、s05 TodoWrite（[[planning-and-plan-mode]]）、s06 [[subagents]]、s07 [[skills]]、s08 [[compaction]]（四步：`tool_result_budget`、`snip_compact`、`micro_compact`、`compact_history`）、s09 [[memory]]、s14 [[mcp]]（[[2026-11-20-learn-claude-code-readme]]）。

网站把课程归入五个"正交关注点"：Tools & Execution、Planning & Control、Memory Management、Concurrency & Scheduling、Multi-Agent Platform。Permission 和 Hooks 被放进"工具与执行"层，Subagent 被归入"规划与控制"而不是多 agent 平台（[[2026-11-20-learn-claude-code-site]]）。

## 课程轨道不一致

> [!warning] 矛盾
> 同一门课程存在三条编号不同的轨道，两份资料都是 2026-11-20 的快照：
> - **网站首页：20 课**（s01–s20）。含 s10 System Prompt（[[system-prompt]]）、s11 Error Recovery（[[error-recovery]]），团队部分拆成 s15 Agent Teams / s16 Team Protocols / s17 Autonomous Agents / s18 Worktree Isolation，终点是 s20 Comprehensive Agent（[[2026-11-20-learn-claude-code-site]]）。
> - **仓库 README 当前轨道：17 课**（s01–s17）。没有 System Prompt 和 Error Recovery，团队内容合并为 s13 Agent Teams，s15 Integrated Harness 之后另有 s16 Workflow Runtime 和 s17 Goal Loop，这两课网站目录里没有（[[2026-11-20-learn-claude-code-readme]]）。
> - **仓库旧轨道：12 课**，保留在 `docs/` 与 `agents/`；README 给了新旧映射表（[[2026-11-20-learn-claude-code-readme]]）。
>
> README 说 `web/` 从根目录课程生成，与线上首页的 20 课目录对不上。来源页的推断是线上站点部署的是另一个版本，无法从资料确认哪个更新（[[2026-11-20-learn-claude-code-site]]）。

实际影响：s01–s09 在网站和 README 当前轨道中顺序和主题相同；从 s10 起同一编号指不同主题。例如 s10 在网站是 System Prompt，在 README 当前轨道是 Task System，在旧轨道是 Team Protocols。**引用章节号时必须注明轨道**（[[2026-11-20-learn-claude-code-site]]）。

另外两处细节不一致：

- 网站首页的 loop 示意代码没有把 assistant 消息追加回 `messages`，照抄不能工作；README 的版本才完整。停止判据也不同（网站用 `stop_reason != "tool_use"`，README 用"有没有 `tool_use` 块"）（[[2026-11-20-learn-claude-code-site]]）。
- 网站标注的代码行数不是单调递增（s10 只有 166 行），来源页推断这几课不是在前一课上累加（[[2026-11-20-learn-claude-code-site]]）。

## 优缺点与适用场景

- 适用：从零理解 harness 各机制如何围绕一个循环叠加；每章单文件可运行（[[2026-11-20-learn-claude-code-readme]]）。
- 不适用（README 自述）：教的是"用完即弃"式 harness；常驻型助手所需的 heartbeat、cron 自调度、IM 多渠道路由放在姊妹仓库 claw0（[[2026-11-20-learn-claude-code-readme]]）。
- 网站首页每课只有一句话，不能当作机制的依据来源（[[2026-11-20-learn-claude-code-site]]）。

> [!warning] 矛盾
> 对 workflow 的态度前后有张力：宣言部分把节点图和硬编码路由斥为"不是 agent"，s16 Workflow Runtime 又主张"编排形状固定时就写进代码"。README 没有说明边界在哪（[[2026-11-20-learn-claude-code-readme]]）。相关讨论见 [[workflows-vs-agents]]。

> [!warning] 矛盾
> 谁决定停止：本仓库 README 强调模型决定何时调用工具、何时停止，代码只执行（[[2026-11-20-learn-claude-code-readme]]）。AI Harness Crash Course 说 harness 管理 "when to continue, when to stop"，并把固定顺序、并行和 retry limit 当作常规手段（[[2026-11-20-ai-harness-crash-course]]）；Go 练习仓库的规格里 `Verify`、`FollowUp`、`Steering` 能在模型想停时让循环继续，`MaxTurns` 和取消能让它停下（[[2026-11-20-harness-engineering-go-practice]]）。README 自己的 s17 Goal Loop 也让独立 evaluator 审查每次"想停"（[[2026-11-20-learn-claude-code-readme]]）。

## 同类替代品

- [[learn-harness-engineering]]：同样自称 harness engineering 课程，但工作对象是仓库里的规则、状态文件和验证流程，把运行时当作给定；本仓库教的是运行时代码本身（[[2026-11-20-learn-harness-engineering-course]]）。
- Go 练习仓库：同样"每课一个机制"，在 subagent 和 skill 的表述上与本仓库 s06、s07 相同，并补了错误分类与重试、停止原因与完成门槛的具体规格（[[2026-11-20-harness-engineering-go-practice]]）。
- Anthropic 官方的 Claude Code 101 讲使用而非实现，见 [[claude-code]]。

## 演进时间线（[[2026-11-20-learn-claude-code-readme]]）

- 约 9 个月前（相对导出日）：最早的提交，说明写的是 "11 progressive sessions"。
- 之后扩到 12 课（现为旧轨道），再到 17 课（当前轨道）。
- 导出前 3 天：s13–s16 仍在被修。
- 后续产品（自述）：Kode Agent CLI 与 Kode Agent SDK。

## 未解问题

- 20 课版本与 17 课版本谁先谁后（[[2026-11-20-learn-claude-code-site]]）。
- "Claude Code = …" 清单与 Claude Code 实际实现的吻合度（[[2026-11-20-learn-claude-code-readme]]）。
- 五要素公式没有把[[verification-and-observability|验证与可观测性]]单列，与其他课程不同（[[2026-11-20-learn-claude-code-readme]]）。
