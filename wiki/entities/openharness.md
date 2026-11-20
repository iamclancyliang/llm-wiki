---
title: OpenHarness
type: entity
kind: project
aliases: [oh, ohmo, HKUDS OpenHarness]
tags: [agent-harness, open-source, python, coding-agent]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-openharness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
---

# OpenHarness

> [!note] 资料边界
> 唯一来源是 2026-11-20 导出的仓库首页（README + 页面元数据），不含源码。下文的能力描述除特别说明外都是**项目自述**，无法核实实现（[[2026-11-20-openharness-readme]]）。

## 是什么、解决什么问题

OpenHarness（命令 `oh`）是 HKUDS 用 Python 写的开源 [[agent-harness|agent harness]]，定位是让研究者和开发者看懂、实验、扩展生产级 agent 的内部结构。README 对 harness 的定义：模型提供智能，harness 提供"手、眼、记忆和安全边界"（[[2026-11-20-openharness-readme]]）。

它在格式和约定上贴近 [[claude-code|Claude Code]]：`CLAUDE.md` 注入、`SKILL.md`、`.claude-plugin/plugin.json` 插件、PreToolUse/PostToolUse hook、Plan Mode 都直接沿用。同时把 provider 抽象为带命名 profile 的 workflow，可在 Anthropic 兼容、OpenAI 兼容、Claude 订阅、[[codex|Codex]] 订阅、GitHub Copilot 之间切换（[[2026-11-20-openharness-readme]]）。

## 关键事实（2026-11-20 导出时的页面数据，[[2026-11-20-openharness-readme]]）

- 组织：HKUDS；自我定位 "community-driven research project"。
- 首次发布：v0.1.0，2026-04-01。最新 Release：v0.1.9（页面显示 "6 months ago"）。
- 许可证：MIT。语言：Python 94.1%、TypeScript 4.4%（TUI 前端）。
- Star 16.2k，Fork 2.6k，贡献者 53；429 次提交。
- 最新提交显示 "5 months ago"，导出时主分支约 5 个月没有更新。

## 工作原理概要

- **Agent loop**：`engine/` 实现 query → stream → tool-call → loop。README 的伪代码里停止条件只有一个：模型返回的 `stop_reason` 不是 `tool_use`；CLI 另有 `--max-turns`。每次工具调用的固定管线是"权限检查 → PreToolUse hook → 执行 → PostToolUse hook → 结果"，写在 loop 内。设计立场是"模型决定做什么，harness 负责怎么做"。见 [[agent-loop]]（[[2026-11-20-openharness-readme]]）。
- **Tools**：自述 43 个[[tools|工具]]，每个带 Pydantic 输入校验、JSON Schema、权限集成和 hook 支持；自定义工具继承 `BaseTool`（[[2026-11-20-openharness-readme]]）。
- **权限**：三种模式，Default（写和执行前询问）、Auto（全部放行，自述适用于沙箱环境）、Plan Mode（禁止一切写操作）；`settings.json` 可配 `path_rules` 和 `denied_commands`；另有 `--dangerously-skip-permissions`。见 [[permissions]]、[[planning-and-plan-mode]]（[[2026-11-20-openharness-readme]]）。
- **Hooks**：README 只列出 PreToolUse / PostToolUse 两个工具级生命周期 [[hooks]]（[[2026-11-20-openharness-readme]]）。
- **Skills 与插件**：[[skills]] 按需加载，发现路径覆盖 `~/.openharness/skills`、`~/.claude/skills`、`~/.agents/skills` 和项目级目录；项目级 skills 可用 `allow_project_skills false` 关闭。插件自述兼容 claude-code plugins。见 [[plugins-and-extensibility]]、[[mcp]]（`mcp/` 是 MCP 客户端）（[[2026-11-20-openharness-readme]]）。
- **上下文与记忆**：发现并注入 `CLAUDE.md`（[[context-files]]）；跨会话 [[memory]] 用 `MEMORY.md`；`prompts/` 负责 [[system-prompt|system prompt]] 组装；支持会话恢复（`--continue`、`--resume`），存储格式未说明（[[session-log]]）（[[2026-11-20-openharness-readme]]）。
- **Compaction**：v0.1.6 起的 Auto-Compact 自述"压缩时保留任务状态和 channel 日志，可以跑多天的会话而无需手动 compact/clear"；触发条件和摘要方式未说明。见 [[compaction]]、[[long-running-agents]]（[[2026-11-20-openharness-readme]]）。
- **多 agent**：`coordinator/` 提供 [[subagents|subagent]] 派生与团队协调（Swarm Coordination）；v0.1.6 自述 subprocess teammate 以 headless worker 运行；ClawTeam 集成仍在 Roadmap（[[2026-11-20-openharness-readme]]）。
- **其他**：自述有带指数退避的 API 重试（[[error-recovery]]）；非交互模式 `oh -p`；未发布的 `--dry-run` 做静态预览（[[verification-and-observability]]）（[[2026-11-20-openharness-readme]]）。

