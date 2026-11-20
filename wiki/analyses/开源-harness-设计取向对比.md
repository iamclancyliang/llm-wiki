---
title: 开源 harness 设计取向对比
type: analysis
aliases: [OpenHarness vs DeepSeek Harness vs Pi vs Microsoft Agent Framework vs Claude Code, harness 设计取向对比]
tags: [agent-harness, comparison, open-source, design]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-openharness-readme
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-pi-readme
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-what-is-claude-code
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-context-management-in-claude-code
  - 2026-11-20-the-claude-md-file
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-learn-claude-code-readme
---

# 开源 harness 设计取向对比

## 回答的问题

[[openharness|OpenHarness]]、[[deepseek-harness|DeepSeek Harness]]、[[pi|Pi]]、[[microsoft-agent-framework|Microsoft Agent Framework]] 的 harness，以及 [[claude-code|Claude Code]]，在设计取向上有何不同？

## 结论

五者都围绕同一个 [[agent-loop|agent loop]]，分歧在于**哪些能力由 harness 内置、loop 自己管多少、安全边界画在哪里**。按资料可以归为五种取向：

1. **Claude Code：产品化的全内置。** 权限模式、plan mode、compaction、subagents、hooks、skills、MCP 都作为产品功能提供，用户通过模式切换和配置文件调节监督程度。它是其余几者的参照物，但本库只有入门级的厂商自述，没有实现资料。
2. **OpenHarness：兼容复刻。** 把 Claude Code 的格式和约定当作事实标准照搬，再加 provider 切换和多 agent 协调。工具管线（权限 → hook → 执行 → hook）写在 loop 里。
3. **Pi：最小核心，能力外置。** 明确不内置权限系统、subagent、plan mode；安全边界交给容器或 micro-VM，功能交给 extension 和 package。
4. **DeepSeek Harness：一切皆插件。** 连 loop 都只是一个包。从源码看，loop 只负责 turn/step 边界、输入队列、日志一致性和取消，重试、步数上限、压缩、权限都在 loop 之外。
5. **Microsoft Agent Framework Harness：默认值的组合。** 不另造运行时，把框架已有构件按一套带取向的默认值组装；todo、plan/execute 模式、审批、遥测默认开启，逐项可关可换。

一句话：Claude Code 和 OpenHarness 把策略放进 harness；Pi 把策略推给用户和外部环境；DeepSeek Harness 把策略推给插件；Microsoft 把策略做成可替换的默认 provider。

**证据强度很不均衡**：只有 DeepSeek Harness 有一个源码文件可核实，其余四者全部是 README 或文档自述。下表的差异有一部分是"资料讲了什么"的差异，不一定是"系统做了什么"的差异。

## 对比表

依据标注：每列默认依据见表头下一行；单元格内的方括号是例外或补充依据，对照下方图例。"资料未提及"表示本库资料中找不到，不表示该系统没有。

图例：

- 〔OH〕[[2026-11-20-openharness-readme]]（项目自述）
- 〔DR〕[[2026-11-20-deepseek-harness-readme]]（README 明文很少，多为来源页推断）
- 〔DL〕[[2026-11-20-deepseek-harness-agent-loop-source]]（源码，可核实）
- 〔PI〕[[2026-11-20-pi-readme]]（项目自述）
- 〔MS〕[[2026-11-20-microsoft-learn-agent-harness]]（厂商文档）
- 〔C101〕[[2026-11-20-claude-code-101-course]]、〔Cwhat〕[[2026-11-20-what-is-claude-code]]、〔Chow〕[[2026-11-20-how-claude-code-works]]、〔Cepcc〕[[2026-11-20-explore-plan-code-commit-workflow]]、〔Cctx〕[[2026-11-20-context-management-in-claude-code]]、〔Cmd〕[[2026-11-20-the-claude-md-file]]、〔Chook〕[[2026-11-20-hooks-in-claude-code]]（均为厂商自述）
- 〔GO〕[[2026-11-20-harness-engineering-go-practice]]（第三方说法）

