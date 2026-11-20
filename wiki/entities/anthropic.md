---
title: Anthropic
type: entity
kind: org
aliases: [Anthropic PBC, Claude Academy]
tags: [org, agent-harness, claude-code]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-openharness-readme
---

# Anthropic

## 是什么

Claude 系列模型的开发公司。在本 wiki 的主题下，它既是 [[agent-harness|agent harness]] 产品的提供方（[[claude-code|Claude Code]]、[[claude-agent-sdk|Claude Agent SDK]]），也是两篇被广泛引用的工程文章的作者。本页只记它在这个主题下的立场与产出。

## 产出

- **文章《Building effective agents》**（2024-12-19，Erik S.、Barry Zhang）：提出 workflows 与 agents 的区分（[[workflows-vs-agents]]）、五种 workflow 模式、agent-computer interface（ACI）的工具设计原则（[[tools]]）。全文没有出现 "harness" 一词。页面在首发后被修订过，顶部说明称当前做法见 Claude Managed Agents（[[2026-11-20-anthropic-building-effective-agents]]）。
- **文章《Effective harnesses for long-running agents》**（2025-11-26，Justin Young）：用 initializer agent 与 coding agent 两种 prompt，加上 feature list、进度文件、git 和端到端测试，解决跨 context window 的 [[long-running-agents|长时运行]]问题（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **产品**：Claude Code（agentic coding tool）；Claude Agent SDK（文中称为"通用的 agent harness"）（[[2026-11-20-claude-code-101-course]]、[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **课程 Claude Academy**：Claude Code 101，12 课、1.5 小时、1 个测验、结业徽章；页脚 "© 2026 Anthropic PBC"，无发布日期。本库摄入了落地页和其中 6 课的视频转录（[[2026-11-20-claude-code-101-course]]）。

## 在本主题下的立场

以下是从两篇文章和课程中读出的主张，均为作者主张或内部经验，没有对照实验：

- **简单优先**：最成功的实现用简单、可组合的模式而非复杂框架；先直接用 LLM API（[[2026-11-20-anthropic-building-effective-agents]]）。
- **agent 就是循环里用工具的 LLM**：每一步要从环境拿到 ground truth，并设停止条件（[[agent-loop]]）（[[2026-11-20-anthropic-building-effective-agents]]）。
- **工具接口值得与 prompt 同等的投入**：SWE-bench agent 的绝对路径案例（[[2026-11-20-anthropic-building-effective-agents]]）。
- **长任务靠环境里的工件，不靠改 harness**：harness、[[system-prompt|system prompt]] 和工具集不变，状态放在工作目录的普通文件里；[[compaction]] 本身不够（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **验证要像人类用户那样做**：浏览器端到端测试（[[verification-and-observability]]）（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- **必须每次发生的事放进 hook，不放进 prompt**：[[hooks]] 是 deterministic 的（[[2026-11-20-hooks-in-claude-code]]）。

> [!warning] 矛盾
> 质量门的松紧：Anthropic 的长时运行文章要求每个 session 留下可合并的干净状态、测试通过才标完成（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；[[openai|OpenAI]] 的文章主张减少阻塞性合并门、flaky test 重跑了事（[[2026-11-20-openai-harness-engineering]]）。场景不同（单 agent 串行对高吞吐多 agent），来源页认为不一定是直接矛盾。

## 影响

- [[learn-harness-engineering]] 课程自述以它的长时运行文章为理论来源之一（[[2026-11-20-learn-harness-engineering-course]]）；Go 练习仓库的长任务部分注明做法来自同一篇文章（[[2026-11-20-harness-engineering-go-practice]]）。
- [[openharness|OpenHarness]] 沿用 Claude Code 的文件格式并桥接 Claude 订阅凭据（[[2026-11-20-openharness-readme]]）。
- 与 OpenAI 独立得出相近结论：进度写进仓库、让 agent 亲眼看运行结果（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。

## 未解问题

- 劝人少用框架与自家发布 Claude Agent SDK 之间的关系，见 [[claude-agent-sdk]]。
- Claude Managed Agents 是什么，本库无资料（[[2026-11-20-anthropic-building-effective-agents]]）。
- 课程所述《Harness design for long-running application development》一文未收录（[[2026-11-20-learn-harness-engineering-course]]）。
