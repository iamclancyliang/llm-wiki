---
title: DeepSeek Harness README（deepseek-ai/deepseek-harness 仓库首页）
type: source
kind: repo
aliases: [DeepSeek Harness README, dsh]
tags: [agent-harness, repo, typescript, open-source, plugin-architecture]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/github-deepseek-harness.md
author: DeepSeek-AI
published:
url: https://github.com/deepseek-ai/deepseek-harness
---

# DeepSeek Harness README（deepseek-ai/deepseek-harness 仓库首页）

> 资料性质：GitHub 仓库首页导出的纯文本，导出日期 2026-11-20。README 本身很短（定位、运行方式、社区、引用格式），**几乎不含架构说明**；架构细节在它指向的 `docs/architecture.md` 和文档站里，这两者都不在本资料中。因此本页分三层标注：README 明文、从文件列表和 commit 信息得到的**推断**、缺失信息。`published` 资料中找不到明确日期，留空。

## 一段话概括

[[deepseek-harness|DeepSeek Harness]]（命令 `dsh`）是 DeepSeek AI 开源的 [[agent-harness|agent harness]]，核心主张只有一句："Everything is a Plugin"（一切皆插件）。它构建在 Cordis 之上，README 把 Cordis 的设计指向一篇论文《A Programming Paradigm for Spatiotemporal Composability》（arXiv:2608.25512）。项目处于 developer preview，以 Web UI 为主要入口（`npx @deepseek-ai/dsh web`），README 用大写明确警告会有破坏兼容性的变更。

## 解决什么问题

README 没有正面写"要解决什么问题"，只给出定位：一个开源 agent harness，架构原则是一切皆插件。可以确认的只有：

- 它想让 harness 的每一块能力都以插件形态存在并可被第三方替换或扩展——README 号召插件作者给仓库加 `dsh-plugin` topic 以便被发现（见 [[plugins-and-extensibility]]）。
- 它把自己作为可被学术引用的工作（给了 BibTeX：`DeepSeek Harness: Everything is a Plugin`，author DeepSeek-AI，year 2026）。

"为什么一切皆插件比固定子系统更好"的理由，README 没有给出，只把论证外包给了 Cordis 论文。

## 架构与关键设计决策

### README 明文

- **一切皆插件 + Cordis**：harness 由 Cordis 驱动。论文标题中的 "Spatiotemporal Composability"（时空可组合性）README 未解释。结合同批资料 agent loop 源码中的用法（从 `@deepseek-ai/cordis` 导入 `Context`，通过 `loopCtx.tools`、`loopCtx.llm`、`loopCtx.systemPrompt` 取服务，注册作用域由生命周期所有者统一回收），可以**推断**："空间"指上下文/作用域的层级隔离，"时间"指注册的副作用随生命周期可逆地卸载。这是推断，待读论文确认。
- **Web UI 优先**：`dsh web` 默认在 `http://127.0.0.1:3080` 启动并打开浏览器；通过 SSH 启动时只打印 URL（因为转发地址归 SSH 客户端或编辑器所有）；`--no-open` 只起服务不开浏览器。
- **分发**：npm 包 `@deepseek-ai/dsh`；从源码运行用 pnpm（`pnpm install && pnpm run build && pnpm dsh web`），`pnpm dsh web` 只使用已构建产物、不会重新构建；`pnpm run dev:web` 一个终端里完成构建、服务和热重建；`make help` 列出 Web 与 Desktop 的 Make 目标。
- **面向 agent 的入口**："For agents, follow AGENTS.md."——仓库把 [[context-files|上下文文件]] `AGENTS.md` 当作一等入口；文件列表显示 `CLAUDE.md` 是首个提交里创建的指向 `AGENTS.md` 的 symlink（commit 信息："Initialize repo with README, AGENTS.md, and CLAUDE.md symlink"）。
- **安全**：运行前要求先读 `SAFETY.md`（内容不在资料中）。

### 从文件列表和 commit 信息推断的结构（均为推断）

