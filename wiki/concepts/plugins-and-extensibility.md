---
title: Plugins and extensibility（插件与扩展模型）
type: concept
aliases: [plugins, plugin, 插件, 扩展, extensions, extensibility, 扩展模型, 扩展机制, Pi package, everything is a plugin, middleware, context provider]
tags: [agent-harness, plugins, extensibility, supply-chain, architecture]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-openharness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-ai-harness-crash-course
---

# Plugins and extensibility（插件与扩展模型）

## 定义

扩展模型回答的是：[[agent-harness|agent harness]] 的哪些部分是写死的核心，哪些部分可以由用户或第三方增加、替换、关闭，以及这些增量以什么形式打包和分发。plugin（插件）在本批资料里没有统一含义：在 [[openharness|OpenHarness]] 里它是一个带清单文件的目录，装着 commands、hooks、agents；在 [[deepseek-harness|DeepSeek Harness]] 里它是构成 harness 本身的单元；[[pi|Pi]] 把可分发的单元叫 Pi package；[[microsoft-agent-framework|Microsoft Agent Framework]] 不用"插件"这个词，用的是 context provider 和 middleware。

## 要解决的问题和动机

- **循环不变，能力外挂**。learn-claude-code 的总主张是 "The loop belongs to the agent. The mechanisms belong to the harness."：新工具注册进 dispatch map，hook 围着循环挂，[[mcp|MCP]] 工具并入同一个 tool pool，循环本身不动（[[2026-11-20-learn-claude-code-readme]]）。
- **工作流不该被 harness 写死**。Pi 的主张是 "Adapt Pi to your workflows, not the other way around."（作者主张；[[2026-11-20-pi-readme]]）。
- **通用产品要能变成"你的"**。[[claude-code|Claude Code]] 官方课程把 `CLAUDE.md`、subagents、skills、MCP servers、hooks 五样合称"定制"，说开箱即用的 Claude Code 是通用的，这一章教怎么把它调成团队自己的（厂商自述；[[2026-11-20-claude-code-101-course]]）。
- **默认组合与逐项替换**。Microsoft 的出发点是自己从零拼装成本高，所以给一套带明确取向的默认组合，同时保留逐项替换和关闭的口子（[[2026-11-20-microsoft-learn-agent-harness]]）。

## 工作原理：四种扩展模型

| 模型 | 代表 | 核心是什么 | 扩展单元 | 来源 |
|---|---|---|---|---|
| 固定子系统 + 兼容格式 | [[openharness\|OpenHarness]] | 一组固定的子系统目录 | 沿用 Claude Code 格式的 plugin、skill、hook | [[2026-11-20-openharness-readme]] |
| 小核心 + 外置包 | [[pi\|Pi]] | 故意少做的运行时 | extensions、skills、prompt templates、themes，打包成 Pi package | [[2026-11-20-pi-readme]] |
| 一切皆插件 | [[deepseek-harness\|DeepSeek Harness]] | 插件运行时（Cordis） | 插件，连 agent loop 也是一个包 | [[2026-11-20-deepseek-harness-readme]] |
| 组合既有构件 | [[microsoft-agent-framework\|Microsoft Agent Framework]] | 框架已有的 agent 抽象 | context provider、middleware | [[2026-11-20-microsoft-learn-agent-harness]] |

### 固定子系统加兼容格式（OpenHarness）

- 能力按目录分成固定子系统：`engine/`、`tools/`、`skills/`、`plugins/`、`permissions/`、`hooks/`、`mcp/`、`coordinator/` 等（README 称 10 个子系统，目录树实际列了 14 个；[[2026-11-20-openharness-readme]]）。
- 扩展走格式兼容：插件清单是 `.claude-plugin/plugin.json`，可带 `commands/*.md`、`hooks/hooks.json`、`agents/*.md`；`plugins/` 的注释还列了 MCP servers。自述"兼容 claude-code plugins，用 12 个官方插件测试过"，表格只列了 6 个（[[2026-11-20-openharness-readme]]）。
- 自定义工具继承 `BaseTool`，声明 `name` / `description` / `input_model` 并实现 `execute`；管理命令是 `oh plugin list | install <source> | enable <name>`（[[2026-11-20-openharness-readme]]）。
- 来源页的判断：它的生态位是"兼容层"而非独立标准（[[2026-11-20-openharness-readme]]）。

