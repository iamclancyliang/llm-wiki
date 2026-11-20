---
title: System prompt（系统提示词）
type: concept
aliases: [系统提示词, system prompt 组装, instructions, harness instructions, prompt assembly]
tags: [system-prompt, agent-harness, context-management, prompt]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-openharness-readme
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-the-claude-md-file
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-pi-readme
---

# System prompt（系统提示词）

## 定义

System prompt 是每次模型调用时排在对话历史之前的那段指令。在 [[agent-harness|agent harness]] 里它不是一段手写的固定文本，而是 harness 在运行时**组装**出来的：[[learn-claude-code]] 网站的说法是"system prompt 是由策略、工具、skill 和上下文生成的产物"（只有课程标题和一句话摘要，正文未摄入）（[[2026-11-20-learn-claude-code-site]]）。

本批资料里专门讲 system prompt 的内容很少，没有任何一份给出某个产品 system prompt 的完整结构。本页能确认的主要是三份有代码或 API 依据的资料：Go 练习仓库的测试规格、[[microsoft-agent-framework|Microsoft Agent Framework]] 的两级指令、[[deepseek-harness|DeepSeek Harness]] loop 源码里的投影机制。

## 要解决的问题和动机

- 模型无状态，每次调用都要重新被告知它是谁、怎么操作、项目有什么规矩、手头有哪些能力。这些信息来源不同（harness 作者、应用开发者、项目仓库、用户个人配置、已安装的 skill），需要一个确定的拼装规则。
- 各部分之间会冲突，所以顺序本身是设计决策：谁在前、谁在后、谁"说了算"。
- system prompt 占用每一次调用的上下文，写多了会挤掉任务本身。[[openai|OpenAI]] 团队的教训是巨大的指令文件让 agent 要么漏掉关键约束，要么去优化错误的约束（[[2026-11-20-openai-harness-engineering]]）。

## 工作原理

### 组装顺序

Go 练习仓库的 `Build(base, contextFiles, skills)` 规格（截至 2026-11-20 的快照，函数体还是桩，规格来自注释和测试）（[[2026-11-20-harness-engineering-go-practice]]）：

1. 基础指令。
2. 每个 `AGENTS.md` 一段，带标题 `# 项目规则（来自 <路径>）`。文件由 `FindContextFiles` 从当前目录向上找到项目根为止，返回顺序从外到内，离当前目录越近的越靠后、越"说了算"。
3. [[skills|skill]] 清单：只放名字、描述和路径。测试断言 skill 正文不出现在提示词里，且两个 skill 的清单不超过 600 个字符；完整内容由模型需要时用 `read_file` 去读。

另一条规格：规则文件读不出来要报错，不能悄悄漏掉（[[2026-11-20-harness-engineering-go-practice]]）。

### 指令的层次

Microsoft 的 Harness 把指令分成两级（[[2026-11-20-microsoft-learn-agent-harness]]）：

| 层 | .NET | Python | 内容 |
|---|---|---|---|
| harness 级 | `HarnessInstructions`（默认值 `HarnessAgent.DefaultInstructions`） | `harness_instructions`（默认值 `DEFAULT_HARNESS_INSTRUCTIONS`） | 如何操作，例："Use tools deliberately and report verified results." |
| agent 级 | `ChatOptions.Instructions` | `agent_instructions` | 你是谁，例："You are a research assistant focused on academic sources." |

**harness 指令排在 agent 指令之前**。在此之上，context provider 还会追加会话级的指令、工具、记忆、todo 状态和运行模式（[[2026-11-20-microsoft-learn-agent-harness]]）。

把两份资料合起来看，层次大致是：harness 的通用操作指令 → 应用或 agent 的角色指令 → 项目规则（由外到内）→ 能力目录。两者的排序原则一致，都是从通用到具体。这是笔者对两份资料的归纳，没有哪一份资料给出这个完整序列；"越靠后越说了算"只是 Go 练习仓库的说法。

### 哪些内容进 system prompt，哪些不进