| 维度 | OpenHarness | DeepSeek Harness | Pi | Microsoft Agent Framework Harness | Claude Code |
|---|---|---|---|---|---|
| 默认依据 | 〔OH〕 | 〔DR〕〔DL〕 | 〔PI〕 | 〔MS〕 | 见各格 |
| 核心定位 | Python 开源 harness，供研究者看懂、实验、扩展生产级 agent；格式贴近 Claude Code；provider 可切换 | "Everything is a Plugin"，建于 Cordis；Web UI 优先〔DR〕 | "最小、可扩展"；故意少做；TUI、print/JSON、RPC、SDK 四种形态 | 带取向、batteries-included 的默认组合；不另造运行时，产物是普通 agent；UX 不属于 harness | Anthropic 的 agentic coding tool 产品，可用于 terminal、IDE、desktop、web〔Cwhat〕〔C101〕 |
| loop 的职责边界（[[agent-loop\|agent loop]]） | loop 内含固定管线：权限检查 → PreToolUse → 执行 → PostToolUse；自述含指数退避重试、并行工具执行、token 计数 | loop 只管 driver → turn → step 的边界、inbox 队列、session log 一致性和取消；请求从 session log 派生；工具批次整体交给工具服务；请求失败询问插件是否重试〔DL〕 | `pi-agent-core` 负责 "tool calling 与状态管理"；实现资料未提及 | 工具调用循环在 chat pipeline 的 function invocation；Go 中由 provider 构造函数持有；looping 是可选的外层有界重调用 | gather context → take action → verify results，verify 是固定一步；用户可随时打断或 steer〔Chow〕；实现资料未提及 |
| 停止与迭代上限 | 模型 `stop_reason` 不是 `tool_use` 即停；CLI 有 `--max-turns` | 五种 turn 结束原因；`turn-stopping` 处理器可续跑；文件内**无**迭代上限〔DL〕 | 资料未提及 | 每次请求有可配置的迭代上限，默认值未给出 | 未达成目标就继续循环〔Chow〕；上限资料未提及 |
| 权限（[[permissions]]） | Default / Auto / Plan 三模式；`path_rules`、`denied_commands`；内置敏感路径保护；`--dangerously-skip-permissions` | 资料未提及：`SAFETY.md` 未收录〔DR〕；`agent.ts` 不含权限检查，来源页推断在工具服务或其他插件〔DL〕 | 明确**没有**内置权限系统，默认以启动者的权限运行 | standing approvals 和 auto-approval 规则默认开启；有只读工具自动批准规则；可用 `DisableToolAutoApproval` 关闭 | 默认询问；auto accept 下编辑不问、命令仍问；plan mode 只读；`Shift+Tab` 切换〔Chow〕；课程页另列 auto mode〔C101〕 |
| 沙箱/隔离（[[sandboxing]]） | README 未描述内置沙箱（来源页注：仅一条 commit 信息提到 `srt` 下的 sandbox）；Auto 模式自述适用于沙箱环境；web 工具 `trust_env=False` 防 SSRF | 资料未提及；Web 服务默认只监听 `127.0.0.1`〔DR〕 | 隔离外置，三种模式：Gondolin micro-VM（凭据留宿主机）、Plain Docker、OpenShell | 进程级沙箱资料未提及；文件访问按 session 或 scope 隔离，无 scope 时 fail closed | 资料未提及 |
| hooks 粒度（[[hooks]]） | 工具级：PreToolUse / PostToolUse；插件可带 `hooks/hooks.json` | loop 级事件：`agent/pre-step`（可改写输入或 reject）、`agent/request`、`agent/request-error`、`agent/turn-stopping`、`agent/error` 等；没有工具级事件〔DL〕 | README 未描述事件模型；〔GO〕称其 `BeforeToolCall`、`AfterToolCall`、`TransformContext` 命名与 Pi 一致，本库无法从 Pi 一侧核实 | 没有 hooks 式事件的描述；拦截点是 middleware/decorators 和 context provider | 5 个 event：UserPromptSubmit、PreToolUse、PostToolUse、Notification、Stop；运行 shell command；exit code 2 阻止并回传 stderr〔Chook〕 |
| subagent（[[subagents]]） | 内置：`coordinator/` 的 subagent 派生、team registry、后台任务；subprocess teammate | 仅有推断：commit 中有 `feat/subagent-names`〔DR〕，cancel cause 含 `parent`〔DL〕 | 明确**不内置** | background agents 可选（.NET、Python，experimental）；Go 无打包的 provider | 有：并行运行、独立 context window、只回摘要〔Cctx〕；官方推荐提交前跑 reviewer subagent〔Cepcc〕 |
| plan mode（[[planning-and-plan-mode]]） | 内置 Plan Mode，禁止一切写操作；有 `/plan` 命令和 EnterPlanMode / ExitPlanMode 工具 | 资料未提及 | 明确**不内置** | plan / execute 两种 agent mode 默认开启，Go 默认从 plan 开始；todo tracking 默认开启 | plan mode 只用 read-only tools，先出计划再执行〔Chow〕〔Cepcc〕 |
| compaction（[[compaction]]） | Auto-Compact（v0.1.6 起），自述保留任务状态和 channel 日志；触发条件和摘要方式未说明 | loop 不实现，只提供 `runMaintenance` 和 surface 代数接口；由谁实现未知〔DL〕 | 资料未提及 | .NET、Python 在提供 token 上限或自定义策略时开启；Go 需显式组合 | 接近上限自动 compact，官方提醒可能丢细节；手动 `/compact`、`/clear`、`/context`〔Cctx〕〔Chow〕 |
| 扩展模型（[[plugins-and-extensibility]]） | 插件（`.claude-plugin/plugin.json`，可带 commands、hooks、agents）、skills、MCP 客户端、继承 `BaseTool` 的自定义工具；自述兼容 claude-code plugins | 一切皆插件，Cordis 的服务与事件〔DR〕；loop 通过 `loopCtx` 取 tools、llm、systemPrompt 服务〔DL〕；MCP、skills 仅为来源页推断〔DR〕 | extensions、skills、prompt templates、themes，打包成 Pi package 经 npm 或 git 分享；MCP 资料未提及 | context provider 与 middleware；内建 provider 可关闭、替换、追加；Agent Skills；MCP 资料未提及 | `CLAUDE.md`、subagents、skills、MCP servers、hooks 五种定制机制〔C101〕 |
| 上下文文件（[[context-files]]） | 发现并注入 `CLAUDE.md`；持久记忆 `MEMORY.md` | 仓库自身以 `AGENTS.md` 为 agent 入口，`CLAUDE.md` 是其 symlink〔DR〕；运行时如何加载用户项目的上下文文件，资料未提及 | 仓库根有 `AGENTS.md`（对人和 agent 都适用的项目规则）；运行时加载机制 README 未描述 | 资料未提及；有 harness 指令在前、agent 指令在后的两级指令 | `CLAUDE.md`，project level 与 user level，`/init` 生成，`@` 引用文件〔Cmd〕 |
| 成熟度信号（2026-11-20 导出时的页面数据） | 最新 Release v0.1.9；Star 16.2k；MIT；最新提交 "5 months ago" | developer preview，`0.2.2-rc.4`；Star 283.3k；28,026 次提交；最新提交 "17 hours ago"；MIT〔DR〕 | 最新 Release v1.5.2，278 个 Release；Star 122.7k；最新提交 "26 minutes ago"；MIT | 文档更新于 2026-10-28；Python `create_harness_agent` 已发布，多项能力 experimental；版本号和许可证未给出 | 商业产品，有官方课程〔C101〕；版本、许可证资料未提及 |

