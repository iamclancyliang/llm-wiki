---
title: Claude Code
type: entity
kind: project
aliases: [claude code, Claude Code CLI]
tags: [agent-harness, coding-agent, anthropic, claude-code]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-what-is-claude-code
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-context-management-in-claude-code
  - 2026-11-20-the-claude-md-file
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-openharness-readme
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-deepseek-harness-readme
---

# Claude Code

## 是什么、解决什么问题

Claude Code 是 [[anthropic|Anthropic]] 的 agentic coding tool：理解 codebase、编辑文件、运行命令，并与现有开发工具集成（厂商自述，[[2026-11-20-what-is-claude-code]]）。官方课程把它定位为"住在 terminal 里的 agentic coding tool"（[[2026-11-20-claude-code-101-course]]）。它与聊天产品 Claude.ai 的区别是能直接访问文件、terminal 和整个 codebase，不需要来回复制粘贴（[[2026-11-20-what-is-claude-code]]）。

在本 wiki 的主题下，它是被引用最多的 [[agent-harness|agent harness]] 实例：[[openharness|OpenHarness]] 沿用它的文件格式和约定（[[2026-11-20-openharness-readme]]），[[learn-claude-code]] 以它为逆向归纳的对象（[[2026-11-20-learn-claude-code-readme]]），[[learn-harness-engineering]] 把它当作要在仓库里为之搭环境的现成 agent（[[2026-11-20-learn-harness-engineering-course]]）。

> [!note] 资料边界
> 本库关于 Claude Code 的一手资料只有 7 份：Claude Academy 课程落地页和其中 6 课视频的自动转录，全部是入门级的厂商自述，没有源码、版本号、发布日期或任何数字。Installing Claude Code、Your first prompt、Code review、Subagents、Skills、MCP 六课正文未摄入（[[2026-11-20-claude-code-101-course]]）。

## 关键事实

- 组织：Anthropic（[[2026-11-20-claude-code-101-course]]）。
- 可用环境：terminal、VS Code、JetBrains IDEs、Claude desktop app、web（[[2026-11-20-claude-code-101-course]]；视频片头列 5 种，片尾 recap 漏了 web，见 [[2026-11-20-what-is-claude-code]]）。
- 使用条件：Claude 账号（Pro、Max、Ultra、Team 或 Enterprise）或 API key（[[2026-11-20-claude-code-101-course]]）。
- 首次发布、当前版本、许可证：资料未提及。

## 工作原理概要（Anthropic 官方说法）

以下各条均为官方入门课程的描述，没有实现细节。

- **Agentic loop**：[[agent-loop|agent loop]] 被描述为 gather context → take action → verify results；未达成目标就回到循环，直到结果"完整且可验证"。循环进行中用户可以随时补充 context、打断或 steer（[[steering-and-cancel]]）（[[2026-11-20-how-claude-code-works]]）。verify 被列为固定一步，但靠什么完成没有说明；另一课给出的手段是测试套件和 Claude in Chrome extension（[[verification-and-observability]]）（[[2026-11-20-explore-plan-code-commit-workflow]]）。
- **Tools**：[[tools]] 被称为"agent 工作方式的支柱"，举例 read file、search web（[[2026-11-20-how-claude-code-works]]）。
- **权限模式**：[[permissions]] 用 `Shift+Tab` 切换。默认模式下编辑文件或运行 shell 命令前要请求许可；auto accept 下编辑文件不再询问、运行命令仍询问；plan mode 只用 read-only tools，先产出计划（[[planning-and-plan-mode]]）（[[2026-11-20-how-claude-code-works]]）。
- **Context window 与 compaction**：到达上限时自动 [[compaction|compact]]，会总结重要细节、移除不必要的 tool call 结果，官方明确提醒可能丢失细节。手动命令有三个：`/compact`（压缩并保留对之前工作的记忆）、`/clear`（清空重来）、`/context`（查看占用）。这些属于 [[context-management]]（[[2026-11-20-context-management-in-claude-code]]）。
- **CLAUDE.md**：项目根目录的 markdown 文件，每次 session 启动时自动读取，内容"被 append 到你自己的 prompt 上"；`/init` 可生成；资料讲了 project level 和 user level 两层；可用 `@路径` 引用项目内文档。它是 [[context-files|context file]] 的代表，也承担跨 session 的 [[memory]] 角色（[[2026-11-20-the-claude-md-file]]）。注入位置是 [[system-prompt|system prompt]] 还是用户消息，资料没有区分（[[2026-11-20-the-claude-md-file]]）。
- **Hooks**：[[hooks]] 在 `settings.json` 中配置（event + 可选 matcher + command），也可用 `/hooks`。资料列出 5 个 event：`UserPromptSubmit`、`PreToolUse`、`PostToolUse`、`Notification`、`Stop`（规范写法是来源页根据转录读音还原的）。`PreToolUse` hook 从 stdin 收到 JSON 形式的 tool name 和 input；exit code `0` 放行，`2` 阻止并把 stderr 反馈给 Claude。项目级 settings 中的 hooks 可提交进 repo 供团队共享（[[2026-11-20-hooks-in-claude-code]]）。
- **Skills**：官方定位是"用于经常重复的任务或工作流"（[[2026-11-20-claude-code-101-course]]）；另一课说 [[skills]]"与 MCP servers 类似，但不会把全部内容放进 context"（[[2026-11-20-context-management-in-claude-code]]）。加载机制未说明。
- **MCP**：[[mcp|MCP]] servers 接入外部工具和数据源（[[2026-11-20-claude-code-101-course]]）；默认把全部可用 tools 加载进 context，无关的 server 建议关掉（[[2026-11-20-context-management-in-claude-code]]）。
- **Subagents**：[[subagents]] 与主 agent 并行运行，拥有完全独立的 context window，只把摘要返回主 agent（[[2026-11-20-context-management-in-claude-code]]）；官方推荐在提交前跑一个 subagent code reviewer（[[2026-11-20-explore-plan-code-commit-workflow]]）。
- **推荐工作流**：Explore → Plan → Code → Commit，核心主张是在写代码之前用 plan mode 纠偏，并在计划里写明什么算"正确"（[[2026-11-20-explore-plan-code-commit-workflow]]）。

