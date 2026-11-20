---
title: Agent harness
type: concept
aliases: [AI harness, harness, agent 运行时脚手架, 智能体 harness]
tags: [agent-harness, harness-engineering, architecture]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-openharness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-what-is-claude-code
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-claude-code-101-course
---

# Agent harness

## 定义

Agent harness（也叫 AI harness）是模型之外、让模型能真正干活的那一层东西。本库资料里这个词有**两层含义**，写作和阅读时必须分清：

1. **运行时程序**：包在模型外面的软件，负责驱动模型调用和工具调用、管理会话状态与上下文、施加审批策略、让 agent 在多步任务里持续推进。Microsoft 的定义是"把语言模型变成能干活的 agent 的运行时脚手架（runtime scaffolding）"（[[2026-11-20-microsoft-learn-agent-harness]]）。[[learn-claude-code]]、[[openharness|OpenHarness]]、[[pi|Pi]]、[[deepseek-harness|DeepSeek Harness]]、Go 练习仓库和 AI Harness Crash Course 用的都是这层含义（[[2026-11-20-learn-claude-code-readme]]、[[2026-11-20-openharness-readme]]、[[2026-11-20-pi-readme]]、[[2026-11-20-deepseek-harness-readme]]、[[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-ai-harness-crash-course]]）。
2. **仓库级的工作环境**：团队在一个现成的 coding agent 之外搭建的规则文件、状态文件、验证流程、lint、可观测性栈。[[learn-harness-engineering|Learn Harness Engineering]] 课程把 harness 的本质说成"给模型建立一套闭环的工作系统"，其每个环节都绑定仓库里的一个文件或命令（[[2026-11-20-learn-harness-engineering-course]]）；[[openai|OpenAI]] 的文章谈的也是这一层（[[2026-11-20-openai-harness-engineering]]）。

本页以第一层含义为主，第二层的做法见 [[harness-engineering]]。两层的共同点是同一句话的两种读法：模型提供智能，其余的都要有人造出来。

## 要解决的问题和动机

- 模型知道怎么写代码，但自己拿不到项目文件、没有改文件的权限、也无法运行应用验证结果；让这些事发生的那层软件就是 harness（[[2026-11-20-ai-harness-crash-course]]）。
- [[anthropic|Anthropic]] 对 agent 的官方口径是"把 LLM 放进一个 loop 里，并让它能访问工具"（[[2026-11-20-what-is-claude-code]]）；《Building effective agents》（2024-12-19）说 agent "通常只是在循环中根据环境反馈使用工具的 LLM"（[[2026-11-20-anthropic-building-effective-agents]]）。该文全文没有出现 harness 一词，但 loop 加工具正是后来 harness 讨论的起点。
- 从零拼装这些能力成本高，这是 Microsoft 提供带默认值的 Harness 的理由（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 第二层含义的动机不同：模型能力强不等于执行可靠。课程列出五类失败：行为越界、跨会话丢上下文、提前宣告完成、不验证自己的工作、过程黑箱（[[2026-11-20-learn-harness-engineering-course]]）。

## 工作原理

运行时 harness 的不变核心是 [[agent-loop|agent loop]]：调用模型、执行模型请求的[[tools|工具]]、把结果回传。learn-claude-code 网站的说法是"生产级系统会在其上叠加策略、权限和生命周期层"（[[2026-11-20-learn-claude-code-site]]），README 的总结句是 "The loop belongs to the agent. The mechanisms belong to the harness."（[[2026-11-20-learn-claude-code-readme]]）。

围绕循环叠加的机制，各资料列出的清单大体重合：[[system-prompt|系统提示词]]组装与 [[context-files|context file]] 注入、[[permissions|权限]]与 [[hooks]]、[[session-log|会话日志]]、[[context-management|上下文管理]]与 [[compaction]]、[[memory|记忆]]、[[subagents|subagent]]、[[skills]]、[[mcp|MCP]]、[[error-recovery|错误恢复]]、[[steering-and-cancel|插话与取消]]、[[verification-and-observability|验证与可观测性]]。Go 练习仓库把其中十几项各压缩成几条测试断言，可当作"最小正确行为"的检查清单（[[2026-11-20-harness-engineering-go-practice]]）。

循环本身的判定虽然简单，但工程量不小：DeepSeek Harness 默认 loop 的源码有约 700 行，大部分花在状态机、日志一致性和取消语义上（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 变体与演进：各资料对 harness 组成的切分