## 推理与依据

**一、内置与外置是最清晰的分界线，且有原文为证。** Pi 的 README 明说跳过 sub-agents 和 plan mode、没有内置权限系统（[[2026-11-20-pi-readme]]）；OpenHarness 的 README 把这三样都列为内置（[[2026-11-20-openharness-readme]]）；Claude Code 的官方课程把权限模式、plan mode、subagents 当作基本功能讲（[[2026-11-20-how-claude-code-works]]、[[2026-11-20-claude-code-101-course]]）；Microsoft 文档把 plan/execute 模式和审批列为默认开启、后台子 agent 列为可选（[[2026-11-20-microsoft-learn-agent-harness]]）。这一组差异是各方自己声明的设计取舍，不依赖推断。

**二、loop 的职责边界：OpenHarness 与 DeepSeek Harness 处在两端。** OpenHarness 的伪代码把"权限 → hook → 执行 → hook"写在 loop 的每次工具调用里（[[2026-11-20-openharness-readme]]）。DeepSeek Harness 的 `agent.ts` 里，loop 把一个 step 的全部 tool call 作为批次交给工具服务，自己不做权限、不做重试、不设步数上限，也不实现压缩（[[2026-11-20-deepseek-harness-agent-loop-source]]）。需要注意两点：前者是 README 的示意伪代码，后者是真实源码，证据类型不同；后者"策略在插件里"的那一半（谁做权限、谁做重试）是来源页的推断，资料里没有看到对应插件。