### 小核心加外置包（Pi）

- 四种定制手段是 extensions、[[skills]]、prompt templates、themes，可以打包成 Pi package，通过 npm 或 git 分享（[[2026-11-20-pi-readme]]）。
- 核心故意不做的功能交给扩展：README 明说跳过 sub-agents 和 plan mode，"让 Pi 自己造出来，或安装一个按你的方式做的 package"；[[permissions|权限系统]]也不内置（[[2026-11-20-pi-readme]]）。
- 包结构本身是分层的：`pi-ai`（多 provider LLM API）→ `pi-agent-core`（agent 运行时）→ `pi-coding-agent`（CLI），各层可单独被外部项目依赖；此外还有 RPC 和 SDK 两种被程序集成的形态（[[2026-11-20-pi-readme]]）。
- extension 的事件模型 README 没有描述（[[2026-11-20-pi-readme]]）。

### 一切皆插件（DeepSeek Harness / Cordis）

- README 的核心主张只有一句 "Everything is a Plugin"，harness 构建在 Cordis 之上；"为什么一切皆插件比固定子系统更好"README 没有论证，只指向 Cordis 的论文（[[2026-11-20-deepseek-harness-readme]]）。
- 源码能核实的部分：agent loop 是 `packages/core/agent-loop` 下的一个包，通过 Cordis 上下文取 `tools`、`llm`、`systemPrompt` 等服务，自己不实现重试、压缩、权限、步数上限这些策略，而是在 `agent/pre-step`、`agent/request`、`agent/request-error`、`agent/turn-stopping` 等事件上让插件改写或否决决定（[[2026-11-20-deepseek-harness-agent-loop-source]]）。事件细节见 [[hooks]]。
- 也有不让插件碰的地方：`agent/request` 事件里不允许改 provider、model 或 reasoning effort，改了就抛错（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- "一切皆插件"的边界（loop、session、LLM 适配器是否都可替换）、插件之间的依赖与隔离如何保证，本批资料没有答案；对 Cordis "时空可组合性"的解释是来源页的推断（[[2026-11-20-deepseek-harness-readme]]）。

### Middleware 与 context provider 的组合（Microsoft）

- Harness 不另造运行时，只是把框架已有的构件按一套默认值组装起来，产物仍是普通的 agent 对象（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 两种机制分工：**context provider** 负责会话级的指令、工具、记忆、todo 状态、运行模式及可选能力；**middleware 与 decorators** 负责审批处理、可观测性、可选的有界循环（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 三种定制动作：逐项关闭（`DisableTodoProvider`、`DisableToolAutoApproval` 等，Python 为 `disable_*`）；替换内建 provider（Python 的 `todo_provider`、`mode_provider`）；追加自定义 provider（`AIContextProviders` / `context_providers`）（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 多个同类 provider 并存时用 `tool_name_prefix` 避免工具名冲突，审批规则要用该 provider 自己的规则工厂生成才能匹配带前缀的名字（[[2026-11-20-microsoft-learn-agent-harness]]）。

### 教学实现里的最小形态

- Go 练习仓库：每个机制对应 `Options` 里的一组字段，零值即关闭；重试更进一步，`Retry` 自己实现 `Model` 接口包在模型外面，循环完全不知道它存在（[[2026-11-20-harness-engineering-go-practice]]）。
- learn-claude-code：s02 工具注册进 `TOOL_HANDLERS`，s04 hooks，s07 skill loading，s14 MCP 工具带命名空间并入同一个 tool pool（[[2026-11-20-learn-claude-code-readme]]）。

## 分发与供应链

