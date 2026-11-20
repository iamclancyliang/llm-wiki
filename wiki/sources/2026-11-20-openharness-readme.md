---
title: OpenHarness README（HKUDS/OpenHarness 仓库首页）
type: source
kind: repo
aliases: [OpenHarness README, oh, ohmo]
tags: [agent-harness, repo, python, open-source, coding-agent]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/github-hkuds-openharness.md
author: HKUDS
published: 2026-04-01
url: https://github.com/HKUDS/OpenHarness
---

# OpenHarness README（HKUDS/OpenHarness 仓库首页）

> 资料性质：GitHub 仓库首页导出的纯文本（README + 页面元数据），导出日期 2026-11-20。`published` 填的是 README 中 v0.1.0 首次开源发布的日期。下文凡涉及能力和优势的描述，除特别说明外都是**项目自述**，本资料不含源码，无法核实实现。

## 一段话概括

[[openharness|OpenHarness]]（命令 `oh`）是 HKUDS 用 Python 写的开源 [[agent-harness|agent harness]]（包裹在 LLM 外面、让它成为可用 agent 的全部基础设施），定位是"让研究者和开发者看懂、实验、扩展生产级 agent 的内部结构"。它在格式和约定上高度贴近 [[claude-code|Claude Code]]：`CLAUDE.md` 注入、`SKILL.md` 技能、`.claude-plugin` 插件、PreToolUse/PostToolUse hook、Plan Mode 都直接沿用。仓库里还附带一个建立在它之上的个人 agent 应用 `ohmo`，通过 Feishu / Slack / Telegram / Discord 接收任务并长时间自主工作。

## 解决什么问题

- README 对 agent harness 的定义：模型提供智能，harness 提供"手、眼、记忆和安全边界"；结尾口号是 "The model is the agent. The code is the harness."
- 目标人群是研究者、构建者和社区，四个用途：理解生产级 agent 如何运作、实验工具/技能/多 agent 协作模式、用插件和 provider 扩展、在"已被验证的架构"上构建专用 agent（"已被验证"是自述）。
- 同时解决"模型供应商绑定"：把 provider 抽象为带命名 profile 的 workflow，可在 Anthropic 兼容、OpenAI 兼容、Claude 订阅、[[codex|Codex]] 订阅、GitHub Copilot 之间切换。

## 架构与关键设计决策

### 模块划分

README 称"10 个子系统"，但给出的目录树实际列了 14 个目录（见"局限与遗留问题"）：

| 目录 | 职责（README 原注释） |
|---|---|
| `engine/` | [[agent-loop\|agent loop]]：query → stream → tool-call → loop |
| `tools/` | 43 个[[tools\|工具]]：文件 I/O、shell、搜索、web、MCP |
| `skills/` | 按需加载的 [[skills]]（`.md` 文件） |
| `plugins/` | 扩展：commands、hooks、agents、MCP servers（见 [[plugins-and-extensibility]]） |
| `permissions/` | [[permissions\|权限]]：多级模式、路径规则、命令黑名单 |
| `hooks/` | 生命周期 [[hooks]]：PreToolUse / PostToolUse |
| `commands/` | 54 个斜杠命令（/help、/commit、/plan、/resume…） |
| `mcp/` | [[mcp\|MCP]]（Model Context Protocol）客户端 |
| `memory/` | 跨会话持久记忆（`MEMORY.md`） |
| `tasks/` | 后台任务管理 |
| `coordinator/` | 多 agent：[[subagents\|subagent]] 派生、团队协调 |
| `prompts/` | [[system-prompt\|system prompt]] 组装、`CLAUDE.md`、skills |
| `config/` | 多层配置与迁移 |
| `ui/` | React/Ink TUI：后端协议 + 前端 |

数据流（README 的 flowchart）：User Prompt → CLI 或 React TUI → RuntimeBundle → QueryEngine → API Client →（`tool_use`）→ Tool Registry → Permissions + Hooks → Files/Shell/Web/MCP/Tasks → 回到 QueryEngine。

### Agent loop

README 给出的是示意伪代码，不是源码（出处：README "The Agent Loop" 一节）：

```python
while True:
    response = await api.stream(messages, tools)
    if response.stop_reason != "tool_use":
        break  # Model is done
    for tool_call in response.tool_uses:
        # Permission check → Hook → Execute → Hook → Result
        result = await harness.execute_tool(tool_call)
    messages.append(tool_results)
```