**三、hooks 的粒度随 loop 边界而变。** OpenHarness 和 Claude Code 暴露的是工具级事件（PreToolUse / PostToolUse），Claude Code 另有 prompt 提交和停止时的事件（[[2026-11-20-openharness-readme]]、[[2026-11-20-hooks-in-claude-code]]）。DeepSeek Harness 的 loop 暴露的是 step 和 turn 级的事件，能改写输入、否决 step、在 turn 将停时续跑（[[2026-11-20-deepseek-harness-agent-loop-source]]）。这与第二点一致：工具管线不在 loop 里，工具级钩子自然也不在 loop 里。这一对应关系是本页的推断。Microsoft 文档里没有 hooks 这个词，功能上相近的是 middleware（[[2026-11-20-microsoft-learn-agent-harness]]）。

**四、安全边界有三种画法。** 应用层的模式加规则（Claude Code、OpenHarness）；审批规则加默认自动批准（Microsoft）；不做应用层权限、整体放进容器（Pi）。Pi 的 Gondolin 模式把模型凭据留在宿主机、把工具执行放进 micro-VM，是资料中唯一把"凭据"和"工具执行环境"分在边界两侧的设计（[[2026-11-20-pi-readme]]）。AI Harness Crash Course 的两条论断可作为评判框架：控制必须由软件强制执行；sandbox 能限制影响范围但解决不了 prompt injection（[[2026-11-20-ai-harness-crash-course]]）。按这个框架，Pi 的做法满足第一条，但对第二条没有回答；OpenHarness 的 Auto 模式"全部放行"则要求用户自己补上隔离（[[2026-11-20-openharness-readme]]）。后两句是本页的推断。

**五、compaction 上只有 Claude Code 官方承认代价。** Claude Code 课程明说自动 compaction 可能丢细节（[[2026-11-20-context-management-in-claude-code]]）；OpenHarness 自述可以"跑多天的会话"但没有数据（[[2026-11-20-openharness-readme]]）；Microsoft 把 compaction 加 looping 作为长时工作手段（[[2026-11-20-microsoft-learn-agent-harness]]）。

> [!warning] 矛盾
> compaction 是否足以支撑长任务：OpenHarness 自述 Auto-Compact 让 agent 无需手动 compact/clear 就能跑多天会话（[[2026-11-20-openharness-readme]]）；Anthropic 的内部实验观察是，即便有 compaction，跨多个 context window 的大型任务仍会失败，因为 compaction "并不总是把足够清晰的指示传给下一个 agent"（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。前者是无数据的项目自述，后者是定性的内部实验，harness 和任务都不同。

