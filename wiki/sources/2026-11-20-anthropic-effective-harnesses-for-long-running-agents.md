---
title: Effective harnesses for long-running agents（Anthropic）
type: source
kind: article
aliases: [长时运行 agent 的有效 harness, initializer agent + coding agent]
tags: [agent-harness, long-running-agents, context-window, anthropic]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/anthropic-effective-harnesses-for-long-running-agents.md
author: Justin Young（Anthropic）
published: 2025-11-26
url: https://www.anthropic.com/research/effective-harnesses-for-long-running-agents
---

# Effective harnesses for long-running agents（Anthropic）

## 一段话概括

[[anthropic|Anthropic]] 2025-11-26 的工程文章，讨论 [[long-running-agents|long-running agent（长时运行 agent）]] 的核心难题：agent 只能在离散的 session 里工作，每个新 session 开始时对之前发生的事**没有记忆**，而复杂项目无法在一个 context window 内完成。作者的回答不是改模型或改 harness 代码，而是**改环境和 prompt**：第一个 session 用专门的 prompt 让 "initializer agent" 搭好环境（feature list、`init.sh`、进度文件、初始 git commit），之后每个 session 的 "coding agent" 只做一个 feature、做完测试、提交 git、更新进度文件，把环境留在"可合并到 main 分支"的干净状态。实验对象是用 Claude Agent SDK + Opus 4.5 从一句高层 prompt 构建 claude.ai 克隆。

## 要点

### 问题：compaction 不够

- 文中把 Claude Agent SDK 称为"通用的 [[agent-harness|agent harness]]"，自带 [[context-management|上下文管理]] 能力如 [[compaction|compaction（压缩）]]。理论上这足以让 agent 无限期工作。
- 实际观察：即便是 Opus 4.5，在 SDK 上跨多个 context window 循环运行，只给 "build a clone of claude.ai" 这样的高层 prompt，也做不出生产质量的 web app。两种失败模式：
  1. **一次做太多（试图 one-shot）**：实现到一半 context 用尽，下一个 session 面对一个半成品且无文档的 feature，只能猜发生了什么，花大量时间把基本功能重新跑起来。作者指出即使有 compaction 也会发生，因为 compaction "并不总是把足够清晰的指示传给下一个 agent"。
  2. **过早宣布完成**：项目后期，新的 agent 实例看到已有不少进展，就判定任务完成。

### 解法：两种 prompt，同一个 harness

- **Initializer agent**（仅第一个 session）：搭建初始环境——`init.sh` 脚本、`claude-progress.txt`（记录各 agent 做了什么的日志）、展示新增文件的初始 git commit，以及 feature list。
- **Coding agent**（之后每个 session）：做增量进展，然后留下结构化的更新。
- 脚注澄清：两者被称为不同的 "agent" 只是因为**初始 user prompt 不同**；[[system-prompt|system prompt]]、工具集和整体 harness 完全相同。
- 作者称关键洞察是：让 agent 在全新 context window 开始时能**快速理解工作状态**，靠的是进度文件加 git 历史；做法的灵感来自"高效软件工程师每天做的事"（文中的类比：轮班工程师，每班新来的人都不记得上一班发生了什么）。

### 环境里的四个工件

1. **Feature list（JSON）**：initializer 把用户 prompt 展开成完整的 feature 需求文件。每条含 `category`、`description`、`steps`（端到端验证步骤）和 `passes` 字段，初始全部为 `false`，让后续 agent 看得到"完整功能"长什么样。coding agent 只允许改 `passes` 字段；prompt 里用了强措辞（"删除或修改测试是不可接受的，因为这可能导致功能缺失或有 bug"）。
2. **增量进展 + git**：每次只做一个 feature。保持干净状态的最有效做法是要求模型用描述性 commit message 提交 git，并在进度文件里写小结。git 同时充当 [[error-recovery|错误恢复]] 手段：可以 revert 坏的改动、回到可工作状态。
3. **端到端测试**：见下节。
4. **`init.sh`**：能启动 dev server 的脚本，省去每个 session 摸索"怎么跑这个应用"。

```json
{
  "category": "functional",
  "description": "New chat button creates a fresh conversation",
  "steps": ["Navigate to main interface", "Click the 'New Chat' button", "..."],
  "passes": false
}
```
（出处：原文 feature list 示例，steps 有删节）

### 测试：必须像人类用户那样验证

- 第三种失败模式：Claude 倾向于未充分测试就把 feature 标为完成。没有明确提示时，它会改代码，甚至用单元测试或 `curl` 打 dev server，但**意识不到 feature 端到端并不能用**。
- 明确要求使用浏览器自动化工具、像人类用户一样测试之后，端到端验证"大体做得不错"。实验中用的是 Puppeteer [[mcp|MCP]] server，agent 在测试时自己截图。这属于 [[verification-and-observability|验证与可观测性]] 一类的 harness 能力：给 agent 能看到真实运行结果的 [[tools|工具]]。

### 每个 session 的开场流程（"getting up to speed"）

coding agent 被提示依次做：

1. 运行 `pwd` 确认工作目录（只能编辑该目录下的文件）。
2. 读 git log 和进度文件，了解最近做了什么。
3. 读 feature list，选优先级最高的未完成 feature。
4. 用 `init.sh` 启动 dev server，**先跑一遍基础端到端测试**（在克隆例子里：新建对话、发消息、收到回复），再开始新 feature。

第 4 步的理由：如果上一个 session 留下了坏状态，先发现并修复；直接开始做新 feature 很可能让问题更糟。

### 失败模式与对策对照（原文表格）

