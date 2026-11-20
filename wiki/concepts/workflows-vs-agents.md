---
title: Workflows 与 agents 的区分
type: concept
aliases: [workflows vs agents, agentic systems, workflow 模式, 图式编排, augmented LLM, Explore-Plan-Code-Commit]
tags: [workflow, agent, orchestration, anthropic]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-pi-readme
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-context-management-in-claude-code
---

# Workflows 与 agents 的区分

## 定义

[[anthropic|Anthropic]] 在《Building effective agents》（2024-12-19）里把 agentic systems 分成两类（[[2026-11-20-anthropic-building-effective-agents]]）：

- **Workflows**：LLM 和[[tools|工具]]通过**预定义的代码路径**编排。
- **Agents**：LLM **动态主导**自己的流程和工具使用，对"如何完成任务"保有控制权。

区分的轴线是控制流归谁：归代码，还是归模型。后者的实现就是 [[agent-loop|agent loop]]。

> 时效性：该文页面顶部有 Anthropic 后加的说明，称工具生态自 2024-12 以来变化很大；导出文本里的框架列表和模型名在首发之后被修订过，无法判断哪些段落是原文（[[2026-11-20-anthropic-building-effective-agents]]）。

## 要解决的问题和动机

- "agent" 一词被用来指很不相同的东西，这套词汇给出一个可操作的分界（[[2026-11-20-anthropic-building-effective-agents]]）。
- 核心建议是**先找最简单的方案**：agentic 系统通常是用延迟和成本换任务表现，很多应用只要把单次 LLM 调用配上检索和 in-context 示例优化好就够了（[[2026-11-20-anthropic-building-effective-agents]]）。
- 文章开头的论点是最成功的实现用的是简单、可组合的模式而不是复杂框架。这是基于"与数十个团队合作"的经验性主张，全文没有对照实验（[[2026-11-20-anthropic-building-effective-agents]]）。

## 工作原理

### 基本构件：augmented LLM

所有模式的基本单元是带三种增强的 LLM：检索、工具、记忆。模型能自己生成检索 query、选工具、决定保留什么信息。实现上强调两点：增强能力要贴合具体用例；给模型的接口要简单且文档完善。[[mcp|MCP]] 被作为接入第三方工具的一种方式提到。记忆虽被列为三项增强之一，全文没有展开（[[2026-11-20-anthropic-building-effective-agents]]）。

### 五种 workflow 模式

| 模式 | 机制 | 作者给出的适用条件 |
|---|---|---|
| Prompt chaining | 任务拆成顺序步骤，后一次调用处理前一次输出；中间可加程序化检查（gate） | 任务能干净地拆成固定子任务；用延迟换准确率 |
| Routing | 先分类输入，再导向专门的后续流程 | 类别分明且分类能做准；也用于按难度分流到大小模型 |
| Parallelization | 多次调用并行、程序化聚合；两种变体：sectioning（拆成独立子任务）和 voting（同一任务跑多次） | 子任务可并行提速，或需要多视角提高置信度；例：guardrail 与主回答分开调用 |
| Orchestrator-workers | 中心 LLM 动态拆任务、委派给 worker LLM、再综合结果 | 无法预知子任务（如改哪些文件） |
| Evaluator-optimizer | 一个调用生成，另一个调用评估并反馈，循环 | 评估标准清晰且迭代有可度量价值 |

（[[2026-11-20-anthropic-building-effective-agents]]）

Orchestrator-workers 与 parallelization 拓扑相似，区别在于子任务不是预定义的（[[2026-11-20-anthropic-building-effective-agents]]）。它可以看作后来 [[subagents|subagent]] 委派的早期表述，但这是来源页的推断，原文没有用 subagent 一词。

### 自主 agent

从人的指令或交互式讨论开始，任务清楚后独立规划和执行，必要时回头找人；每一步从环境拿 ground truth 评估进展；可以在 checkpoint 或遇阻时暂停；通常任务完成即终止，常见做法是加最大迭代次数之类的停止条件（[[2026-11-20-anthropic-building-effective-agents]]）。