| 来源 | 切分方式 | 值得注意的地方 |
|---|---|---|
| Microsoft Agent Framework | 五层：chat client / chat pipeline / agent 与 context providers / middleware 与 decorators / application UX | 明说 Harness 不规定应用界面，console 只是示例；Harness 不是新运行时，产物仍是普通 agent（[[2026-11-20-microsoft-learn-agent-harness]]） |
| learn-claude-code README | `Harness = Tools + Knowledge + Observation + Action Interfaces + Permissions`；Agent 产品 = Model + Harness | 作者主张；验证没有独立位置，Observation 指环境反馈（[[2026-11-20-learn-claude-code-readme]]） |
| learn-claude-code 网站 | 五个"正交关注点"：Tools & Execution、Planning & Control、Memory Management、Concurrency & Scheduling、Multi-Agent Platform | 权限和 hooks 归在工具执行层；subagent 归在规划与控制层（[[2026-11-20-learn-claude-code-site]]） |
| AI Harness Crash Course | 四个方面：context and memory、tools and execution flow、runtime/security/privacy、agent evaluation | 把隐私和评估单列（[[2026-11-20-ai-harness-crash-course]]） |
| Claude Code 101 | 四个概念：agentic loop、context window、tools、permissions | 厂商自述的心智模型（[[2026-11-20-how-claude-code-works]]、[[2026-11-20-claude-code-101-course]]） |
| OpenHarness | "手、眼、记忆和安全边界"；按子系统分目录（engine、tools、skills、plugins、permissions、hooks、commands、mcp、memory、tasks、coordinator、prompts、config、ui） | 项目自述；README 称 10 个子系统但目录树列了 14 个（[[2026-11-20-openharness-readme]]） |
| Pi | 分包：统一 LLM API → agent 运行时 → 编码 agent CLI，另有 TUI、durable、telemetry 等包 | 各层可被外部项目单独依赖（[[2026-11-20-pi-readme]]） |
| DeepSeek Harness | "Everything is a Plugin"，agent loop 只是一个包 | README 几乎不含架构说明（[[2026-11-20-deepseek-harness-readme]]） |
| Learn Harness Engineering | 仓库内的文件与流程：`AGENTS.md`、`init.sh`、`feature_list.json`、测试与 QA、进度文件 | 第二层含义；把运行时当作给定（后半句是来源页的推断）（[[2026-11-20-learn-harness-engineering-course]]） |

设计取向上有三条明显的轴线（详见 [[开源-harness-设计取向对比]]）：

- **内置多少**。Microsoft 的 Harness 是 batteries-included，默认开启 todo、plan/execute 模式、文件记忆、审批规则、OpenTelemetry 等（[[2026-11-20-microsoft-learn-agent-harness]]）；OpenHarness 自述内置 43 个工具、54 个命令（[[2026-11-20-openharness-readme]]）；Pi 自称"最小、可扩展"，明文不内置 sub-agents、plan mode 和权限系统（[[2026-11-20-pi-readme]]）；DeepSeek Harness 把一切做成插件（[[2026-11-20-deepseek-harness-readme]]）。扩展机制见 [[plugins-and-extensibility]]。
- **状态放在 harness 里还是环境里**。Microsoft 把 todo、文件记忆、模式做成内建 provider（[[2026-11-20-microsoft-learn-agent-harness]]）；Anthropic 的长时运行做法是 harness 不变，把 feature list 和进度写成工作目录里的普通文件，靠 prompt 约定维护（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。见 [[long-running-agents]]。
- **安全边界在哪一层**。OpenHarness 用应用层的多级权限模式加路径规则（自述）（[[2026-11-20-openharness-readme]]）；Pi 不做权限系统，把隔离交给容器或 [[sandboxing|沙箱]]（[[2026-11-20-pi-readme]]）。

## 优缺点和权衡

- **厚 harness**：起步快，但抽象层会遮住底层 prompt 和响应、更难调试。Anthropic 建议先直接用 LLM API，用框架就要读懂底层代码（作者的经验性主张，无数据）（[[2026-11-20-anthropic-building-effective-agents]]）。Microsoft "组合既有构件"的做法可以读作对这一批评的回应，但这是来源页的推断（[[2026-11-20-microsoft-learn-agent-harness]]）。
- **薄 harness**：用户要自己补能力。Pi 的答案是"叫 Pi 自己造出来，或安装别人做好的 package"（[[2026-11-20-pi-readme]]）。
- **harness 再好也替代不了环境**。Anthropic 观察到，即使 [[claude-agent-sdk|Claude Agent SDK]] 自带 compaction，Opus 4.5 仅凭一句高层 prompt 跨多个 context window 也做不出生产质量的 web app；改进来自环境和 prompt，而不是 harness 代码（内部实验的定性观察，无对照数据）（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

