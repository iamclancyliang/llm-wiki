---
title: Harness engineering
type: concept
aliases: [harness 工程, 环境工程, agent-first engineering]
tags: [harness-engineering, agent-harness, agent-legibility, verification]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-microsoft-learn-agent-harness
---

# Harness engineering

## 定义

Harness engineering 是一门实践：不去改模型，而是为 agent 设计它工作的环境、约束和反馈回路，让同一个模型的执行变得可靠。[[openai|OpenAI]] 的说法是，工程师不再写代码之后，工作变成"设计环境、明确意图、构建反馈回路"，口号是"人类掌舵，智能体执行"（[[2026-11-20-openai-harness-engineering]]）。[[learn-harness-engineering|Learn Harness Engineering]] 课程的说法是"Harness 的本质不是让模型变聪明，而是给模型建立一套闭环的工作系统"（[[2026-11-20-learn-harness-engineering-course]]）。

这个词也有另一种用法：[[learn-claude-code]] 的 README 把 harness engineering 说成给模型造"车"（模型是"司机"），指的是编写运行时本身，即 [[agent-harness]] 的第一层含义（[[2026-11-20-learn-claude-code-readme]]）。本页讲仓库与流程层面的做法；运行时机制见 [[agent-harness]] 和 [[agent-loop]]。

> 术语提示：OpenAI 文章的中文官方译文把标题译成"工程技术"，正文没有直接出现 harness，只在结尾说"纪律更多体现在支撑结构上，而不是代码上"。"harness engineering" 是来源页按英文 URL slug 还原的（[[2026-11-20-openai-harness-engineering]]）。

## 要解决的问题和动机

- **瓶颈是环境而不是模型**。OpenAI 团队早期进展比预期慢，作者归因于环境规范不足：agent 缺少完成高层目标所需的工具、抽象和内部结构。出问题时问的是"缺什么能力，怎样让它对 agent 既清晰可读又可强制执行"（[[2026-11-20-openai-harness-engineering]]）。
- **agent 没有跨会话的记忆**。每个新 session 开始时对之前发生的事一无所知，而复杂项目无法在一个 context window 内完成（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **典型失败模式**。[[anthropic|Anthropic]] 在内部实验里观察到三种：试图一次做完导致半成品、项目后期过早宣布完成、未充分测试就把 feature 标为完成（定性观察，无对照数据）（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。课程把同类问题归为五项：越界、丢上下文、提前宣告完成、不自我验证、过程黑箱（[[2026-11-20-learn-harness-engineering-course]]）。
- **熵增**。agent 会复制仓库里已有的模式，包括不好的，时间一长必然漂移（[[2026-11-20-openai-harness-engineering]]）。

## 工作原理

### 仓库即记录系统与 agent 可读性

- 原则：从 agent 角度看，运行时上下文里访问不到的东西等于不存在。Google Docs、聊天记录、人脑里的知识都不可见，只有仓库内版本化的工件（代码、Markdown、schema、可执行计划）可见（[[2026-11-20-openai-harness-engineering]]）。课程 L03 的标题是"让代码仓库成为唯一的事实来源"（仅标题，正文未摄入）（[[2026-11-20-learn-harness-engineering-course]]）。
- 可读性延伸到运行中的应用：OpenAI 团队让应用按 git worktree 启动，接入 Chrome DevTools Protocol，并给每个 worktree 配一套用完即毁的本地可观测性栈，agent 用 LogQL、PromQL 查日志和指标。作者称这样"服务启动在 800ms 内完成"之类的 prompt 才可执行（团队自述）（[[2026-11-20-openai-harness-engineering]]）。
- 技术选型也受影响：偏好能在仓库内被完全理解的依赖，"无聊"的技术更容易被模型建模（作者判断，无对照实验）（[[2026-11-20-openai-harness-engineering]]）。

### 渐进式披露

"给 Codex 一张地图，而不是一本 1000 页的说明书"：`AGENTS.md` 约 100 行，只作目录，指向结构化的 `docs/` 和 `ARCHITECTURE.md`；agent 从一个小而稳定的入口开始，被告知下一步去哪看（[[2026-11-20-openai-harness-engineering]]）。详见 [[context-files]]。[[skills]] 的"先列目录、用到再读"是同一思路在运行时一侧的对应物（[[2026-11-20-harness-engineering-go-practice]]）。

