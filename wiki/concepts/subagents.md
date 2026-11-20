---
title: Subagents（子 agent）
type: concept
aliases: [subagent, sub-agent, 子 agent, 子智能体, background agents, task tool, orchestrator-workers]
tags: [agent-harness, subagents, context-isolation, multi-agent]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-context-management-in-claude-code
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-what-is-claude-code
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-openharness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
---

# Subagents（子 agent）

## 定义

subagent（子 agent）是主 agent 在运行中另开的一个 [[agent-loop|agent loop]]：它有自己独立的 context，从一条任务说明开始工作，结束时只把结果交还给主 agent，中间过程不进入主 agent 的 context。learn-claude-code 的表述是"给子任务全新的 `messages[]`，只把最终文本作为一条 tool result 返回"（[[2026-11-20-learn-claude-code-readme]]）；[[claude-code|Claude Code]] 官方视频的表述是 subagent 拥有完全独立的 context window，完成后只把摘要返回主 agent（[[2026-11-20-context-management-in-claude-code]]）。

## 要解决的问题和动机

- **保住主 context**：每个读过的文件、每条命令输出都会追加进 context window，而空间有限（[[2026-11-20-context-management-in-claude-code]]）。把"只要答案、不要过程"的任务交给 subagent，过程产生的内容就留在它那边。官方课程对 subagents 的定位是"委派任务，并保持主 context 干净"（[[2026-11-20-claude-code-101-course]]）；learn-claude-code 网站的一句话是"给每个子任务干净的消息历史，同时保住主线程"（[[2026-11-20-learn-claude-code-site]]）。所以它首先是一种 [[context-management|上下文管理]]手段。
- **并行**：Claude Code 的 subagents 与主 agent 并行运行（[[2026-11-20-context-management-in-claude-code]]）；[[microsoft-agent-framework|Microsoft Agent Framework]] 的 background agents 是"并行委派给具名子 agent"（[[2026-11-20-microsoft-learn-agent-harness]]）。
- **不带成见的审查**：官方工作流在提交前先跑一个 subagent code reviewer（[[2026-11-20-explore-plan-code-commit-workflow]]）；课程大纲称之为 fresh-context reviewer，与自己过目并列（[[2026-11-20-claude-code-101-course]]）。

## 工作原理

Go 练习仓库用测试把最小行为固定了下来（快照中 `Subagent` 的函数体仍是桩，以下是规格；[[2026-11-20-harness-engineering-go-practice]]）：

- `Subagent(model, tools, system, opts) Tool` 把"再开一个循环"包装成一个名为 `task` 的[[tools|工具]]。主 agent 像调用别的工具一样调用它。
- 子 agent 的历史只有 `[system, user(prompt)]`，跑完只返回最后一条消息的文字。
- **隔离的效果**：测试让子 agent 产生三万字输出，断言主历史只有 4 条消息且 `Size ≤ 200` 字符，主模型看不到中间过程。
- **失败不上传**：子 agent 受自己的 `Options` 约束；它撞上 `MaxTurns` 时，主 agent 收到一条含"出错"的工具结果，而不是跟着失败。
- **取消向下传**：取消通过 `ctx` 传到子 agent。
- **不递归、继承权限**：命令行入口里子 agent 拿到的工具集不含 `task`，并继承父级的[[permissions|权限]]策略。
- 空 prompt 报错。

其他项目的对应物：

- [[deepseek-harness|DeepSeek Harness]] 的 loop 里，`cancel` 的 cause 是封闭联合 `user | parent | disposed | hook`；`parent` 暗示父 agent 可取消子 agent（来源页标为推断；[[2026-11-20-deepseek-harness-agent-loop-source]]）。仓库有 subagent 机制是从分支名 `feat/subagent-names` 推断的，README 没有明文（[[2026-11-20-deepseek-harness-readme]]）。
- [[openharness|OpenHarness]] 的 `coordinator/` 子系统负责 subagent 派生与团队协调，工具清单里有 Agent / SendMessage / TeamCreate；v0.1.6 自述 subprocess teammate 以 headless worker 模式运行（项目自述，协议和失败处理没有细节；[[2026-11-20-openharness-readme]]）。

