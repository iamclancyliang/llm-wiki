---
title: DeepSeek Harness
type: entity
kind: project
aliases: [dsh, DSH, deepseek-ai/deepseek-harness, ReactLoopAgent]
tags: [agent-harness, open-source, typescript, plugin-architecture]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-openharness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-harness-engineering-go-practice
---

# DeepSeek Harness

> [!note] 资料边界
> 两份来源：仓库首页导出（README 很短，几乎不含架构说明）和一个源码文件 `packages/core/agent-loop/src/agent.ts`。架构文档 `docs/architecture.md`、`SAFETY.md`、Cordis 论文都不在资料中。本页把"README 明文""源码可见""推断"分开标注。

## 是什么、解决什么问题

DeepSeek Harness（命令 `dsh`）是 DeepSeek AI 开源的 [[agent-harness|agent harness]]，README 的核心主张只有一句："Everything is a Plugin"。它构建在 Cordis 之上，以 Web UI 为主要入口（`npx @deepseek-ai/dsh web`，默认监听 `127.0.0.1:3080`）。README 没有正面写要解决什么问题，也没有解释为什么一切皆插件更好（[[2026-11-20-deepseek-harness-readme]]）。

## 关键事实（2026-11-20 导出时的页面数据，[[2026-11-20-deepseek-harness-readme]]）

- 组织：DeepSeek-AI。阶段：developer preview，README 用大写警告会有破坏兼容性的变更。
- 版本：commit 信息中出现 `0.2.2-rc.4`，导出时处于 0.2.x 候选版本。
- 许可证：MIT。语言：TypeScript 95.5%，另有 Python、Swift、C#。
- Star 283.3k，Fork 35.1k，贡献者 54；28,026 次提交，41 个 tag；最新提交 "17 hours ago"。
- 最早的文件提交显示 "5 months ago"，来源页据此**推断**公开历史约 5 个月。首次发布日期资料中没有。
- 没有 Issues 页签，反馈走 GitHub Discussions。

## Cordis

README 说 harness 由 Cordis 驱动，并把其设计指向论文《A Programming Paradigm for Spatiotemporal Composability》（arXiv:2608.25512）（[[2026-11-20-deepseek-harness-readme]]）。源码可见的用法：从 `@deepseek-ai/cordis` 导入 `Context`，通过 `loopCtx.tools`、`loopCtx.llm`、`loopCtx.systemPrompt` 取服务（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

"时空可组合性"的含义 README 未解释。来源页的**推断**是："空间"指上下文作用域的层级隔离，"时间"指注册的副作用随生命周期可逆地卸载；`vendor/` 的 commit 信息显示 Cordis 是外部上游项目，本仓库 vendoring 并回移补丁。两条都待读论文和架构文档确认（[[2026-11-20-deepseek-harness-readme]]）。这是该项目的 [[plugins-and-extensibility|扩展模型]]基础。

## 工作原理概要：agent loop 源码要点

以下均直接来自 `agent.ts`（751 行，默认实现 `ReactLoopAgent`），除非标为推断（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

- **两个设计核心**：输入进 inbox 队列，只在 turn 或 step 的边界被领取；发给模型的每个请求都从 [[session-log|session log]]（只追加的事件日志）派生，loop 自己不持有消息历史。
- **三层控制流**：driver（`kick`）→ turn → step，step 内还有请求重试循环。状态是三态 Phase：`idle`、`maintenance`、`running`；`maintenance` 对外也报告 idle。见 [[agent-loop]]。
- **停止条件**：`TurnEndReason` 有五种，`completed`（没有 tool-call 块，或工具结果 `concluded` 为真）、`max-tokens`（粘性）、`blocked`（pre-step 被 reject）、`aborted`、`error`。文件里**没有** max-steps / max-turns 之类的迭代上限。
- **插话与取消**：`followup` 进 next-turn 队列，`steer` 和 `inject` 进 next-step 队列；插话不打断正在进行的流或工具批次。`cancel` 的 cause 是封闭联合 `user | parent | disposed | hook(reason)`。见 [[steering-and-cancel]]。
- **工具执行**：一个 step 的全部 tool call 作为一个批次交给[[tools|工具]]服务，并发度由 `maxParallelToolCalls` 控制；loop 不逐个调用工具。工具可返回 `additionalContexts`，排进 next-step 队列。
- **错误恢复**：模型请求失败不在 loop 里重试，而是通过 waterfall 事件 `agent/request-error` 询问插件；被中断的半截输出以 `interrupted: true` 落盘；step 抛错时给悬空的 tool call 补写 `tool/result`，保证日志始终合法。见 [[error-recovery]]。
- **事件点**：`agent/status`、`agent/pre-step`、`agent/request`、`agent/assistant-stream`、`agent/request-error`、`agent/turn-stopping`、`agent/error`。`agent/turn-stopping` 的处理器可以往 next-step 队列塞消息让 turn 继续。这里没有 PreToolUse / PostToolUse 级别的事件。见 [[hooks]]。
- **System prompt**：是投影，变更以 `system/message` 事件写入日志（[[system-prompt]]）。
- **Compaction**：本文件不实现 [[compaction]]，只提供协作接口 `runMaintenance(job)`（仅 idle 时可进入）和 surface 代数检查；代码注释提到 "Compaction during the first resumed pre-step must still mark a new series."

