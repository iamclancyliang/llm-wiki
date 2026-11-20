---
title: MCP（Model Context Protocol）
type: concept
aliases: [Model Context Protocol, MCP server, MCP servers, MCP 工具, 模型上下文协议]
tags: [agent-harness, mcp, tools, protocol]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-context-management-in-claude-code
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-openharness-readme
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-openai-harness-engineering
---

# MCP（Model Context Protocol）

> 本批资料对 MCP 讲得不多：没有一份资料描述协议本身（消息格式、传输、能力协商），都只是从 harness 的角度提到它。本页只整理这些提法，不补充资料之外的内容。

## 定义

Model Context Protocol（MCP）在这些资料里的角色是：让 [[agent-harness|agent harness]] 用一种标准方式发现并调用外部 server 暴露的[[tools|工具]]。AI Harness Crash Course 的说法是"给应用一个标准方式去发现和调用 server 暴露的工具"（[[2026-11-20-ai-harness-crash-course]]）；learn-claude-code 网站的说法是"外部服务通过标准的发现与调用协议成为 agent 工具"（[[2026-11-20-learn-claude-code-site]]）。

## 要解决的问题和动机

- 工具不一定是 harness 进程里的一个函数。Crash Course 的例子：团队的构建日志在另一个服务里，MCP server 暴露一个取日志的工具，agent 就能排查失败的构建（[[2026-11-20-ai-harness-crash-course]]）。
- [[anthropic|Anthropic]] 的《Building effective agents》把 MCP 作为接入第三方工具生态的一种方式提到（[[2026-11-20-anthropic-building-effective-agents]]）。
- [[claude-code|Claude Code]] 官方课程把 MCP servers 定位为接入外部工具和数据源的定制手段，与 subagents、skills、hooks 并列（[[2026-11-20-claude-code-101-course]]）。
- learn-claude-code s14 的格言是 "Not enough capability? Plug in more via MCP"（[[2026-11-20-learn-claude-code-readme]]）。

## 工作原理（资料中出现的部分）

- **对循环来说只是多了一批工具**。learn-claude-code s14 的关键词是 tool discovery、带命名空间的工具、合并进同一个 tool pool；循环本身不变（README 只给了关键词，章节正文未摄入；[[2026-11-20-learn-claude-code-readme]]）。
- **harness 一侧是 MCP 客户端**。[[openharness|OpenHarness]] 有独立的 `mcp/` 子系统（"Model Context Protocol client"），工具清单里有 MCPTool、ListMcpResources、ReadMcpResource；v0.1.5（2026-04-08）自述增加 HTTP transport 和断线自动重连；插件可以携带 MCP servers；`--dry-run` 会检查 MCP 配置是否有明显问题而不实际连接 server（均为项目自述；[[2026-11-20-openharness-readme]]）。
- **一个实际用例**：Anthropic 的长时运行实验用 Puppeteer MCP server 给 agent 浏览器自动化能力，让它像人类用户一样做端到端测试并自己截图（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。这里 MCP 承担的是 [[verification-and-observability|验证]]工具的接入。

## 优缺点和权衡

- **context 代价**：Claude Code 官方视频说 MCP servers 默认把全部可用工具加载进 context，与项目无关的 server 可以关掉；并把 [[skills]] 描述为"与 MCP servers 类似，但不会把全部内容放进 context"（厂商自述，没有给出占用的数字；[[2026-11-20-context-management-in-claude-code]]）。也就是说，接得越多，留给任务的 context 越少，属于 [[context-management]] 要管的事。
- **工具能看到的有限**：长时运行实验里，Claude 通过 Puppeteer MCP 看不到浏览器原生 alert modal，依赖这类 modal 的 feature 因此 bug 更多（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。这是那个具体工具的盲区，不是协议的性质（后半句是笔者的判断）。
- 没有资料讨论 MCP server 的信任与安全问题。

## 不同来源的分歧

- **归在哪一层**。learn-claude-code 的 README 把 s14 MCP Plugin 放在"扩展与组装"阶段（[[2026-11-20-learn-claude-code-readme]]）；网站把 s19 MCP Tools 放在 "Multi-Agent Platform" 层而不是 "Tools & Execution" 层，来源页认为这个归类并不直观（[[2026-11-20-learn-claude-code-site]]）。OpenHarness 则同时把 MCP 列在 `tools/` 的工具类别和独立的 `mcp/` 子系统里（[[2026-11-20-openharness-readme]]）。
- **不用 MCP 也能接外部能力**。Crash Course 说工具可以是一个 Python 函数，也可以通过 MCP server 接入（[[2026-11-20-ai-harness-crash-course]]）。[[openai|OpenAI]] 团队给 [[codex|Codex]] 接浏览器时，文章描述的是把 Chrome DevTools Protocol 接入 agent 运行时并写 skills，全文没有提到 MCP（[[2026-11-20-openai-harness-engineering]]）；同样的浏览器验证需求，Anthropic 的实验用的是 MCP server。

## 谁支持，谁不提

| 项目 | 情况 | 来源 |
|---|---|---|
| [[claude-code\|Claude Code]] | 支持，官方课程有 MCP 专课（正文未摄入） | [[2026-11-20-claude-code-101-course]] |
| [[claude-agent-sdk\|Claude Agent SDK]] | 长时运行实验中使用了 Puppeteer MCP server | [[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]] |
| [[openharness\|OpenHarness]] | 内置 MCP 客户端（自述） | [[2026-11-20-openharness-readme]] |
| [[learn-claude-code]] | s14（README 轨道）/ s19（网站轨道）教学实现 | [[2026-11-20-learn-claude-code-readme]]、[[2026-11-20-learn-claude-code-site]] |
| [[deepseek-harness\|DeepSeek Harness]] | README 没有明文；commit 里有 `feat/mcp-tool-loading`、`feat/mcp-oauth` 分支名，据此推断支持 | [[2026-11-20-deepseek-harness-readme]] |
| [[pi\|Pi]] | README 没有提到，是否支持未知 | [[2026-11-20-pi-readme]] |
| [[microsoft-agent-framework\|Microsoft Agent Framework]] | Harness 概念页未提及，不能据此断定不支持 | [[2026-11-20-microsoft-learn-agent-harness]] |
| Go 练习仓库 | 明确没有 MCP | [[2026-11-20-harness-engineering-go-practice]] |

Crash Course 是在 Google ADK 的语境下提到 MCP 的（[[2026-11-20-ai-harness-crash-course]]）。

## 相关概念

[[tools]]、[[skills]]（按需加载，context 代价不同）、[[plugins-and-extensibility]]、[[context-management]]、[[verification-and-observability]]、[[agent-harness]]；横向比较见 [[开源-harness-设计取向对比]]。