> [!warning] 矛盾
> 权限模式的数量：课程落地页列**四种**（manual mode、auto-accept、auto mode、Plan Mode）（[[2026-11-20-claude-code-101-course]]）；第 2 课视频只讲**三种**（默认、auto accept、plan mode），没有 auto mode（[[2026-11-20-how-claude-code-works]]）。auto mode 与 auto-accept 的区别两处都没有说明。

> [!warning] 矛盾
> `CLAUDE.md` 指令的可靠性：CLAUDE.md 一课说把纠正保存到 memory 后 Claude "每次都会知道"（[[2026-11-20-the-claude-md-file]]）；hooks 一课明说写在 `CLAUDE.md` 里的指令只是"多数时候"被遵守，必须每次发生的事要放进 hook（[[2026-11-20-hooks-in-claude-code]]）。两者同为官方课程，后者的说法更保守。

## 第三方的逆向归纳（不是官方描述）

- **learn-claude-code 的拆解**：README 把 Claude Code 归纳为"一个 agent loop + 11 项机制"：工具（bash、read、write、edit、glob、grep、browser…）、按需加载 skill、context compaction、subagent、带依赖图的 task system、异步 mailbox 团队协作、绑定任务的 worktree、权限治理、hooks、memory 持久化、MCP 外部能力路由。来源页明确这是作者归纳，是否与实际实现一致无法证明（[[2026-11-20-learn-claude-code-readme]]）。配套网站把同一思路表述为"所有 AI 编程 Agent 共享同一个循环，生产级系统在其上叠加策略、权限和生命周期层"（[[2026-11-20-learn-claude-code-site]]）。
- 同一 README 称 Claude Code 是"最优雅、最完整的 agent harness 实现"，理由是它不替模型做决策、不强加固定工作流。这是作者评价，不是比较实验的结论（[[2026-11-20-learn-claude-code-readme]]）。
- **OpenHarness 的兼容面**：OpenHarness 沿用 `CLAUDE.md` 注入、`SKILL.md`、`.claude-plugin/plugin.json` 插件、PreToolUse/PostToolUse hook、Plan Mode，并读取 `~/.claude/.credentials.json` 桥接订阅（项目自述，[[2026-11-20-openharness-readme]]）。这从侧面说明这些格式已被当作事实约定，但不能反推 Claude Code 的内部实现（后半句是推断）。
- [[deepseek-harness|DeepSeek Harness]] 仓库的 `CLAUDE.md` 是指向 `AGENTS.md` 的 symlink（[[2026-11-20-deepseek-harness-readme]]）。

## 与 Claude Agent SDK 的关系

资料没有正面说明两者的关系。唯一线索：Anthropic 的长时运行文章以 [[claude-agent-sdk|Claude Agent SDK]] 为 harness 做实验，致谢中提到 Claude Code 团队参与（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。详见 [[claude-agent-sdk]]。

## 优缺点与适用场景

- 优点（厂商自述）：直接在 codebase 里行动并验证自己的工作；监督程度可通过权限模式选择（[[2026-11-20-how-claude-code-works]]）。
- 官方自己承认的局限：会犯错（误解意图、引入 bug、overengineer）（[[2026-11-20-what-is-claude-code]]）；context window 有限，自动 compaction 会丢细节（[[2026-11-20-context-management-in-claude-code]]）；prompt 级指令不保证执行（[[2026-11-20-hooks-in-claude-code]]）。
- 资料没有任何任务成功率或基准数据。

## 同类替代品

- [[codex|Codex]]（OpenAI 的 coding agent）（[[2026-11-20-learn-harness-engineering-course]]）。
- 开源 harness：[[openharness|OpenHarness]]（格式兼容取向）、[[pi|Pi]]（最小核心取向）、[[deepseek-harness|DeepSeek Harness]]（一切皆插件取向）。对比见 [[开源-harness-设计取向对比]]。

## 演进时间线

资料未提及 Claude Code 自身的版本历史。

## 未解问题

- auto mode 是什么（[[2026-11-20-claude-code-101-course]]）。
- 视频称 Claude Code "uses semantic searching to determine when to call a tool"，只有一句、没有机制解释，含义不明，不宜引用为事实（[[2026-11-20-how-claude-code-works]]）。
- `CLAUDE.md` 是否有更多层级、冲突时的优先级（[[2026-11-20-the-claude-md-file]]）。
- 5 个 hook event 是否为全集；hook 以非 0 非 2 的 exit code 失败时的行为（[[2026-11-20-hooks-in-claude-code]]）。
- `/compact` 之后保留了什么、丢了什么（[[2026-11-20-context-management-in-claude-code]]）。
- 是否有 [[sandboxing|sandbox]]、[[session-log|session log]] 的存储方式、[[error-recovery|错误恢复]]策略：本库的官方资料均未提及。
