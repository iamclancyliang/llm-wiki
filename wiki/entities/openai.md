---
title: OpenAI
type: entity
kind: org
aliases: [OpenAI]
tags: [org, harness-engineering, codex]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-openharness-readme
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-microsoft-learn-agent-harness
---

# OpenAI

## 是什么

GPT 系列模型和 [[codex|Codex]] 的开发公司。在本 wiki 的主题下，它的一手资料只有一篇：工程师 Ryan Lopopolo 2026-02-11 的实践报告《Harness engineering：在智能体优先的世界中利用 Codex》。本库摄入的是简体中文官方译文，标题把 "Harness engineering" 译成了"工程技术"，正文没有直接出现 harness 一词（[[2026-11-20-openai-harness-engineering]]）。

## 产出

- **文章**：上述实践报告，是 [[harness-engineering|harness engineering]] 这一说法的主要出处之一（[[2026-11-20-openai-harness-engineering]]）。
- **产品**：Codex（含 Codex CLI），文中提到 GPT-5（[[2026-11-20-openai-harness-engineering]]）。

## 在本主题下的立场

以下均为单一团队的自述经验，产品和仓库未公开，无第三方验证（[[2026-11-20-openai-harness-engineering]]）：

- **人类掌舵，智能体执行**：工程师不写代码，工作变成设计环境、明确意图、构建反馈回路。
- **仓库是唯一知识来源**：运行时上下文里访问不到的东西对 agent 等于不存在。
- **AGENTS.md 是地图不是手册**：约 100 行，只作目录；"一个巨大的 AGENTS.md"失败过（[[context-files]]、[[context-management]]）。
- **强制不变量而非微观管理**：用自定义 linter 和结构测试机械执行架构约束，lint 错误信息里直接写修复指引。
- **让应用对 agent 可读**：每个 worktree 一套临时可观测性栈，接入 Chrome DevTools Protocol（[[verification-and-observability]]）。
- **少设阻塞性合并门**：理由是"纠错成本低，等待成本高"；作者明说在低吞吐环境里这样做不负责任。
- **持续垃圾回收**：后台 agent 定期扫描偏差、发起重构 PR。

自述数据：约 100 万行代码、约 1,500 个 PR、起初 3 名工程师、约五个月；单次 Codex 运行常超过 6 小时（[[long-running-agents]]）（[[2026-11-20-openai-harness-engineering]]）。作者自己划了边界：端到端自主行为高度依赖该仓库的结构和工具，不应假定可泛化。

> [!warning] 矛盾
> "harness" 的所指：本文谈的是团队在 agent 之外搭建的仓库级环境（文档、lint、可观测性栈）（[[2026-11-20-openai-harness-engineering]]）；Microsoft 文档把 [[agent-harness|agent harness]] 定义为驱动模型和工具调用的运行时脚手架（[[2026-11-20-microsoft-learn-agent-harness]]）。两种用法需要分开。

> [!warning] 矛盾
> 质量门的松紧：本文主张少设合并门、flaky test 重跑（[[2026-11-20-openai-harness-engineering]]）；[[anthropic|Anthropic]] 的长时运行文章要求每个 session 留下干净状态、测试通过才标完成（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。前者是高吞吐多 agent 场景，后者是单 agent 串行场景。

## 影响

- [[learn-harness-engineering]] 课程自述以本文为理论来源之一（[[2026-11-20-learn-harness-engineering-course]]）。
- 与 Anthropic 独立得出相近结论：用仓库内版本化的工件传递跨 session 状态，给 agent 接浏览器做 UI 级验证（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- [[openharness|OpenHarness]] 支持 OpenAI 兼容 API 并桥接 Codex 订阅凭据（[[2026-11-20-openharness-readme]]）。
- [[learn-claude-code]] 的 README 把 OpenAI Five 作为"agency 来自训练"的历史里程碑引用（[[2026-11-20-learn-claude-code-readme]]）。

## 未解问题

- Codex 自身的运行时设计，本库无资料，见 [[codex]]。
- 文中数字没有成本、缺陷率等配套数据，"100 万行"包含文档和生成物（[[2026-11-20-openai-harness-engineering]]）。