> [!warning] 矛盾
> 谁决定停止：OpenHarness 的立场是"模型决定做什么，harness 负责怎么做"，停止条件只看模型的 `stop_reason`（[[2026-11-20-openharness-readme]]），与 learn-claude-code 的"循环属于 agent"一致（[[2026-11-20-learn-claude-code-readme]]）。DeepSeek Harness 的 `agent/pre-step` 可以 reject、`agent/turn-stopping` 可以让 turn 续跑、工具结果可以宣告 `concluded`（[[2026-11-20-deepseek-harness-agent-loop-source]]）；Microsoft 的 looping 由 evaluator 或谓词驱动重新调用（[[2026-11-20-microsoft-learn-agent-harness]]）。后两者把一部分"停不停"的决定权放在了 harness 一侧。

**六、上下文文件出现了两个约定。** OpenHarness 跟随 Claude Code 用 `CLAUDE.md`（[[2026-11-20-openharness-readme]]、[[2026-11-20-the-claude-md-file]]）；DeepSeek Harness 和 Pi 的仓库都以 `AGENTS.md` 为入口，DeepSeek Harness 用 symlink 兼容 `CLAUDE.md`（[[2026-11-20-deepseek-harness-readme]]、[[2026-11-20-pi-readme]]）。但后两者的资料讲的是"仓库自身给 agent 的规则文件"，不是"harness 运行时加载哪个文件"，不能直接等同。

## 局限性

- **多数是自述而非源码或实测。** OpenHarness、Pi 两列来自 README；Microsoft 一列来自一页由 AI 协助撰写的概念文档；Claude Code 一列来自入门课程的落地页和 6 段有识别错误的视频转录。只有 DeepSeek Harness 的 loop 有一个源码文件，且它依赖的 tools、session、压缩插件都没看到。
- **没有任何实测。** 五者都没有任务成功率、成本或稳定性数据，本页不能回答"哪个更好"。
- **"资料未提及"不等于"没有"。** 最典型的是 Pi 的 hooks、compaction、MCP，DeepSeek Harness 的权限和沙箱，Microsoft 的 hooks、MCP、上下文文件，Claude Code 的沙箱。
- **比较对象不同类。** Claude Code 是商业产品；OpenHarness、Pi、DeepSeek Harness 是开源项目；Microsoft 的是 SDK 里的一组默认组合，且 .NET、Python、Go 三者默认值不一致，表中只能概括。
- **DeepSeek Harness 一列的推断成分最高。** subagent、skills、MCP、权限位置都来自 commit 信息和目录名的推断，已在表中标出。
- **OpenHarness README 自身有不一致**（10 个子系统对 14 个目录、并行工具执行对串行伪代码），其自述的可靠性要打折扣（[[2026-11-20-openharness-readme]]）。
- **成熟度信号只是页面数据。** star 数、提交数不代表质量；DeepSeek Harness 的 star 数相对约 5 个月的公开历史异常高，来源页也无法解释（[[2026-11-20-deepseek-harness-readme]]）。

## 结论的有效期

- 所有数据是 2026-11-20 的快照。DeepSeek Harness 处于 developer preview 并明确警告会有破坏性变更，Pi 发布频繁，两者的结论最容易过期；建议三个月内或摄入新资料时复查。
- 以下资料任一摄入后，对应列应重写：DeepSeek Harness 的 `docs/architecture.md`、`SAFETY.md` 和 Cordis 论文；Pi 的 `packages/coding-agent/docs/` 与 `pi-agent-core` 源码；OpenHarness 的 `engine/`、`permissions/` 源码；Microsoft 文档的 compaction、looping、审批子页；Claude Code 课程未摄入的六课和官方参考文档。
- "内置对外置"这条主线来自各项目的明文取舍声明，预计比具体功能清单稳定。