| 问题 | Initializer 的做法 | Coding agent 的做法 |
|---|---|---|
| 过早宣布整个项目完成 | 根据输入 spec 建结构化 JSON feature list | session 开始读 feature list，选一个 feature 做 |
| 留下有 bug 或未记录进展的环境 | 建初始 git repo 和进度笔记文件 | 开始时读进度笔记和 git log、跑基础测试；结束时写 git commit 和进度更新 |
| 过早把 feature 标为完成 | 建 feature list | 自我验证所有 feature，仔细测试后才标 passing |
| 花时间摸索怎么运行应用 | 写能启动 dev server 的 `init.sh` | session 开始读 `init.sh` |

## 值得记下的数据和论据

- **实验设定**：模型 Opus 4.5；harness 为 Claude Agent SDK；任务为从高层 prompt 构建 claude.ai 克隆（全栈 web app）；跨多个 context window 循环运行。文章未报告 session 数、总时长、成本或最终通过的 feature 数。
- **Feature list 规模**：claude.ai 克隆例子中 initializer 生成了 **200 多条** feature。
- **JSON 优于 Markdown**（作者基于试验的观察，无数字）：模型不恰当地修改或覆盖 JSON 文件的可能性低于 Markdown 文件，所以 feature list 用 JSON。
- **测试工具的效果**：作者称提供浏览器自动化测试工具"显著提升了表现"（dramatically improved），因为 agent 能发现并修复仅从代码看不出的 bug。无量化数据。
- **已知盲区**：Claude 通过 Puppeteer MCP **看不到浏览器原生 alert modal**，依赖这类 modal 的 feature 因此 bug 更多。
- 开场流程的收益：每个 session 省一些 token（不必重新弄清如何测试代码）。未量化。

## 作者主张与有证据支撑的结论

- **有实验观察支撑（定性，内部实验）**：两种失败模式（one-shot、过早完成）和"未测试就标完成"的存在；feature list + 单 feature 增量 + git/进度文件 + 浏览器端到端测试这套组合能缓解它们；JSON 比 Markdown 更不易被乱改；alert modal 盲区。
- **作者主张 / 推测**：这些经验"很可能部分或全部"能推广到科研、金融建模等其他长时任务（原文措辞是 likely，未验证）；专门的测试 agent、QA agent、代码清理 agent"似乎有理由"做得更好（未验证）。
- **没有对照数据**：文章没有给出"有无 initializer""有无 feature list"的量化对比，结论的强度是"我们内部实验中有效的一组做法"。作者自己的定位也是 "one possible set of solutions"。

## 与同批资料的关系

- **印证**：OpenAI 的 harness engineering 文章同样把"仓库内、版本化的工件"当作 agent 跨 session 的记忆（exec plans 带进度和决策日志并提交进仓库），同样给 agent 接上浏览器（Chrome DevTools Protocol）来做 UI 级验证。两家独立得出"进度写进仓库 + 让 agent 亲眼看运行结果"的结论。
- **补充**：Anthropic 自己的《Building effective agents》（2024-12）说 agent 每步要从环境获得 ground truth 并设停止条件；本文把这两点落到了具体工件上（端到端测试、`passes` 字段）。
- **对比**：Microsoft Agent Framework 的 Harness 把 todo 追踪、文件记忆、compaction 做成 harness 内建的 provider；本文的做法是 harness 不变，把同类状态放进**工作目录里的普通文件**，靠 prompt 约定来维护。这是"状态放在 harness 里还是放在环境里"的两种取向。
- **粒度差异**：本文强调干净状态、一次一个 feature、测试通过才算完成；OpenAI 文章主张减少阻塞性合并门、flaky test 重跑了事（"纠错成本低、等待成本高"）。场景不同（单 agent 串行 vs 高吞吐多 agent 团队），不一定是直接矛盾，但对"质量门该多严"的态度不同。

## 涉及的实体和概念

[[anthropic]]、[[claude-code|Claude Code]]（致谢中提到 Claude Code 团队参与；Claude Agent SDK 是本文所用 harness）、[[long-running-agents]]、[[agent-harness]]、[[compaction]]、[[context-management]]、[[system-prompt]]、[[error-recovery]]、[[verification-and-observability]]、[[mcp]]、[[tools]]、[[subagents]]（仅在 future work 中作为多 agent 架构的设想出现）

进度文件 `claude-progress.txt` 与 [[session-log|session log]] 相关但不等同：它是 agent 自己写在工作目录里的摘要，而不是 harness 记录的会话历史（此区分为笔者推断）。

## 局限与遗留问题

- 作者列出的开放问题：单一通用 coding agent 与多 agent 架构哪个更好，尚不清楚；demo 只针对全栈 web app 优化，推广性未验证。
- 靠强措辞 prompt 约束"只改 `passes` 字段"是软约束；文章没说 agent 违反的频率，也没用 [[hooks|hooks]] 或权限机制做硬约束（后一句是笔者的观察，原文未讨论）。
- "优先级最高的未完成 feature"如何定义优先级，feature list 里没有对应字段，原文未说明。
- feature list 由 initializer 一次生成，后续如果需求变化或发现遗漏如何增补，未讨论。
- 示例 transcript 里 agent 提到的是 `tests.json`，而正文和工具调用里是 `feature_list.json`，文件名不一致，可能是示例拼接所致。
- 视觉能力和浏览器自动化工具的局限使部分 bug 无法被发现；除 alert modal 外没有给出其他类别。
- 配套代码在 anthropics/claude-quickstarts 的 autonomous-coding 目录，本批资料未收录，prompt 原文需另查。
