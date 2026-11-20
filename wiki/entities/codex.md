---
title: Codex
type: entity
kind: project
aliases: [OpenAI Codex, Codex CLI]
tags: [coding-agent, openai, harness-engineering]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-openharness-readme
  - 2026-11-20-learn-harness-engineering-course
---

# Codex

> [!note] 资料边界
> 本库没有 Codex 的产品文档或源码。几乎全部信息来自 [[openai|OpenAI]] 一篇实践报告，讲的是"一个团队怎样用 Codex"，不是 Codex 的内部设计。Codex 自身的 [[agent-loop|agent loop]]、[[permissions|权限]]、[[sandboxing|sandbox]]、[[compaction]] 等机制，资料均未提及。

## 是什么、解决什么问题

Codex 是 OpenAI 的 coding agent。在 harness engineering 一文中，它是唯一的代码生产者：一个小团队用五个月构建并交付一款内部 beta 产品，约一百万行代码全部由 Codex 生成，没有一行人手写（团队自述，无第三方验证，[[2026-11-20-openai-harness-engineering]]）。

## 关键事实

- 组织：OpenAI（[[2026-11-20-openai-harness-engineering]]）。
- 形态：文中出现 Codex CLI，初始脚手架由 Codex CLI + GPT-5 生成；另提到"本地和云端的其他 agent"参与审查（[[2026-11-20-openai-harness-engineering]]）。
- 订阅凭据：[[openharness|OpenHarness]] 自述可通过本地 `~/.codex/auth.json` 桥接 Codex 订阅（[[2026-11-20-openharness-readme]]）。
- 首次发布、当前版本、许可证：资料未提及。

## 工作原理概要（资料中可见的部分）

以下是该团队围绕 Codex 搭建的环境，属于 [[harness-engineering|harness engineering]]，不是 Codex 的内建机制（[[2026-11-20-openai-harness-engineering]]）：

- **AGENTS.md 作为入口**：约 100 行，注入上下文，只作目录，指向结构化的 `docs/`。"一个巨大的 AGENTS.md"方案失败过。这是 [[context-files|context file]] 的渐进式披露用法，目的是 [[context-management|上下文管理]]。
- **Skills**：团队写了处理 DOM 快照、截图、导航的 [[skills]]，配合接入 agent 运行时的 Chrome DevTools Protocol。
- **自我验证**：每个 git worktree 起一个应用实例和一套临时的可观测性栈，Codex 用 LogQL、PromQL 查询（[[verification-and-observability]]）。
- **Agent 审 agent**：Codex 本地自审，再请其他 agent 审查，循环到所有 agent reviewer 满意（作者称为 Ralph Wiggum 循环）。
- **计划作为工件**：复杂工作写 execution plan，带进度和决策日志并提交进仓库（[[planning-and-plan-mode]]）。
- **后台任务**：定期运行后台 Codex 任务扫描偏差、发起重构 PR。

## 值得记下的数据（均为团队自述，[[2026-11-20-openai-harness-engineering]]）

- 2025 年 8 月下旬首次提交；文章发表于 2026-02-11。
- 约 100 万行代码（含文档和工具）；约 1,500 个 PR；起初 3 名工程师，平均每人每天 3.5 个 PR，后扩到 7 人。
- 单次 Codex 运行经常在一个任务上持续超过 6 小时，是 [[long-running-agents|长时运行 agent]] 的一个数据点。
- 估计用时约为手写的 1/10（估计值，无估算方法）。

## 优缺点与适用场景

- 文中展示的能力：在该仓库里，给一个 prompt，Codex 可以从复现 bug 一路做到合并 PR，仅在需要判断时升级给人。作者强调这**高度依赖该仓库的特定结构和工具**，不应假定可泛化（[[2026-11-20-openai-harness-engineering]]）。
- 文中承认的问题：Codex 会复制仓库里已有的模式，包括不好的，需要持续"垃圾回收"；早期进展慢，作者归因于环境规范不足而非 Codex 能力不足（[[2026-11-20-openai-harness-engineering]]）。
- 局限：单一团队、单一 greenfield 项目、OpenAI 内部条件，没有成本和缺陷率数据（[[2026-11-20-openai-harness-engineering]]）。

## 同类替代品

- [[claude-code|Claude Code]]：[[learn-harness-engineering]] 课程把两者并列为要在仓库里为之搭环境的现成 coding agent（[[2026-11-20-learn-harness-engineering-course]]）。
- 开源 harness：[[openharness|OpenHarness]]、[[pi|Pi]]、[[deepseek-harness|DeepSeek Harness]]。

## 演进时间线

资料未提及 Codex 自身的版本历史。

## 未解问题

- Codex 运行时的权限模型、sandbox、compaction、[[subagents|subagent]] 机制。
- 文中"本地和云端 agent"各自是什么产品形态。
- raw 是中文官方译文，个别术语与英文原意有距离（[[2026-11-20-openai-harness-engineering]]）。