### 何时用哪种

| 情形 | 选择 |
|---|---|
| 单次调用加检索和示例就能解决 | 不要上 agentic 系统 |
| 任务定义清晰，要可预测性和一致性 | workflow |
| 步数难以预测、无法硬编码路径，且对模型决策有一定信任 | agent |

（[[2026-11-20-anthropic-building-effective-agents]]）

- agent 的代价是成本更高、错误会累积；建议在[[sandboxing|沙箱]]环境中大量测试并配合 guardrails（[[2026-11-20-anthropic-building-effective-agents]]）。
- 适合 agent 的任务特征（作者归纳）：既要对话又要行动、成功标准清晰、能形成反馈回路、有实质性的人工监督。编码符合这些条件，因为方案可由自动化测试验证（[[2026-11-20-anthropic-building-effective-agents]]）。见 [[verification-and-observability]]。

## 变体与演进

### agent 外面再套一层固定结构

区分并不互斥。多份资料描述的是"节点内由模型自主、节点之间由代码或人固定"的混合形态：

- **图式 workflow 里放 agent**：AI Harness Crash Course 用 Google ADK 的 graph workflow 举例，节点可以是 agent 也可以是普通函数。coding agent 改代码后，单元测试和浏览器测试并行；任一失败把反馈送回 coding agent，都通过才进入 review；可设 retry limit，反复修不好就停下求助。对 ADK 的描述是讲者口头介绍，未注明版本（[[2026-11-20-ai-harness-crash-course]]）。
- **有界的外层循环**：[[microsoft-agent-framework|Microsoft Agent Framework]] 的 looping 由 evaluator 或谓词驱动，有界地重新调用 agent（可选能力）（[[2026-11-20-microsoft-learn-agent-harness]]）。这与 evaluator-optimizer 模式形状相同（笔者的对应，原文未作此类比）。
- **固定的会话序列**：Go 练习仓库的 `Drive` 每轮开一个全新上下文的会话，按清单状态选 initializer 或 coding 提示词，会话后用代码校验清单（[[2026-11-20-harness-engineering-go-practice]]）。见 [[long-running-agents]]。
- **课程里的进阶方向**：[[learn-claude-code]] README 的 s16 Workflow Runtime 主张"编排形状固定时就写进代码"（[[2026-11-20-learn-claude-code-readme]]）；[[learn-harness-engineering|Learn Harness Engineering]] 的 L13、L14 标题是"从手动驱动到自动循环"和"从单循环到图工程"（仅标题，正文未摄入）（[[2026-11-20-learn-harness-engineering-course]]）。

### Explore → Plan → Code → Commit：人机协作的节奏

[[claude-code|Claude Code]] 官方课程推荐的四步，开篇称这是整门课"最该带走的一件事"（厂商自述）（[[2026-11-20-explore-plan-code-commit-workflow]]）：

| 步骤 | 作用 |
|---|---|
| Explore | 为 Claude 提供项目的相关 context；可在 plan mode 下只读调研 |
| Plan | 产出行动计划，Claude 用它判断自己是否成功；人在此审阅和纠偏 |
| Code | 人与 Claude 来回，直到确定计划的最终结果 |
| Commit | 审查并 push；提交前跑一个 subagent code reviewer |

- 核心主张：不要一上来就让 Claude 写代码，否则之后要更多纠偏；计划阶段是最佳纠偏点，因为还没有写任何代码（作者主张，无数据）（[[2026-11-20-explore-plan-code-commit-workflow]]）。
- 课程大纲把 code review 定位为"自己过目加一个 fresh-context reviewer"（[[2026-11-20-claude-code-101-course]]）；一个计划做完、开始新功能时应 `/clear`（[[2026-11-20-context-management-in-claude-code]]）。
- 把它归为 workflow 是来源页的推断：它是由**人**驱动的固定步骤，套在 agent 自主循环之外，资料本身没有用 workflow/agent 这对术语（[[2026-11-20-explore-plan-code-commit-workflow]]）。计划环节的机制见 [[planning-and-plan-mode]]。