| 内容 | 是否进 system prompt | 依据 |
|---|---|---|
| 基础指令、角色、操作方式 | 进 | [[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-microsoft-learn-agent-harness]] |
| 项目规则（[[context-files\|context file]]） | Go 练习仓库：进。[[claude-code\|Claude Code]]：课程只说"append 到你自己的 prompt 上"，没有区分是 system prompt 还是用户消息 | [[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-the-claude-md-file]] |
| skill | 只进目录，正文按需读取 | [[2026-11-20-harness-engineering-go-practice]] |
| 工具定义 | 在 Anthropic Messages API 形态的最小循环里走独立的 `tools` 参数，与 `system` 并列；但 Anthropic 认为它应得到与整体 prompt 同等的 prompt engineering 投入 | [[2026-11-20-learn-claude-code-readme]]、[[2026-11-20-anthropic-building-effective-agents]] |
| 运行时上下文（时间、环境等动态段） | DeepSeek Harness：不进，以 `user/message` 追加，每次重试前刷新 | [[2026-11-20-deepseek-harness-agent-loop-source]] |
| 工具集的增减 | DeepSeek Harness：不改 system prompt，往日志追加一条 `developer/message` | [[2026-11-20-deepseek-harness-agent-loop-source]] |
| 具体任务与会话角色 | [[anthropic\|Anthropic]] 长时运行实验：initializer agent 和 coding agent 的 system prompt、工具集完全相同，只有初始 user prompt 不同 | [[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]] |
| 大篇幅的项目知识 | 不进；入口文件约 100 行只作目录，其余留在 `docs/` 按需去读 | [[2026-11-20-openai-harness-engineering]] |
| 必须每次都发生的规则 | 不该靠 prompt，交给 [[hooks]] | [[2026-11-20-hooks-in-claude-code]] |

出错时的修复指引也可以不进 system prompt：OpenAI 团队把它写进 lint 的错误信息，只在违规的那一刻进入 agent 上下文（[[2026-11-20-openai-harness-engineering]]）。

### 作为投影的 system prompt

DeepSeek Harness 的 loop 不直接拼字符串，而是把 system prompt 当作状态的投影（[[2026-11-20-deepseek-harness-agent-loop-source]]）：

- 每个 step 之前调用 `systemPrompt.assemble`；`SystemPromptProjection.project` 算出需要提交的变更，以 `system/message` 事件写入 [[session-log|session log]]。发给模型的请求再从日志派生。
- 适配器可以声明 `systemPromptUpdate === 'in-history'`，即在历史中更新而不是替换。
- 发生 [[compaction]] 之类让 session surface 换代的事件后，下一个请求被标为新 series，并重新提交 system prompt。

来源页推断这些机制的目的是保持请求前缀稳定以利于 prompt cache，但文件里没有明说（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

### 与 compaction 的关系

Go 练习仓库的 `Compact` 规格保留开头连续的 system 消息，只压缩中间那段；摘要以一条 user 消息的形式放回，不进 system prompt（[[2026-11-20-harness-engineering-go-practice]]）。

## 变体与演进

- **常量**：learn-claude-code README 的最小循环里 `system=SYSTEM` 是一个固定字符串（[[2026-11-20-learn-claude-code-readme]]）。
- **函数式拼装**：Go 练习仓库的 `Build`，每次启动按固定顺序拼一次（[[2026-11-20-harness-engineering-go-practice]]）；[[openharness|OpenHarness]] 有独立的 `prompts/` 目录负责 system prompt 组装、`CLAUDE.md` 和 skills（项目自述，README 未讲顺序）（[[2026-11-20-openharness-readme]]）。
- **可组合的 provider**：Microsoft 用 context provider 逐项贡献指令和状态，可逐项关闭或替换（[[2026-11-20-microsoft-learn-agent-harness]]）。
- **事件溯源式投影**：DeepSeek Harness（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- **可预览**：OpenHarness 的 `--dry-run`（README 标为 Unreleased）不调用模型、不执行工具，只解析设置、prompt 组装、skills 和工具并给出结论（[[2026-11-20-openharness-readme]]）。

