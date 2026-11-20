---
title: Pi
type: entity
kind: project
aliases: [pi, pi-coding-agent, pi-mono, earendil-works pi]
tags: [agent-harness, open-source, typescript, coding-agent, minimalism]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-pi-readme
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-openharness-readme
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-learn-harness-engineering-course
---

# Pi

> [!note] 资料边界
> 主要来源是 2026-11-20 导出的仓库首页。README 侧重安装、包结构、安全立场和供应链，**不讲 agent loop 的实现**；扩展、skills、RPC、SDK 的细节在未摄入的 `packages/coding-agent/docs/` 下（[[2026-11-20-pi-readme]]）。

## 是什么、解决什么问题

Pi 自称"一个最小、可扩展、可以变成你自己的 [[agent-harness|agent harness]]"。核心取向是故意少做：自带"强力的默认值"，但明确不内置 sub-agents 和 plan mode，也明确没有内置权限系统。主张是 "Adapt Pi to your workflows, not the other way around."（项目自述，[[2026-11-20-pi-readme]]）。

它提供四种使用形态：交互式 TUI、print / JSON 模式、RPC、TypeScript SDK；README 举 OpenClaw 作为集成案例（[[2026-11-20-pi-readme]]）。

## 关键事实（2026-11-20 导出时的页面数据，[[2026-11-20-pi-readme]]）

- 组织：earendil-works。资料中没有出现作者姓名。
- 当前版本：最新 Release v1.5.2（页面显示 "last week"）；共 278 个 Release。
- 许可证：MIT。语言：TypeScript 87.1%、HTML 10.2%。
- Star 122.7k，Fork 15.8k，贡献者 316；8,058 次提交；最新提交 "26 minutes ago"。
- 运行环境：Node.js 22.19 及以上；macOS、Linux、Windows。
- 首次发布：资料中没有明确日期。`LICENSE` 的提交显示 "last year"，来源页据此推断仓库始于 2025 年。

## 工作原理概要

- **分层的包**：`pi-ai`（统一的多 provider LLM API）→ `pi-agent-core`（agent 运行时：tool calling 与状态管理，[[agent-loop|agent loop]] 所在层）→ `pi-coding-agent`（CLI）。另有 `pi-tui`、`pi-durable`（durable 的 conversation、task、document 运行时）、`pi-telemetry`（厂商中立的遥测契约）、`chord`。各层可被外部项目单独依赖（[[2026-11-20-pi-readme]]）。
- **扩展模型**：四种定制手段，extensions、[[skills]]、prompt templates、themes，可打包成 Pi package 通过 npm 或 git 分享。见 [[plugins-and-extensibility]]（[[2026-11-20-pi-readme]]）。
- **不内置 subagent 和 plan mode**：原文 "skips features like sub-agents and plan mode. Ask Pi to build what you want, or install a package that does it your way."。见 [[subagents]]、[[planning-and-plan-mode]]（[[2026-11-20-pi-readme]]）。
- **不做权限系统**：没有内置的[[permissions|权限系统]]来限制文件系统、进程、网络或凭据访问，默认以启动它的用户和进程的权限运行。需要更强边界时"把 Pi 容器化或放进沙箱"，README 给出三种模式：Gondolin extension（`pi` 进程和凭据留在宿主机，工具被路由进本地 Linux micro-VM）、Plain Docker、OpenShell。见 [[sandboxing]]（[[2026-11-20-pi-readme]]）。
- **供应链**：把 npm 依赖变更当作需要 review 的代码变更；精确版本锁定、`min-release-age=2`、`--ignore-scripts`、lifecycle script allowlist、定时 `npm audit`（[[2026-11-20-pi-readme]]）。
- **上下文文件**：仓库根有 `AGENTS.md`，README 称它是对人和 agent 都适用的项目规则。见 [[context-files]]（[[2026-11-20-pi-readme]]）。

README 没有描述的部分：agent loop 实现、[[compaction]]、会话存储、[[steering-and-cancel|插话与取消]]、[[hooks]] 或 extension 的事件模型、内置工具清单、是否支持 [[mcp|MCP]]（[[2026-11-20-pi-readme]]）。

### 来自第三方的间接信息

Go 练习仓库的代码注释说，它的三个 hook 插入点（`BeforeToolCall`、`AfterToolCall`、`TransformContext`）和事件名（`agent_start`、`turn_start`、`message_end`、`tool_execution_start`、`tool_execution_end`、`turn_end`、`agent_end`）与 Pi 保持一致（[[2026-11-20-harness-engineering-go-practice]]）。这是练习仓库作者的说法；Pi 的 README 没有列出这些名字，本库无法从 Pi 一侧核实。

## 优缺点与适用场景

- 适用：想要小而可改的底座、愿意写或安装扩展的开发者；需要把 agent 嵌入自己产品的团队；已有容器或沙箱基础设施的人（来源页的归纳，[[2026-11-20-pi-readme]]）。
- 不适用：期望开箱即有权限确认、plan mode、subagent 的用户；不能提供外部隔离又要在敏感环境直接运行的场景（[[2026-11-20-pi-readme]]）。
- 贡献门槛：新贡献者的 issue 和 PR 默认被自动关闭（[[2026-11-20-pi-readme]]）。
- README 没有性能或任务成功率数据；作者主张真实会话数据比 "toy benchmarks" 更能改进编码 agent（[[2026-11-20-pi-readme]]）。
- "不内置权限系统"的理由 README 没有写。来源页的推断是作者认为应用层逐次确认既打断流程又不是真正的安全边界，需其他资料佐证（[[2026-11-20-pi-readme]]）。

## 同类替代品

- [[openharness|OpenHarness]]：在权限系统、subagent、plan mode 三点上直接相反，全部内置（[[2026-11-20-openharness-readme]]）。
- [[deepseek-harness|DeepSeek Harness]]：同样强调可扩展，但取向是"连核心都是插件"；README 不做"故意不做什么"的取舍声明（[[2026-11-20-deepseek-harness-readme]]）。
- [[claude-code|Claude Code]]：内置权限模式、plan mode、subagents。
- [[learn-harness-engineering]] 的"前沿 Harness 拆解"把 Pi 与 Claude Code、Codex、DeepSeek 并列（[[2026-11-20-learn-harness-engineering-course]]）。
- 完整对比见 [[开源-harness-设计取向对比]]。

## 演进时间线

资料没有版本历史。可见的只有：旧名 `pi-mono`；导出时已过 1.0 且发布频繁；commit 信息里出现 `apps/p2`、`p3`、Chord v1 移除，来源页推断正在开发基于 Chord 的新一代应用（[[2026-11-20-pi-readme]]）。

## 未解问题

- agent loop、compaction、session 存储、extension 事件模型的实际设计，需要摄入 `pi-agent-core` 源码和 docs。
- `pi-durable` 的 durable 语义；`chord` 与 coding agent 的关系（[[2026-11-20-pi-readme]]）。
- extension 能否自行实现确认式权限，是否已有这样的 package（[[2026-11-20-pi-readme]]）。