## 优缺点和权衡

- workflow：可预测、一致、易测试；但路径写死，遇到没预料的输入就失效。prompt chaining 是用延迟换准确率（[[2026-11-20-anthropic-building-effective-agents]]）。
- agent：灵活；但成本高、错误累积，且必须对模型的决策有一定信任（[[2026-11-20-anthropic-building-effective-agents]]）。
- 框架让起步容易，但额外的抽象层会遮住底层 prompt 和响应，也诱使人加不必要的复杂度；作者称"对底层的错误假设是客户出错的常见来源"（经验性主张）（[[2026-11-20-anthropic-building-effective-agents]]）。

## 不同来源的分歧

> [!warning] 矛盾
> **图式编排算不算正路。**
> - learn-claude-code README 的宣言：把"用 if-else、节点图、prompt chain 把 LLM API 串起来"当成构建 agent 是误解；拖拽式工作流和 prompt chain 库被称为 "Rube Goldberg machines"。agency 来自模型训练，不来自外部代码编排（作者立场，修辞色彩明显，无实验支撑）（[[2026-11-20-learn-claude-code-readme]]）。
> - Anthropic：两类都是正当的 agentic systems，按任务特征选择，并且建议从最简单的开始（[[2026-11-20-anthropic-building-effective-agents]]）。
> - AI Harness Crash Course：把固定顺序、并行和 retry limit 的 graph workflow 当作 harness 设计的常规组成部分（[[2026-11-20-ai-harness-crash-course]]）。
> - Learn Harness Engineering：L14 把"图工程"当作进阶方向（仅标题）（[[2026-11-20-learn-harness-engineering-course]]）。
>
> learn-claude-code 自身也有张力：同一份 README 的 s16 主张固定形状的编排写进代码。两者可以调和（形状固定的部分交给代码、节点内由模型自主），但 README 没有说明边界在哪（[[2026-11-20-learn-claude-code-readme]]）。

- **对框架的态度**：Anthropic 建议先直接用 LLM API、减少抽象层（[[2026-11-20-anthropic-building-effective-agents]]）；Microsoft 提供默认开启十来项能力的 batteries-included Harness（[[2026-11-20-microsoft-learn-agent-harness]]）。两者出发点相反但未必矛盾：Anthropic 也说框架可用于起步。
- **工作流该由谁定**：[[pi|Pi]] 的主张是"让 Pi 适应你的工作流，而不是反过来"，因此不内置 plan mode 和 sub-agents（[[2026-11-20-pi-readme]]）；Claude Code 课程则推荐一套固定的四步节奏（[[2026-11-20-explore-plan-code-commit-workflow]]）。
- **多 agent 的审查回路**：[[openai|OpenAI]] 团队让 [[codex|Codex]] 自审、请其他 agent 审查、回应反馈，循环到所有 agent reviewer 满意（[[2026-11-20-openai-harness-engineering]]）。这在形状上接近 evaluator-optimizer（笔者的对应，原文未用该术语）。

## 采用它的项目

- 词汇表的出处是 [[anthropic|Anthropic]]（[[2026-11-20-anthropic-building-effective-agents]]）。
- agent 形态：[[claude-code|Claude Code]]（learn-claude-code README 称赞它"不强加固定工作流"，作者评价）（[[2026-11-20-learn-claude-code-readme]]）。
- 图式或固定编排：Google ADK 的 graph workflow（[[2026-11-20-ai-harness-crash-course]]）、[[microsoft-agent-framework|Microsoft Agent Framework]] 的 looping（[[2026-11-20-microsoft-learn-agent-harness]]）、[[learn-claude-code]] 的 s16（[[2026-11-20-learn-claude-code-readme]]）。

## 相关概念

[[agent-loop]]、[[agent-harness]]、[[planning-and-plan-mode]]、[[subagents]]、[[tools]]、[[mcp]]、[[memory]]、[[verification-and-observability]]、[[long-running-agents]]、[[harness-engineering]]