- 停止条件只有一个：模型返回的 `stop_reason` 不是 `tool_use`。CLI 另有 `--max-turns` 作为外部上限。
- 每次工具调用的固定管线是"权限检查 → PreToolUse hook → 执行 → PostToolUse hook → 结果"。
- 自述的 loop 特性：流式 tool-call 循环、带指数退避的 API 重试（见 [[error-recovery]]）、并行工具执行、token 计数与成本跟踪。伪代码里是串行 `for`，与"并行工具执行"的说法如何对应，README 没有说明。
- 设计立场："模型决定做什么（what），harness 负责怎么做（how）——安全、高效、可观测。"

### 工具、技能、插件

- 每个工具有四样东西：Pydantic 输入校验、自描述 JSON Schema、权限集成（每次执行前检查）、hook 支持。自定义工具继承 `BaseTool`，声明 `name` / `description` / `input_model`，实现 `async execute(arguments, context) -> ToolResult`。
- 工具清单覆盖文件（Bash/Read/Write/Edit/Glob/Grep）、搜索（WebFetch/WebSearch/ToolSearch/LSP）、Agent/SendMessage/TeamCreate、Task*、MCP、模式切换（EnterPlanMode/ExitPlanMode/Worktree）、调度（Cron*/RemoteTrigger）、元工具（Skill/Config/Brief/Sleep/AskUser）——命名与 Claude Code 的工具集基本对应（这一对应关系是我的观察，README 未明说）。
- Skills 是"按需知识"，模型需要时才加载。发现路径同时覆盖 `~/.openharness/skills`、`~/.claude/skills`、`~/.agents/skills` 以及项目级同名目录（从 cwd 向上找到 git root）。项目级 skills 默认启用，对不可信仓库可用 `oh config set allow_project_skills false` 关闭——这是把 skills 当作攻击面处理的一个具体设计。
- 插件自述"兼容 claude-code plugins，用 12 个官方插件测试过"（表格只列了 6 个：commit-commands、security-guidance、hookify、feature-dev、code-review、pr-review-toolkit）。插件清单文件是 `.claude-plugin/plugin.json`，可带 `commands/*.md`、`hooks/hooks.json`、`agents/*.md`。

### 上下文与记忆

- [[context-files|上下文文件]]：发现并注入 `CLAUDE.md`；持久记忆用 `MEMORY.md`；支持会话恢复与历史（`-c/--continue`、`-r/--resume`、`/resume`），对应 [[session-log]] 一类机制，但 README 没讲存储格式。
- [[compaction|上下文压缩]]（Auto-Compact）：v0.1.6（2026-04-10）起自述"压缩时保留任务状态和 channel 日志，agent 可以跑多天的会话而无需手动 compact/clear"。这是它对 [[long-running-agents|长时间运行 agent]] 的主要回答，属于 [[context-management]] 的范畴；压缩触发条件和摘要方式 README 未说明。

### 治理

- 三种权限模式：Default（写和执行前询问）、Auto（全部放行，自述适用于沙箱环境）、Plan Mode（禁止一切写操作，用于大型重构先审后做）。
- `settings.json` 里可配 `path_rules`（如 `/etc/*` 拒绝）和 `denied_commands`（如 `rm -rf /`）。v0.1.4 自述在 PermissionChecker 内置了敏感路径保护。
- `web_search` / `web_fetch` 保持 `trust_env=False` 以防 SSRF，不自动继承 `HTTP_PROXY`；需要代理时显式设 `OPENHARNESS_WEB_PROXY`，且 URL 不能内嵌凭据。
- `--dangerously-skip-permissions` 作为 CLI 开关存在。

### 多 agent 与 ohmo

- "Swarm Coordination"：subagent 派生与委派、team registry、后台任务生命周期；v0.1.6 自述 subprocess teammate 以 headless worker 模式运行。ClawTeam 集成标注为 Roadmap（未完成）。
- `ohmo`：`~/.ohmo/` 工作区含 `soul.md`（长期人格与行为）、`identity.md`、`user.md`（用户画像）、`BOOTSTRAP.md`（首次运行仪式）、`memory/`、`gateway.json`。通过 gateway 接入聊天渠道，自述能"自己开分支、写代码、跑测试、开 PR"，并且"复用已有的 Claude Code 或 Codex 订阅，无需额外 API key"。