## 变体与演进

- **早期表述：orchestrator-workers**。[[anthropic|Anthropic]] 2024-12 的《Building effective agents》描述了一种 workflow：中心 LLM 动态拆任务、委派给 worker LLM、再综合结果，适用于无法预知子任务的场景（如要改哪些文件）。把它看作 subagent 委派模式的早期表述是来源页的推断，原文没有用 subagent 一词（[[2026-11-20-anthropic-building-effective-agents]]）。相关讨论见 [[workflows-vs-agents]]。
- **作为工具的 subagent**：一次调用、同步返回一条结果（Go 练习仓库、learn-claude-code s06；[[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-learn-claude-code-readme]]）。
- **后台委派**：Microsoft 的 background agents 在 .NET、Python 可选开启，截至 2026-10-28 仍为 experimental，Go 没有打包好的 provider。文档特意把它与 background responses 区分开：后者是用 continuation token 轮询或恢复同一个 provider 请求，不涉及子 agent（[[2026-11-20-microsoft-learn-agent-harness]]）。
- **agent 审 agent**：[[openai|OpenAI]] 团队让 [[codex|Codex]] 在本地自审，再请求本地和云端的其他 agent 审查，循环到所有 agent reviewer 满意（团队自述；如何避免互相放水没有给出机制；[[2026-11-20-openai-harness-engineering]]）。文中的 reviewer 是否以 subagent 形式派生，资料没有说明。

### 与常驻多 agent 团队的区别

| 维度 | subagent | 常驻队友（agent teams） |
|---|---|---|
| 生命周期 | 为一个子任务创建，交回结果即结束 | 常驻，持续存在 |
| 与主 agent 的关系 | 被调用，只回传最终结果 | 协作，自己认领任务，通过消息协议往来 |
| 需要的配套 | 一个工具入口 | 任务系统、原子化任务认领、消息契约、绑定任务的 worktree |
| 在 learn-claude-code 网站的归层 | Planning & Control | Multi-Agent Platform |

依据：learn-claude-code 的 README 在 s13 Agent Teams 里列出常驻队友、原子化任务认领、task-bound worktrees、typed protocols，并把 "async mailbox team coordination" 与 "subagent spawning" 分列为 Claude Code 的两项机制（作者的逆向归纳，不是官方描述；[[2026-11-20-learn-claude-code-readme]]）。网站把 Subagent 归入"规划与控制"层而不是"多 agent 平台"层，并用单独几课讲 Teams、Team Protocols（"多 agent 系统需要显式的消息契约"）、Autonomous Agents、Worktree Isolation（[[2026-11-20-learn-claude-code-site]]）。文件系统层面的隔离见 [[sandboxing]]。

## 优缺点和权衡

- **优点**：主 context 不被过程内容占用；可以并行；审查者不带实现过程的成见（[[2026-11-20-context-management-in-claude-code]]、[[2026-11-20-claude-code-101-course]]）。
- **代价一：主 agent 看不到过程**。这是设计目的，但也意味着子 agent 没写进最终文本的发现就丢了（后半句是笔者推断）。适用边界正是官方说的"只要答案、不要过程"（[[2026-11-20-context-management-in-claude-code]]）。
- **代价二：成本**。Anthropic 的一般性判断是 agentic 系统用延迟和成本换任务表现（[[2026-11-20-anthropic-building-effective-agents]]）；多开一个循环就多一份模型调用（这是笔者的推论，没有资料给出 subagent 的成本数据）。
- **代价三：错误处理要另外设计**。子 agent 的失败、取消、步数上限都需要约定如何传回父级（[[2026-11-20-harness-engineering-go-practice]]）；DeepSeek Harness 的 `kick` 吞掉异常后 `whenIdle()` 不会 reject，这对"父 agent 等待子 agent"意味着什么，来源页列为待查（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 不同来源的分歧