- **分发渠道**：Pi package 走 npm 或 git（[[2026-11-20-pi-readme]]）；DeepSeek Harness 号召插件作者给仓库加 `dsh-plugin` topic 以便被发现（[[2026-11-20-deepseek-harness-readme]]）；OpenHarness 用 `oh plugin install <source>`（[[2026-11-20-openharness-readme]]）；Claude Code 的项目级 hooks 提交进仓库后全团队自动获得（[[2026-11-20-hooks-in-claude-code]]）。
- **扩展等于在用户机器上运行别人的代码或指令**。Pi 默认以启动者的全部权限运行（[[2026-11-20-pi-readme]]），装进来的 extension 也就拥有同样的权限（后半句是笔者推断，README 没有讨论第三方 package 的信任问题）。
- **Pi 对自身依赖的做法**（针对 Pi 自己的 npm 依赖，不是针对第三方 Pi package）："We treat npm dependency changes as reviewed code changes."：直接外部依赖锁定精确版本；`min-release-age=2` 避开当天发布的版本；pre-commit 默认拦截 lockfile 变更；官方安装器按 install-lock 连传递依赖一起锁定，而直接 `npm install -g` 不锁传递依赖；安装和 CI 一律 `--ignore-scripts`，带 lifecycle script 的新依赖要进 allowlist；定时跑 `npm audit` 和 `npm audit signatures`（[[2026-11-20-pi-readme]]）。
- **随仓库而来的扩展是攻击面**。OpenHarness 的项目级 skills 默认启用，对不可信仓库可用 `oh config set allow_project_skills false` 关闭（[[2026-11-20-openharness-readme]]）；详见 [[skills]]。Crash Course 的一般性提醒是：agent 在文件里读到一条指令，不代表它应该照做（[[2026-11-20-ai-harness-crash-course]]）。提交进仓库的 hooks 是否有同样的开关，资料没有说明。
- 没有一份资料描述插件的签名、审核或权限声明机制。

## 优缺点和权衡

- **固定子系统**：结构一眼可读，适合"看懂生产级 agent 的内部结构"这一目标（OpenHarness 的自我定位）；代价是能力边界由项目决定，兼容别人的格式意味着跟随别人的演进（后半句是笔者推断；[[2026-11-20-openharness-readme]]）。
- **小核心**：核心小、可改；代价是开箱缺少权限确认、plan mode、subagent，要自己写或挑选 package（[[2026-11-20-pi-readme]]）。
- **一切皆插件**：策略全部可替换；代价是单看一个文件跑不起来，理解一个行为要追到多个插件，例如没有内建步数上限，是否有默认插件兜底未知（[[2026-11-20-deepseek-harness-agent-loop-source]]）。项目处于 developer preview，README 明确警告会有破坏兼容性的变更（[[2026-11-20-deepseek-harness-readme]]）。
- **组合既有构件**：产物是普通 agent，抽象不增加；代价是三个 SDK 的默认值和成熟度不一致，Go 需要自己组合 compaction、looping、shell（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 没有资料给出不同扩展模型在可维护性或任务表现上的对比数据。

## 不同来源的分歧

- **要不要这么多抽象**。[[anthropic|Anthropic]] 的《Building effective agents》劝人少用框架、直接用 LLM API，理由是额外的抽象层会遮住底层 prompt 和响应、更难调试（作者经验性主张；[[2026-11-20-anthropic-building-effective-agents]]）。Microsoft 提供的正是默认开启十来项能力的组合式框架；来源页认为两者未必矛盾，但出发点相反（[[2026-11-20-microsoft-learn-agent-harness]]）。
- **什么该内置**。OpenHarness 内置权限、subagent、Plan Mode，Pi 明确不内置这三样（[[2026-11-20-openharness-readme]]、[[2026-11-20-pi-readme]]）。DeepSeek Harness 的 README 不做这类取舍声明（[[2026-11-20-deepseek-harness-readme]]）。
- **MCP 算不算插件**。learn-claude-code 的 README 把 s14 叫 "MCP Plugin"，归在"扩展与组装"阶段（[[2026-11-20-learn-claude-code-readme]]）；网站把 MCP Tools 归入 "Multi-Agent Platform" 层（[[2026-11-20-learn-claude-code-site]]）。

## 采用它的项目

见上面"四种扩展模型"表。另：[[claude-code|Claude Code]] 的五种定制机制（[[2026-11-20-claude-code-101-course]]），OpenHarness 所兼容的 plugin 格式即来自它（[[2026-11-20-openharness-readme]]）；本批资料没有 Claude Code 插件格式的一手描述。

## 相关概念

[[hooks]]、[[skills]]、[[mcp]]、[[tools]]、[[subagents]]、[[permissions]]、[[sandboxing]]、[[context-files]]、[[agent-harness]]、[[harness-engineering]]；横向比较见 [[开源-harness-设计取向对比]]。