| 线索 | 推断 |
|---|---|
| 顶层目录 `apps/`、`packages/`、`native/`、`python/`、`vendor/`、`website/`、`benchmarks/`、`snapshots/`、`patches/` | pnpm monorepo；`packages/core/agent-loop` 是其中一个包（由同批源码资料的路径确认） |
| 语言占比 TypeScript 95.5%，另有 Swift 0.6%、C# 0.3%、Python 1.1% | 主体是 TypeScript；`native/` 可能是 macOS / Windows 桌面壳；`python/` 提供 Python 运行时 wheel（commit："support macOS x64 runtime wheels"） |
| `vendor/` 的 commit："chore(cordis): backport … from upstream" | Cordis 是外部上游项目（cordiverse/cordis），本仓库 vendoring 并回移补丁 |
| commit 中的 `feat/mcp-tool-loading`、`feat/mcp-oauth` | 支持 [[mcp\|MCP]]，且在做工具加载和 OAuth |
| `feat/subagent-names`、`feat/upstream-skills`、`.agents/` 目录 | 有 [[subagents\|subagent]] 和 [[skills]] 机制 |
| "adapt packed pages to session journal"、`feat/session-worksp…` | 会话以 journal（日志）形式持久化，对应 [[session-log]]；与 agent loop 源码"每个请求都从 session log 派生"一致 |
| "sync the recent-view limit from the Host Config"、"run fixture browser cases through Host"、`tsconfig.host.json` / `tsconfig.client.json` | 进程模型分 Host 与 Client 两侧，Client bundle 分别为 Node 和浏览器构建 |
| "docs: … two ADRs, review skill"、`.claude/` 目录 | 项目用 ADR 记录架构决策，并用 agent（含 review skill）参与自身开发 |
| 多个 `vitest.*.config.ts`（e2e、snapshot、expected、web、web-stress、web.perf、bench）与 `BENCHMARK.md` | 测试分层较细，有快照测试和性能/压力测试；基准内容未知 |
| 分支名 `codex/add-security-policy`、`codex/trim-ai-prose`、`worktree-sync-release-…` | 开发流程中大量使用编码 agent 和 git worktree |

### 设计取向小结

与同批的 [[openharness|OpenHarness]] 相比，DeepSeek Harness 不在 README 里罗列"内置了多少工具、多少命令"，而是把可组合的插件运行时当作产品本身。agent loop 也只是 `packages/core/` 下的一个包、通过事件和服务与其他插件协作（细节见同批来源页 `2026-11-20-deepseek-harness-agent-loop-source`）。

## 适用与不适用场景

适用（推断，README 未列举）：

- 想研究或二次开发"插件化 harness 运行时"的人；想在 Web UI 而不是终端里使用 agent 的人。
- 愿意跟随快速迭代的早期采用者。

不适用（有 README 依据）：

- 需要稳定接口的生产集成：developer preview，"THERE WILL BE COMPATIBILITY-BREAKING CHANGES"。
- 只读 README 就想上手架构的人：README 不讲架构，必须读 `docs/architecture.md`、`docs/development.md` 和文档站。

## 成熟度（2026-11-20 导出时的页面数据）

- 阶段：developer preview；commit 信息中出现 `0.2.2-rc.4`（"chore(release): sync release/dsh-0.2.2 0.2.2-rc.4 to master"），即导出时处于 0.2.x 候选版本。
- 许可证 MIT（commit："Adopt MIT for DSH packages"，页面显示"3 months ago"）；第三方依赖许可证见 `THIRD_PARTY_NOTICES.md`。
- Star 283.3k，Fork 35.1k，Watcher 1.2k；贡献者 54。
- 28,026 次提交，1 个分支（master），41 个 tag；页面未显示正式 Release 数，只显示 41 tags。
- 最新提交显示"17 hours ago"，非常活跃。最早的文件提交显示"5 months ago"（初始化 README/AGENTS.md），据此**推断**仓库公开历史约 5 个月——5 个月 2.8 万次提交，开发节奏极快（很可能有大量 agent 生成的提交，这是推断）。
- 仓库没有 Issues 页签，反馈和 bug 报告统一走 GitHub Discussions；另有 Discord 社区。PR 编号也链接到 discussions 路径。

## 值得记下的数据和论据

- 默认端口 3080，绑定 `127.0.0.1`（默认只监听本机）。
- Cordis 论文编号 arXiv:2608.25512（按编号规则对应 2026-08，推断）。
- 文档站：`https://deepseek-harness.github.io/deepseek-harness/`；产品页 `deepseek.com/harness`。

## 与已有知识的关系

- 补充：同批的 agent loop 源码页给出了这个仓库唯一可核实的实现细节，两页应一起读。
- 对照：[[pi|Pi]] 同样强调"最小核心 + 扩展"，但 Pi 的 README 明说哪些能力故意不做；DeepSeek Harness 的 README 不做这类取舍声明。
- 与 [[harness-engineering]] 的关系：仓库自身用 `AGENTS.md`、ADR、review skill 来约束 agent 开发，是"用 harness 开发 harness"的一个实例（推断）。

## 局限与遗留问题

- README 信息量很低：没有架构图、没有模块清单、没有权限模型说明、没有与其他 harness 的对比，也没有任何性能或任务成功率数据。本页"架构"部分大半是推断，应在摄入 `docs/architecture.md` 后重写。
- "一切皆插件"的边界在哪里（agent loop、session、LLM 适配器是否都可替换）？插件之间的依赖和隔离如何保证？需要读 Cordis 论文和架构文档。
- `SAFETY.md` 的内容未知：[[permissions|权限]]与沙箱模型在本资料中完全空白。
- 是否只支持 DeepSeek 模型？README 没说；agent loop 源码中 provider/model 是通用的 selection，推断为多 provider，但未证实。
- `BENCHMARK.md` 测的是什么、结果如何，未知。
- Star 数（283.3k）相对约 5 个月的公开历史非常高，本资料无法解释原因，引用时只应作为"导出时页面数据"。