> [!warning] 矛盾
> subagent 是否属于 harness 的核心：
> - 属于：learn-claude-code 把 "subagent spawning" 列进 Claude Code 的组成清单（[[2026-11-20-learn-claude-code-readme]]）；OpenHarness 把 `coordinator/` 做成固定子系统（[[2026-11-20-openharness-readme]]）；Claude Code 官方课程有 subagents 专课（[[2026-11-20-claude-code-101-course]]）。
> - 不属于：[[pi|Pi]] 的 README 明说 "skips features like sub-agents and plan mode"，要用户让 Pi 自己造，或安装别人做好的 package（[[2026-11-20-pi-readme]]）。
> - 居中：Microsoft 把 background agents 做成可选、默认不开的能力（[[2026-11-20-microsoft-learn-agent-harness]]）。
>
> Pi 没有论证为什么 subagent 不适合内置，只给了"让 Pi 适应你的工作流"这一句理由。

- **单 agent 还是多 agent，是开放问题**。Anthropic 的长时运行文章在结尾写明：单一通用 coding agent 与多 agent 架构哪个更好尚不清楚；专门的测试 agent、QA agent、代码清理 agent "似乎有理由"做得更好，但未验证（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。该文实验里的 initializer agent 和 coding agent 不是 subagent：两者只是初始 user prompt 不同，system prompt、工具集和 harness 完全相同，且按 session 先后串行（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **团队内容怎么切分**：learn-claude-code 的 README（17 课轨道）把团队相关内容并为 s13 一课，网站（20 课轨道）拆成 s15–s18 四课；两条轨道的矛盾见 [[2026-11-20-learn-claude-code-site]]。
- **并行与否**：Claude Code 的 subagents 并行运行（[[2026-11-20-context-management-in-claude-code]]）；Go 练习仓库的工具串行执行，subagent 作为工具也就是串行的（[[2026-11-20-harness-engineering-go-practice]]）。这是实现差异，不是矛盾。
- **入门视频的措辞**：《What is Claude Code?》说 agent 可以访问"其他 AI agents"，没有展开（[[2026-11-20-what-is-claude-code]]）。

## 采用它的项目

| 项目 | 形态 | 来源 |
|---|---|---|
| [[claude-code\|Claude Code]] | 独立 context window、并行、只回摘要；可自定义 | [[2026-11-20-context-management-in-claude-code]]、[[2026-11-20-claude-code-101-course]] |
| [[openharness\|OpenHarness]] | `coordinator/`：subagent 派生加团队协调（自述） | [[2026-11-20-openharness-readme]] |
| [[microsoft-agent-framework\|Microsoft Agent Framework]] | background agents，可选，experimental | [[2026-11-20-microsoft-learn-agent-harness]] |
| [[learn-claude-code]] | s06 Subagent；团队另见 s13（README 轨道） | [[2026-11-20-learn-claude-code-readme]] |
| Go 练习仓库 | `task` 工具的规格与测试（实现待完成） | [[2026-11-20-harness-engineering-go-practice]] |
| [[deepseek-harness\|DeepSeek Harness]] | 有相关分支名，机制未知（推断） | [[2026-11-20-deepseek-harness-readme]] |
| [[pi\|Pi]] | 明确不内置 | [[2026-11-20-pi-readme]] |

## 相关概念

[[context-management]]、[[compaction]]（另一种腾出 context 的办法）、[[agent-loop]]、[[tools]]、[[permissions]]、[[sandboxing]]、[[workflows-vs-agents]]、[[long-running-agents]]、[[steering-and-cancel]]、[[verification-and-observability]]（code review）；横向比较见 [[开源-harness-设计取向对比]]。