## ohmo

`ohmo` 是仓库里建立在 OpenHarness 之上的个人 agent 应用。`~/.ohmo/` 工作区含 `soul.md`、`identity.md`、`user.md`、`BOOTSTRAP.md`、`memory/`、`gateway.json`；通过 gateway 接入 Feishu / Slack / Telegram / Discord。自述能"自己开分支、写代码、跑测试、开 PR"，并复用已有的 Claude Code 或 Codex 订阅（[[2026-11-20-openharness-readme]]）。

## 优缺点与适用场景

- 适用（README 自述）：仓库内编码助手、headless 脚本工具、Claude 风格插件和 skill 的试验台、多 agent 原型（[[2026-11-20-openharness-readme]]）。
- 需谨慎（来源页的推断）：权限是应用层的模式加规则，README 没有描述内置沙箱（仅一条 commit 信息提到 `srt` 下的 sandbox），Auto 模式要自己配外部 [[sandboxing|沙箱]]；版本仍在 0.1.x 且主分支数月无提交（[[2026-11-20-openharness-readme]]）。
- 测试自述：114 个单元加集成测试和若干 E2E；没有任务成功率类的基准数据（[[2026-11-20-openharness-readme]]）。

> [!warning] 矛盾
> README 内部不一致（均见 [[2026-11-20-openharness-readme]]）：
> - 称"10 个子系统"，目录树实际列了 14 个目录。
> - 自述"并行工具执行"，而伪代码里是串行 `for`，两者如何对应没有说明。
> - "What's New" 只写到 v0.1.7，Releases 最新是 v0.1.9。
> - 插件自述"用 12 个官方插件测试过"，表格只列了 6 个。

> [!warning] 矛盾
> 关于 compaction 能否支撑长任务：OpenHarness 自述 Auto-Compact 让 agent"跑多天的会话"（无数据，[[2026-11-20-openharness-readme]]）；Anthropic 的实验观察是仅靠 compaction 不足以支撑跨多个 context window 的大型任务（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。两者的 harness、任务和证据强度都不同，不能直接判定谁对。

## 同类替代品

- [[pi|Pi]]：在权限系统、subagent、plan mode 三点上取向相反，Pi 明确不内置（[[2026-11-20-pi-readme]]）。
- [[deepseek-harness|DeepSeek Harness]]：其 loop 只管边界和日志，工具管线外包给工具服务；OpenHarness 把"权限 → hook → 执行 → hook"写在 loop 里（[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- [[claude-code|Claude Code]]：被兼容的对象。
- 完整对比见 [[开源-harness-设计取向对比]]。

## 演进时间线（README "What's New"，[[2026-11-20-openharness-readme]]）

- 2026-04-01 v0.1.0 首发。
- 2026-04-06 v0.1.2 统一 setup、ohmo 打包。
- 2026-04-08 v0.1.4 多 provider 认证、PermissionChecker 内置敏感路径保护；同日 v0.1.5 MCP HTTP transport、自动重连。
- 2026-04-10 v0.1.6 Auto-Compaction。
- 2026-04-18 v0.1.7 打包与 TUI 打磨。
- v0.1.9 为 Releases 页最新，日期只有相对时间。

## 未解问题

- Auto-Compaction 的触发阈值和摘要策略；多 agent 协调的协议和失败处理（[[2026-11-20-openharness-readme]]）。
- [[steering-and-cancel|插话与取消]]在 README 中完全没有提到（[[2026-11-20-openharness-readme]]）。
- 通过第三方 harness 复用 Claude Code / Codex 订阅凭据是否符合对应服务条款，README 没有讨论（[[2026-11-20-openharness-readme]]）。
- 活跃度回落的原因未知。