### 可观测与可脚本化

- 非交互模式 `oh -p`，输出格式 `text | json | stream-json`。
- `--dry-run`（Unreleased）：静态预览，不调用模型、不执行工具、不派生 subagent、不连接 MCP server，只解析设置、认证状态、prompt 组装、skills、命令、工具，给出 `ready / warning / blocked` 结论和下一步建议。这是 [[verification-and-observability|验证与可观测性]] 上比较少见的一个设计。

## 值得记下的数据和论据

- 测试自述：114 个单元+集成测试、6 个 CLI flag E2E（真实模型调用）、9 个 harness 特性 E2E（重试、skills、并行、权限）、3 个 React TUI E2E、4 个 TUI 交互 E2E、12 个真实 skills+plugins 测试。没有给出任务成功率类的基准数据。
- 版本时间线（README "What's New"）：v0.1.0（2026-04-01，首发）→ v0.1.2（2026-04-06，统一 setup、ohmo 打包）→ v0.1.4（2026-04-08，多 provider 认证、Moonshot/Kimi）→ v0.1.5（2026-04-08，MCP HTTP transport、自动重连）→ v0.1.6（2026-04-10，Auto-Compaction）→ v0.1.7（2026-04-18，打包与 TUI 打磨）。

## 适用与不适用场景

适用（README "Showcase" 自述）：仓库内编码助手；headless 脚本工具；Claude 风格插件和 skill 的试验台；多 agent 原型；在多个 Anthropic 兼容后端之间做对比的沙箱。

不适用或需谨慎（我的推断，依据见后）：

- 需要强隔离的场景：权限是应用层的模式 + 规则，README 没有描述内置沙箱（仅一条 commit 信息提到 `srt` 下的 sandbox），Auto 模式"全部放行"要自己配外部沙箱。
- 需要长期稳定 API 的生产依赖：版本仍在 0.1.x，且导出时主分支已数月没有新提交。

## 成熟度（2026-11-20 导出时的页面数据）

- 许可证 MIT；语言 Python 94.1%、TypeScript 4.4%（TUI 前端）。
- Star 16.2k，Fork 2.6k，Watcher 89；Issues 33，Pull requests 71；贡献者 53。
- 429 次提交，14 个分支，4 个 tag；Releases 4 个，最新 v0.1.9（"Skill Workflows and Provider Key Updates"，页面显示"6 months ago"）。
- 最新提交显示"5 months ago"——即导出时主分支约 5 个月没有更新，活跃度明显回落（相对时间，具体日期资料中没有）。
- 自我定位是 "community-driven research project"。

## 与已有知识的关系

- 这是 wiki 的首批资料之一，暂无可印证或矛盾的既有页面。
- 与同批的 Pi README 形成直接对照：OpenHarness 内置权限系统、subagent、Plan Mode；Pi 明确不内置这三样。与 [[deepseek-harness|DeepSeek Harness]] 的对照是：OpenHarness 用固定的子系统目录 + Claude 兼容格式，DeepSeek Harness 走"一切皆插件"。
- 它直接读取 `~/.claude/.credentials.json` 和 `~/.codex/auth.json` 来桥接 [[anthropic|Anthropic]] 和 [[openai|OpenAI]] 的订阅，说明其生态位是"兼容层"而非独立标准。

## 局限与遗留问题

- **README 内部不一致**：称"10 个子系统"但目录树列出 14 个目录；工具数"43"与"43+"并存；自定义 skill 示例路径是 `~/.openharness/skills/my-skill.md`，而前文约定的布局是 `<skill>/SKILL.md`；flowchart 只画了 "Anthropic-compatible API Client"，但同时支持 OpenAI 兼容格式。
- "What's New" 只写到 v0.1.7，而 Releases 最新是 v0.1.9，README 落后于发布。
- Auto-Compaction 的触发阈值、摘要策略、"保留任务状态"的具体形式都没有说明；"多天会话"没有数据支撑。
- 取消与插话（[[steering-and-cancel]]）在 README 中完全没有提到。
- 通过第三方 harness 复用 Claude Code / Codex 订阅凭据是否符合对应服务条款，README 没有讨论。
- 多 agent 协调（team registry、SendMessage）的协议和失败处理没有细节；ClawTeam 集成仍在 Roadmap。
- 要核实以上自述，需要摄入 `engine/`、`permissions/` 的源码和 `CHANGELOG.md`。