### 把状态和计划落到仓库里

- Anthropic 的做法：第一个 session 由 initializer agent 搭环境（JSON feature list、`init.sh`、进度文件、初始 git commit），之后每个 session 的 coding agent 只做一个 feature、测试、提交 git、更新进度文件。两者只是初始 user prompt 不同，system prompt、工具集和 harness 完全相同（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- OpenAI 的做法：复杂工作写 execution plan，附进度和决策日志并提交进仓库；活跃计划、已完成计划、技术债清单都版本化（[[2026-11-20-openai-harness-engineering]]）。见 [[planning-and-plan-mode]]。
- 课程把这套东西画成闭环：`AGENTS.md` → `init.sh` → 运行与反馈 → 测试与 QA → 进度文件交接（箭头走向是来源页根据边标签重建的）（[[2026-11-20-learn-harness-engineering-course]]）。更多见 [[long-running-agents]]。

### 机械强制不变量

- 单靠文档无法让全 agent 生成的代码库保持连贯。OpenAI 团队强制的是不变量而不是实现：例如要求在边界处解析数据形状，但不规定用哪个库；每个业务域内代码只能沿 Types → Config → Repo → Service → Runtime → UI 向前依赖，由自定义 linter 和结构测试执行（[[2026-11-20-openai-harness-engineering]]）。
- lint 的错误信息里直接写修复指引，等于在出错的那一刻把指令注入 agent 上下文（[[2026-11-20-openai-harness-engineering]]）。
- "文档不够时，把规则变成代码"（[[2026-11-20-openai-harness-engineering]]）。同一论点在其他资料里反复出现：[[hooks]] 一课的结语是"必须每次都发生的事，不要放进 prompt，放进 hook"（[[2026-11-20-hooks-in-claude-code]]）；Crash Course 说控制必须由软件强制执行，光叮嘱模型小心不够（[[2026-11-20-ai-harness-crash-course]]）；Go 练习仓库的注释是"提示词是请求，模型可能不照做；代码是规则，模型绕不过去"（[[2026-11-20-harness-engineering-go-practice]]）。

### 反馈回路：让 agent 亲眼看到结果

- 明确要求用浏览器自动化、像人类用户那样测试之后，端到端验证"大体做得不错"；没有这个要求时，agent 会用单元测试或 `curl`，却意识不到 feature 端到端并不能用（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- 完成由工件判定而不由模型的一句话判定：feature list 的 `passes` 字段、测试结果（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]、[[2026-11-20-harness-engineering-go-practice]]）。人机协作一侧的对应做法是在计划里写明什么算正确，并给 agent 能自我验证的工具（[[2026-11-20-explore-plan-code-commit-workflow]]）。见 [[verification-and-observability]]。

### 后台"垃圾回收" agent

OpenAI 团队最初靠人每周五（一周的 20%）清理"AI 残渣"，不可扩展。改为把"黄金原则"编码进仓库，定期运行后台 [[codex|Codex]] 任务扫描偏差、更新质量评分、发起定向重构 PR；另有 doc-gardening agent 扫描与真实代码行为不符的过时文档并开修复 PR。作者称多数自动重构 PR 可在一分钟内 review 完（团队自述）（[[2026-11-20-openai-harness-engineering]]）。

## 变体与演进

- **软约束到硬约束**。Anthropic 用强措辞的 prompt 约束 coding agent 只改 `passes` 字段（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；Go 练习仓库把同一条规则写成 `CheckEdit`，会话后校验清单，不合规就用会话前的版本覆盖回去（[[2026-11-20-harness-engineering-go-practice]]）。
- **从手动到自动**。课程的 L13、L14 标题是"从手动驱动到自动循环"和"从单循环到图工程"（仅标题，正文未摄入）（[[2026-11-20-learn-harness-engineering-course]]）。OpenAI 团队报告的端到端流程是一个 prompt 驱动复现 bug、修复、验证、开 PR、回应反馈直到合并，作者强调这高度依赖该仓库的特定结构，不应假定可泛化（[[2026-11-20-openai-harness-engineering]]）。
- **状态放在环境里还是 harness 里**。与上述"落盘到仓库"相对，[[microsoft-agent-framework|Microsoft Agent Framework]] 把 todo、文件记忆、模式做成 harness 内建的 provider（[[2026-11-20-microsoft-learn-agent-harness]]）。