## 优缺点和权衡

- **可靠性有限**。写进 prompt 的指令只是"多数时候"被遵守；Claude Code 课程的结语是"必须每次都发生的事，不要放进 prompt，放进 hook"（厂商自述，无遵守率数据）（[[2026-11-20-hooks-in-claude-code]]）。Crash Course 同样说控制必须由软件强制执行（[[2026-11-20-ai-harness-crash-course]]）。
- **篇幅与注意力**。"过多指导等于没有指导"：一切都重要时，agent 只会做局部模式匹配（[[2026-11-20-openai-harness-engineering]]）。目录式的 skill 清单和约 100 行的入口文件都是对这一点的回应。
- **稳定与新鲜**。把动态信息留在 system prompt 之外能让前缀稳定（DeepSeek Harness 的做法，目的为推断）（[[2026-11-20-deepseek-harness-agent-loop-source]]）；代价是模型要从后面的消息里读到这些信息。
- **system prompt 之外的 prompt 同样是杠杆**。Anthropic 的长时运行实验没有改 system prompt，只靠不同的初始 user prompt 和环境里的工件就改变了 agent 的行为（内部实验的定性观察）（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

## 不同来源的分歧

> [!warning] 矛盾
> **system prompt 组装算不算一项独立机制。** learn-claude-code 的网站首页把它单列一课（s10 System Prompt，归在 Planning & Control 层）（[[2026-11-20-learn-claude-code-site]]）；同一门课的仓库 README 当前 17 课轨道里没有这一课（[[2026-11-20-learn-claude-code-readme]]）。两份资料都是 2026-11-20 的快照，哪一版更新无法从资料确认。

- **context file 注入到哪里**：Go 练习仓库明确拼进 system prompt（[[2026-11-20-harness-engineering-go-practice]]）；Claude Code 课程的原话是内容"append 到你自己的 prompt 上"，读起来更像用户侧，但没有明说（[[2026-11-20-the-claude-md-file]]）；OpenAI 文章只说 `AGENTS.md` "注入上下文"（[[2026-11-20-openai-harness-engineering]]）。本批资料不足以确定 Claude Code 或 [[codex|Codex]] 的实际做法。
- **动态内容放哪**：Microsoft 的 context provider 把 todo 状态、模式等会话级内容交给 agent 层（[[2026-11-20-microsoft-learn-agent-harness]]）；DeepSeek Harness 把运行时上下文作为 user 消息追加而不改 system prompt（[[2026-11-20-deepseek-harness-agent-loop-source]]）。Microsoft 文档没有说明 provider 的内容最终落在请求的哪个位置，所以两者是否真的不同无法判断。
- **未覆盖**：AI Harness Crash Course 和 [[pi|Pi]] 的 README 都没有讲 system prompt 怎么组装（[[2026-11-20-ai-harness-crash-course]]、[[2026-11-20-pi-readme]]）。Pi 的 README 只提到 prompt templates 是四种定制手段之一，机制不在资料中（[[2026-11-20-pi-readme]]）。

## 采用它的项目

[[microsoft-agent-framework|Microsoft Agent Framework]]（两级指令）（[[2026-11-20-microsoft-learn-agent-harness]]）、[[deepseek-harness|DeepSeek Harness]]（投影）（[[2026-11-20-deepseek-harness-agent-loop-source]]）、[[openharness|OpenHarness]]（`prompts/`）（[[2026-11-20-openharness-readme]]）、[[learn-claude-code]] 网站版 s10（[[2026-11-20-learn-claude-code-site]]）、Go 练习仓库的 `prompt/` 包（[[2026-11-20-harness-engineering-go-practice]]）、[[claude-agent-sdk|Claude Agent SDK]]（Anthropic 实验中 system prompt 保持不变）（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

## 相关概念

[[context-files]]、[[skills]]、[[tools]]、[[agent-harness]]、[[agent-loop]]、[[context-management]]、[[compaction]]、[[session-log]]、[[hooks]]、[[memory]]、[[planning-and-plan-mode]]、[[harness-engineering]]
