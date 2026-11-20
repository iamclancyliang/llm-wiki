---
title: Building effective agents（Anthropic）
type: source
kind: article
aliases: [Building effective AI agents, 构建有效的 agent]
tags: [agent, workflow, tool-design, anthropic]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/anthropic-building-effective-agents.md
author: Erik S., Barry Zhang（Anthropic）
published: 2024-12-19
url: https://www.anthropic.com/research/building-effective-agents
---

# Building effective agents（Anthropic）

## 一段话概括

[[anthropic|Anthropic]] 工程团队在 2024-12-19 发表的经验总结，基于"过去一年与数十个团队合作构建 LLM agent"的观察。核心论点：最成功的实现用的不是复杂框架，而是**简单、可组合的模式**。文章给出了一套后来被广泛引用的词汇表——把 agentic systems 分成 workflows（预定义代码路径编排）和 agents（模型自己主导流程），即 [[workflows-vs-agents|workflows 与 agents 的区分]]——列出五种 workflow 模式和一种自主 agent 形态，并用一个附录专门讲工具接口（agent-computer interface，ACI）的设计。全文没有出现 "harness" 一词，但它对 agent 的定义（"LLM 在循环中根据环境反馈使用工具"）正是后来 [[agent-harness|agent harness]] 讨论的起点。

> 时效性提示：页面顶部有 Anthropic 后加的说明，称文中描述的工具生态自 2024-12 以来已变化很多，当前做法见 Claude Managed Agents。导出的文本里框架列表、模型名（Claude Haiku 4.5 / Sonnet 4.5）显然在首发之后被修订过，所以本页内容是"2024-12 的论点 + 之后的局部更新"，引用具体产品名时要留意。

## 要点

### 定义与取舍

- **Workflows**：LLM 和工具通过**预定义的代码路径**编排。**Agents**：LLM **动态主导**自己的流程和工具使用，对"如何完成任务"保有控制权。两者统称 agentic systems。
- **先找最简单的方案**：agentic 系统通常是用延迟和成本换任务表现，很多应用只需把单次 LLM 调用配上检索和 in-context 示例优化好就够了。需要复杂度时：任务定义清晰、要可预测性和一致性选 workflow；需要灵活性和模型驱动的决策选 agent。
- **对框架的态度**：框架让起步容易（封装 LLM 调用、工具定义与解析、调用串联），但额外的抽象层会遮住底层 prompt 和响应，更难调试，也诱使人加不必要的复杂度。建议先直接用 LLM API（"很多模式几行代码就能实现"）；用框架就要读懂底层代码——作者称"对底层的错误假设是客户出错的常见来源"。

### 基本构件：augmented LLM

- 所有模式的基本单元是带检索、[[tools|工具]]、记忆三种增强的 LLM；模型能自己生成检索 query、选工具、决定保留什么信息。
- 实现上强调两点：增强能力要贴合具体用例；给模型的接口要简单且文档完善。[[mcp|Model Context Protocol（MCP）]] 被作为接入第三方工具生态的一种方式提到。

### 五种 workflow 模式

| 模式 | 机制 | 适用条件（作者给出的） |
|---|---|---|
| Prompt chaining | 任务拆成顺序步骤，后一次调用处理前一次输出；中间可加程序化检查（gate） | 任务能干净地拆成固定子任务；用延迟换准确率，让每次调用更容易 |
| Routing | 先分类输入，再导向专门的后续流程 | 类别分明、分类能做准；否则为一类输入优化会损害另一类。也用于按难度分流到大小模型 |
| Parallelization | 多次调用并行、程序化聚合；两种变体：sectioning（拆成独立子任务）和 voting（同一任务跑多次） | 子任务可并行提速，或需要多视角/多次尝试提高置信度；例：guardrail 与主回答分开调用 |
| Orchestrator-workers | 中心 LLM 动态拆任务、委派给 worker LLM、再综合结果 | 无法预知子任务（如改哪些文件）；与 parallelization 拓扑相似，区别在子任务不是预定义的 |
| Evaluator-optimizer | 一个调用生成，另一个调用评估并反馈，循环 | 评估标准清晰且迭代有可度量价值；判据：人给反馈时输出能明显变好，且 LLM 自己能给出这种反馈 |

Orchestrator-workers 是后来 [[subagents|subagent]] 委派模式的早期表述（此为笔者推断，原文未用 subagent 一词）。

### 自主 agent

- 运行方式：从人的指令或交互式讨论开始；任务清楚后独立规划和执行，必要时回头找人要信息或判断。
- **每一步都要从环境拿到 "ground truth"**（工具调用结果、代码执行结果）来评估进展；可以在 checkpoint 或遇阻时暂停等人反馈；通常任务完成即终止，但常见做法是加停止条件（如最大迭代次数）以保持控制。
- 作者的一句定性：agent "通常只是在循环中根据环境反馈使用工具的 LLM"，实现往往很直白——这就是 [[agent-loop|agent loop]]。因此工具集及其文档的设计才是关键。
- 适用：步数难以预测、无法硬编码路径的开放式问题，且必须对模型决策有一定信任。代价：成本更高、错误会累积（compounding errors）。建议在沙箱环境中大量测试，并配合适当的 guardrails。