## 优缺点和权衡

- 证据强度有限。OpenAI 的数字（五个月、约 100 万行、约 1,500 个 PR、起初 3 名工程师每人每天 3.5 个 PR、约 1/10 的时间）全部是团队自述，产品和仓库未公开；1/10 是估计值，没有说明估算方法（[[2026-11-20-openai-harness-engineering]]）。Anthropic 的文章没有"有无 initializer"的量化对比，作者自己的定位是 "one possible set of solutions"（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- 前期投入大。OpenAI 作者说严格分层架构通常到几百名工程师时才会引入，但对 coding agent 是早期前提（作者判断）（[[2026-11-20-openai-harness-engineering]]）。
- 适用面未知。两篇一手文章都是 greenfield 项目；Anthropic 的 demo 只针对全栈 web app（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]、[[2026-11-20-openai-harness-engineering]]）。

## 不同来源的分歧

> [!warning] 矛盾
> **质量门该多严。** OpenAI 主张减少阻塞性合并门，flaky test 靠重跑解决，理由是 agent 吞吐远超人类注意力时"纠错成本低，等待成本高"；作者明说在低吞吐环境里这样做是不负责任的（[[2026-11-20-openai-harness-engineering]]）。Anthropic 要求每个 session 把环境留在可合并到 main 的干净状态，仔细测试后才把 feature 标为通过（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。两者场景不同（多 agent 高吞吐加持续垃圾回收，对单 agent 串行），未必是直接矛盾，但态度相反。

- **工作对象**：learn-claude-code 说的 harness engineering 是写运行时，并把收集部署轨迹用于训练下一代模型也算作职责（作者主张）（[[2026-11-20-learn-claude-code-readme]]）；课程和 OpenAI 说的是在现成 agent 之外搭仓库环境（[[2026-11-20-learn-harness-engineering-course]]、[[2026-11-20-openai-harness-engineering]]）。
- **接口设计的范围**：Anthropic《Building effective agents》把 agent-computer interface 限定在工具定义层（[[2026-11-20-anthropic-building-effective-agents]]）；OpenAI 把"为 agent 设计接口"扩大到整个仓库、文档体系、lint 错误信息和可观测性栈（[[2026-11-20-openai-harness-engineering]]）。
- **agent 审 agent**：OpenAI 团队的审核已几乎全部是 agent 对 agent，人的 review 不是必须（[[2026-11-20-openai-harness-engineering]]）；Anthropic 认为专门的测试或 QA agent"似乎有理由"做得更好，但列为未验证的 future work（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

## 采用它的项目

- OpenAI 的内部 beta 产品团队，使用 [[codex|Codex]]（[[2026-11-20-openai-harness-engineering]]）。
- Anthropic 用 [[claude-agent-sdk|Claude Agent SDK]] 加 Opus 4.5 构建 claude.ai 克隆的实验（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- [[learn-harness-engineering]] 课程的模板库（`AGENTS.md`、`feature_list.json` 等）（[[2026-11-20-learn-harness-engineering-course]]）；Go 练习仓库的 `longrun` 包（[[2026-11-20-harness-engineering-go-practice]]）。
- [[deepseek-harness|DeepSeek Harness]] 仓库自身用 `AGENTS.md`、ADR 和 review skill 约束 agent 开发；这是来源页从文件列表和 commit 信息得到的推断（[[2026-11-20-deepseek-harness-readme]]）。

## 相关概念

[[agent-harness]]、[[context-files]]、[[planning-and-plan-mode]]、[[long-running-agents]]、[[verification-and-observability]]、[[hooks]]、[[skills]]、[[context-management]]、[[workflows-vs-agents]]、[[tools]]、[[subagents]]