来源页的推断（未经证实）：[[permissions|权限]]检查在 `tools.execute` 内部或由其他插件承担；工具级钩子在工具服务一侧；压缩是一种维护作业；步数上限被当作插件策略；`parent` cancel cause 暗示父 agent 可取消子 agent（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 其他可见的设计

- **上下文文件**：README 写 "For agents, follow AGENTS.md."；`CLAUDE.md` 是指向 `AGENTS.md` 的 symlink。见 [[context-files]]（[[2026-11-20-deepseek-harness-readme]]）。
- **安全**：运行前要求先读 `SAFETY.md`，内容不在资料中；权限与 [[sandboxing|沙箱]]模型在资料中空白（[[2026-11-20-deepseek-harness-readme]]）。
- 从 commit 信息和目录名**推断**：支持 [[mcp|MCP]]（`feat/mcp-tool-loading`、`feat/mcp-oauth`），有 [[subagents|subagent]] 和 [[skills]] 机制（`feat/subagent-names`、`feat/upstream-skills`），进程模型分 Host 与 Client（[[2026-11-20-deepseek-harness-readme]]）。

## 优缺点与适用场景

- 适用：作为"事件溯源式 agent loop"的参考实现，面向需要可恢复、可审计、支持中途插话和干净取消的 [[long-running-agents|长时间运行 agent]]（来源页的判断，[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- 不适用：需要稳定接口的生产集成（developer preview）；只读 README 上手架构（[[2026-11-20-deepseek-harness-readme]]）。也不适合当入门示例，单看 `agent.ts` 跑不起来，策略都在文件之外（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- 风险：没有内建步数上限，若没有插件兜底，模型持续发 tool call 时 turn 不会自行停止；是否有默认插件提供保护未知（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- README 没有任何性能或任务成功率数据（[[2026-11-20-deepseek-harness-readme]]）。

## 同类替代品

- [[openharness|OpenHarness]]：固定子系统目录加 Claude 兼容格式（[[2026-11-20-openharness-readme]]）。
- [[pi|Pi]]：小核心加外置包；两者都把 `AGENTS.md` 作为 agent 入口（[[2026-11-20-pi-readme]]）。
- [[learn-harness-engineering]] 的"前沿 Harness 拆解"栏目列有 "DeepSeek"，来源页认为应指本项目（[[2026-11-20-learn-harness-engineering-course]]）。
- 注意区分：Go 练习仓库用的是 DeepSeek 的模型 API，与本项目无关（[[2026-11-20-harness-engineering-go-practice]]）。
- 完整对比见 [[开源-harness-设计取向对比]]。

## 演进时间线

资料只有相对时间：约 5 个月前初始化仓库（README、AGENTS.md、CLAUDE.md symlink）；约 3 个月前 "Adopt MIT for DSH packages"；导出时在 0.2.2 候选版本（[[2026-11-20-deepseek-harness-readme]]）。`agent.ts` 最新提交 `dd54a74` 约在导出前 2 周，仍在调整销毁与唤醒语义（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

## 未解问题

- "一切皆插件"的边界：agent loop、session、LLM 适配器是否都可替换（[[2026-11-20-deepseek-harness-readme]]）。
- 谁订阅 `agent/request-error` 实现退避、谁实现压缩并调用 `runMaintenance`（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- 是否只支持 DeepSeek 模型；`BENCHMARK.md` 测什么（[[2026-11-20-deepseek-harness-readme]]）。
- Star 数相对约 5 个月的公开历史非常高，资料无法解释，只应作为导出时的页面数据引用（[[2026-11-20-deepseek-harness-readme]]）。