### 三条原则（Summary）

1. 保持设计 **simplicity**。
2. 优先 **transparency**：显式展示 agent 的规划步骤。
3. 通过充分的工具文档和测试精心打造 **ACI**。

### 附录 2：工具即 prompt

- 工具定义应得到与整体 prompt 同等的 prompt engineering 投入。同一动作的不同表达方式对软件是等价的，对 LLM 的书写难度却差别很大：写 diff 需要在写新代码之前就知道 chunk header 里的行数；在 JSON 里写代码比在 markdown 里多出换行和引号转义。
- 选格式的三条建议：给模型足够 token 先"思考"，避免把自己写进死角；格式贴近模型在互联网文本中自然见过的样子；消除格式"开销"（如精确计数几千行代码、对代码做字符串转义）。
- ACI 的做法：站在模型角度看工具描述是否一眼可用；好的工具定义包含示例用法、边界情况、输入格式要求、与其他工具的界限；像给团队里的 junior developer 写 docstring 那样改参数名和描述；在 workbench 里跑大量样例看模型怎么犯错再迭代；用 poka-yoke（防呆）改参数，让错误更难发生。

## 值得记下的数据和论据

- **绝对路径案例**（有具体实践支撑）：在做 SWE-bench agent 时，团队花在优化工具上的时间多于整体 prompt。发现 agent 离开根目录后，使用相对路径的工具会出错；改成工具**始终要求绝对路径**后，作者称模型"用得毫无差错"。未给出量化数字。
- **SWE-bench Verified**：Anthropic 自述其实现能仅凭 pull request 描述解决该基准中的真实 GitHub issue；本文未给出通过率、模型版本或配置，数字需到其链接的 swe-bench-sonnet 文章查。
- **客服场景的商业信号**：若干公司采用"只对成功解决收费"的按量定价，作者以此作为 agent 有效性的旁证（未点名公司，无数据）。
- 全文**没有任何对照实验或量化评估**；各模式的"何时使用"是经验性判断。

## 作者主张与有证据支撑的结论

- **作者主张（经验性，无公开数据）**：最成功的实现都用简单可组合模式而非复杂框架；框架的抽象是常见出错来源；guardrail 与主回答分开调用通常优于同一调用兼顾；多考虑因素的复杂任务让每个因素由单独调用处理效果更好。
- **有具体实践支撑**：SWE-bench agent 的工具优化与绝对路径修复；SWE-bench 和 computer use 参考实现作为 agent 形态的两个实例。
- **适合 agent 的任务特征**（附录 1，作者归纳）：既要对话又要行动、成功标准清晰、能形成反馈回路、有实质性的人工监督。编码之所以适合：方案可由自动化测试验证、可用测试结果迭代、问题空间结构化、质量可客观度量——这也是 [[verification-and-observability|验证与可观测性]] 在 coding agent 中居于核心的理由。作者同时强调自动化测试只验证功能，人工 review 对"方案是否符合更大的系统需求"仍然关键。

## 与同批资料的关系

- **补充**：同批的 Anthropic《Effective harnesses for long-running agents》（2025-11-26）可看作本文 agent 形态在"跨多个 context window"条件下的续篇；本文的 "ground truth from the environment" 在那里具体化为浏览器端到端测试，"停止条件"在那里对应"过早宣布完成"的失败模式。
- **补充**：OpenAI 的 harness engineering 文章把本文的"精心设计 ACI"从工具层扩大到整个代码仓库（文档、linter 错误信息、可观测性栈都为 agent 可读性设计）。
- **潜在分歧**：本文劝人少用框架、直接用 API、减少抽象层；同批的 Microsoft Agent Framework Harness 文档则提供 batteries-included、默认开启大量能力的 harness。两者未必矛盾（本文也说框架可用于起步，并在更新后的列表里列出 Claude Agent SDK），但出发点相反，值得在概念页里并列。

## 涉及的实体和概念

[[anthropic]]、[[workflows-vs-agents]]、[[agent-loop]]、[[tools]]、[[mcp]]、[[subagents]]、[[verification-and-observability]]、[[agent-harness]]

## 局限与遗留问题

- 发表于 2024-12，早于 "harness" 成为通用说法；没有讨论 [[context-management|上下文管理]]、会话持久化、权限模型、长时运行等后来的核心议题。
- "simple, composable patterns" 的优越性只有经验陈述，没有对比数据；什么时候复杂度"确实改善了结果"由读者自行度量。
- 记忆（memory）被列为 augmented LLM 的三项增强之一，但全文没有展开。
- 文中未说明"透明地展示规划步骤"具体如何实现、对用户信任的影响有多大。
- 导出文本经过后期修订，无法从本资料判断哪些段落是 2024-12 原文、哪些是之后更新的。