## 不同来源的分歧

> [!warning] 矛盾
> **"harness" 指什么。** Microsoft 把它限定为运行时程序（驱动调用、管状态、施加审批）（[[2026-11-20-microsoft-learn-agent-harness]]）；Learn Harness Engineering 课程把它说成仓库里的规则、状态文件和验证流程组成的闭环工作系统（[[2026-11-20-learn-harness-engineering-course]]）。两者都自称 harness 或 harness engineering，但工作对象不同。OpenAI 文章的中文译文正文从未出现 harness 一词，"harness engineering" 是来源页按英文 URL slug 还原的（[[2026-11-20-openai-harness-engineering]]）。

> [!warning] 矛盾
> **控制权在模型还是在 harness。** learn-claude-code README 称赞 [[claude-code|Claude Code]] 的理由是它"不替模型做决策、不强加固定工作流"，模型决定何时调用工具、何时停止（作者评价）（[[2026-11-20-learn-claude-code-readme]]）。AI Harness Crash Course 则说 harness 管理"何时继续、何时停止、何时求助"，并把固定顺序、并行和 retry limit 的图式 workflow 当作常规手段（[[2026-11-20-ai-harness-crash-course]]）。Go 练习仓库的规格站在后者一边：`Verify`、`FollowUp`、`Steering` 能在模型想停时让循环继续，`MaxTurns` 和取消能在模型不想停时让它停下（[[2026-11-20-harness-engineering-go-practice]]）。详见 [[agent-loop]] 与 [[workflows-vs-agents]]。

> [!warning] 矛盾
> **权限系统是不是 harness 的必备件。** learn-claude-code 的公式把 Permissions 列为五要素之一（[[2026-11-20-learn-claude-code-readme]]），OpenHarness 内置多级权限模式（[[2026-11-20-openharness-readme]]）；Pi 明文"没有内置的权限系统"，默认以启动者的全部权限运行（[[2026-11-20-pi-readme]]）。

- UX 是否属于 harness：Microsoft 明确排除（[[2026-11-20-microsoft-learn-agent-harness]]）；OpenHarness 把 React/Ink TUI 列为子系统之一（[[2026-11-20-openharness-readme]]），Pi 把 TUI 做成独立的包（[[2026-11-20-pi-readme]]）。
- 评估是否属于 harness：Crash Course 把 evaluation 列为四个方面之一，但它混合了运行时的完成验证和事后的质量评估（[[2026-11-20-ai-harness-crash-course]]）；learn-claude-code 的五要素里没有它（[[2026-11-20-learn-claude-code-readme]]）。

## 采用它的项目

- 产品：[[claude-code|Claude Code]]（learn-claude-code README 称其为"最优雅、最完整的 agent harness 实现"，这是作者评价而非比较实验）（[[2026-11-20-learn-claude-code-readme]]）；[[codex|Codex]]（[[2026-11-20-openai-harness-engineering]]）。
- SDK 与框架：[[claude-agent-sdk|Claude Agent SDK]]，Anthropic 称之为"通用的 agent harness"（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；[[microsoft-agent-framework|Microsoft Agent Framework]] 的 Harness（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 开源实现：[[openharness|OpenHarness]]、[[pi|Pi]]、[[deepseek-harness|DeepSeek Harness]]（[[2026-11-20-openharness-readme]]、[[2026-11-20-pi-readme]]、[[2026-11-20-deepseek-harness-readme]]）。
- 教学实现：[[learn-claude-code]]（[[2026-11-20-learn-claude-code-readme]]）、Go 练习仓库（截至 2026-11-20 的快照，机制多数还是待实现的桩）（[[2026-11-20-harness-engineering-go-practice]]）。

## 相关概念

[[harness-engineering]]、[[agent-loop]]、[[tools]]、[[system-prompt]]、[[context-files]]、[[planning-and-plan-mode]]、[[workflows-vs-agents]]、[[context-management]]、[[compaction]]、[[session-log]]、[[memory]]、[[permissions]]、[[sandboxing]]、[[hooks]]、[[subagents]]、[[skills]]、[[mcp]]、[[plugins-and-extensibility]]、[[long-running-agents]]、[[error-recovery]]、[[steering-and-cancel]]、[[verification-and-observability]]
