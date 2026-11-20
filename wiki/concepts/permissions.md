---
title: Permissions（权限控制）
type: concept
aliases: [权限控制, 权限系统, permission system, tool approval, 工具审批, permission modes, 权限模式]
tags: [agent-harness, permissions, security, tool-approval]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-what-is-claude-code
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-openharness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-deepseek-harness-readme
---

# Permissions（权限控制）

## 定义

permissions（权限控制）是 [[agent-harness|agent harness]] 在[[tools|工具]]真正执行之前设置的决策点：对模型请求的每一次工具调用，由 harness 的代码裁决放行（allow）、拒绝（deny）还是先问人（ask）。learn-claude-code 网站对它的一句话表述是"危险操作在 shell 执行前需要一个 harness 决策点"（[[2026-11-20-learn-claude-code-site]]）；Microsoft 的 harness 定义里也把"应用审批策略"列为 harness 的职责之一（[[2026-11-20-microsoft-learn-agent-harness]]）。

它与 [[sandboxing]] 不是一回事：权限管"这次调用让不让做"，sandbox 管"做了之后最多能碰到什么"。两者的关系见 [[sandboxing]]。

## 要解决的问题和动机

- 模型"决定要改文件"之后，真正去改的是 harness；所以能不能改也只能由 harness 把关。AI Harness Crash Course 的论断是：控制必须由软件强制执行，光叮嘱模型小心是不够的（讲者主张，无论证；[[2026-11-20-ai-harness-crash-course]]）。
- 模型会犯错：误解意图、引入 bug、过度设计。[[claude-code|Claude Code]] 因此默认在运行命令或修改代码前先问用户（厂商自述；[[2026-11-20-what-is-claude-code]]）。官方课程提醒，放任它自由运行命令意味着错误更难在发生前被拦住（[[2026-11-20-how-claude-code-works]]）。
- learn-claude-code 把权限写进 harness 的五要素公式（Tools + Knowledge + Observation + Action Interfaces + Permissions），s03 的格言是 "Set boundaries first, then grant freedom"（作者主张；[[2026-11-20-learn-claude-code-readme]]）。

## 工作原理

### 规则与判定

各资料的共同骨架是三值裁决加一组规则：

- **Go 练习仓库**（测试固定下来的规格，快照中 `Rules.Decide` 仍是桩）：`Policy func(call) Decision`，裁决为 `Allow` / `Deny` / `Ask`。顺序是：工具名在 `AllowTools` → 放行；`bash` 命令包含 `DenyContains` 任一项 → 拒绝；以 `AllowPrefixes` 任一项开头 → 放行；其余一律 `Ask`。拒绝优先于放行（`ls && sudo rm x` 被拒）；`Deny` 时不再去问人；`Ask` 时把完整调用交给 `Approve` 看（[[2026-11-20-harness-engineering-go-practice]]）。
- **learn-claude-code s03**：`PermissionRule` 加 approval pipeline，区分可执行、必须拦下、需要审批三类（README 只给了关键词，章节正文未摄入；[[2026-11-20-learn-claude-code-readme]]）。
- **[[openharness|OpenHarness]]**（项目自述）：`settings.json` 里配 `path_rules`（如 `/etc/*` 拒绝）和 `denied_commands`（如 `rm -rf /`）；v0.1.4 起 PermissionChecker 内置敏感路径保护；每个工具都带"权限集成"，执行前检查（[[2026-11-20-openharness-readme]]）。
- **[[microsoft-agent-framework|Microsoft Agent Framework]]**：以 auto-approval 规则放行一部分工具。文件访问 provider 提供规则工厂，`get_read_only_tools_auto_approval_rule()` 只自动批准只读工具；文档建议除非存储边界和工具输入可信，否则保持写操作需要审批（[[2026-11-20-microsoft-learn-agent-harness]]）。

### 权限模式

模式是一组预设的规则，让用户按任务选择监督程度：

| 项目 | 模式 | 行为 | 来源 |
|---|---|---|---|
| [[claude-code\|Claude Code]] | 默认（课程大纲称 manual mode） | 编辑文件或运行 shell 命令前必须明确请求许可 | [[2026-11-20-how-claude-code-works]] |
| Claude Code | auto-accept | 编辑文件不再询问，运行命令仍然询问 | [[2026-11-20-how-claude-code-works]] |
| Claude Code | auto mode | 大纲只列出名字，未说明行为 | [[2026-11-20-claude-code-101-course]] |
| Claude Code | plan mode | 只用 read-only tools，不能编辑文件，先产出计划 | [[2026-11-20-how-claude-code-works]]、[[2026-11-20-explore-plan-code-commit-workflow]] |
| [[openharness\|OpenHarness]] | Default | 写和执行前询问 | [[2026-11-20-openharness-readme]] |
| OpenHarness | Auto | 全部放行，自述适用于沙箱环境 | [[2026-11-20-openharness-readme]] |
| OpenHarness | Plan Mode | 禁止一切写操作 | [[2026-11-20-openharness-readme]] |

- Claude Code 用 `Shift+Tab` 切换模式（[[2026-11-20-how-claude-code-works]]）；OpenHarness 用 `/permissions` 或 `--permission-mode`（[[2026-11-20-openharness-readme]]）。
- "默认模式"与大纲里的 "manual mode" 是同一个东西，这是笔者推断，两份资料都没有明说。
- plan mode 既是权限模式（只读），又是一种工作流手段，后一面见 [[planning-and-plan-mode]]。Microsoft 的 plan / execute 是 agent 的运行模式，文档没有把它描述成权限模式（[[2026-11-20-microsoft-learn-agent-harness]]）。

### 在工具管线中的位置：先于 hook

- OpenHarness 的 loop 伪代码把每次工具调用的固定管线写成"Permission check → Hook → Execute → Hook → Result"（示意伪代码，非源码；[[2026-11-20-openharness-readme]]）。
- Go 练习仓库的测试约定：权限在前，[[hooks|hook]] 在后，权限已拒绝的调用不再触发 `BeforeToolCall`（[[2026-11-20-harness-engineering-go-practice]]）。
- learn-claude-code 网站把 Permission 和 Hooks 都归入 "Tools & Execution" 层，即把权限看作工具执行管线上的一个决策点，而不是单独的安全层（[[2026-11-20-learn-claude-code-site]]）。
- [[deepseek-harness|DeepSeek Harness]] 的 loop 源码里没有权限检查，loop 把整批 tool call 交给工具服务；权限在工具服务内部还是由别的插件承担，资料中看不到（来源页标为推断；[[2026-11-20-deepseek-harness-agent-loop-source]]）。
- Claude Code 自身的权限检查与 hook 的先后，本批资料没有说明；官方视频只说 `PreToolUse` hook 是在 tool call 执行之前运行、可以阻止它（[[2026-11-20-hooks-in-claude-code]]）。

### 被拒之后，以及无人可问时

- 无论批不批准循环都继续：模型拿到一条固定文字的工具结果（`MsgDenied` 或 `MsgRejected`），自己决定换什么做法（[[2026-11-20-harness-engineering-go-practice]]）。
- **无人值守按拒绝处理**：`Approve` 为 nil 时，`Ask` 的结果是拒绝；注释的理由是"安全相关的默认值要选保守的那一边"（[[2026-11-20-harness-engineering-go-practice]]）。Microsoft 文件访问的 fail closed 是同一种取向用在存储范围上（见 [[sandboxing]]）。
- 交互式场景下，harness 暂停并请求人批准后再执行工具（[[2026-11-20-ai-harness-crash-course]]）；Microsoft 把"收集工具审批这类输入"划给应用 UX 层，不属于 harness 本体（[[2026-11-20-microsoft-learn-agent-harness]]）。

## 变体与演进

- **模式制**（Claude Code、OpenHarness）：少数几个预设档位，切换成本低。
- **规则制**（Go 练习仓库、OpenHarness 的路径规则和命令黑名单、Microsoft 的 auto-approval 规则）：按工具名、路径或命令内容细分。
- **常设批准**（standing approvals）：Microsoft 的 Harness 默认开启 standing approvals 和 auto-approval 规则，Go SDK 以 middleware 形式提供。它的作用域和有效期、默认规则具体放行哪些工具，文档没有说明（[[2026-11-20-microsoft-learn-agent-harness]]）。
- **跳过权限**：OpenHarness 有 `--dangerously-skip-permissions` 开关（[[2026-11-20-openharness-readme]]）。
- **委派时的继承**：Go 练习仓库的命令行入口里，[[subagents|子 agent]] 继承父级的权限策略（[[2026-11-20-harness-engineering-go-practice]]）。
- **不做权限系统**：[[pi|Pi]] 的 README 明说没有内置权限系统来限制文件系统、进程、网络或凭据访问，默认以启动它的用户和进程的权限运行；需要更强边界就把 Pi 容器化或放进沙箱（[[2026-11-20-pi-readme]]）。

## 优缺点和权衡

- **监督程度与打断**：Claude Code 的官方说法是让用户在"更 hands-on"与"更被动"之间选（[[2026-11-20-what-is-claude-code]]）；模式越宽松，错误越难在发生前被拦住（[[2026-11-20-how-claude-code-works]]）。
- **字符串匹配容易绕过**：按 Go 练习仓库的规格，前缀放行意味着 `ls; curl … | sh` 会因为以 `ls` 开头而放行（除非命中 `DenyContains`）；白名单含 `cat ` 时，`cat .env` 不需要批准。这是来源页作者读代码后的推断，不是测试断言（[[2026-11-20-harness-engineering-go-practice]]）。
- **全放行需要另一条防线**：OpenHarness 自述 Auto 模式适用于沙箱环境，但 README 没有描述内置沙箱（[[2026-11-20-openharness-readme]]）。
- **默认自动批准的安全性未知**：Microsoft 默认开启 auto-approval，可用 `DisableToolAutoApproval` 关闭，但默认放行范围未在该页说明（[[2026-11-20-microsoft-learn-agent-harness]]）。
- 没有任何一份资料给出权限机制拦截率、误拦率或对任务完成率影响的数据。

## 不同来源的分歧

> [!warning] 矛盾
> Claude Code 有几种权限模式，官方两份资料说法不同：
> - 课程落地页列四种：manual mode、auto-accept、auto mode、Plan Mode（[[2026-11-20-claude-code-101-course]]）。
> - 第 2 课视频只讲三种：默认、auto accept、plan mode，没有 auto mode（[[2026-11-20-how-claude-code-works]]）。
>
> auto mode 与 auto-accept 的区别两份资料都没有解释。两份资料都没有发布日期，无法判断是否一新一旧。

> [!warning] 矛盾
> 权限系统是不是 harness 的必备件：
> - 是：learn-claude-code 把 Permissions 列为 harness 五要素之一（[[2026-11-20-learn-claude-code-readme]]）；OpenHarness 把 `permissions/` 做成固定子系统（[[2026-11-20-openharness-readme]]）；Microsoft 把审批策略写进 harness 的定义（[[2026-11-20-microsoft-learn-agent-harness]]）。
> - 否：Pi 明确不做，把边界交给容器或沙箱（[[2026-11-20-pi-readme]]）。
>
> Pi 的 README 没有写出理由。"应用层逐次确认既打断流程又不是真正的安全边界"是来源页的推断，没有资料佐证。

- **同名不同义**：Claude Code 的 auto-accept 只免除文件编辑的询问，命令仍要问（[[2026-11-20-how-claude-code-works]]）；OpenHarness 的 Auto 是全部放行（[[2026-11-20-openharness-readme]]）。跨项目比较时不能按名字对应。
- **权限是否包含隔离**：learn-claude-code 的 README 在展开五要素时，把 Permissions 一项写作 sandbox isolation、approval workflows、trust boundaries，即把 sandbox 算作权限的一部分（README 原文，来源页未摘录这一行；[[2026-11-20-learn-claude-code-readme]]）；Crash Course 和 Pi 则把两者当作不同手段（[[2026-11-20-ai-harness-crash-course]]、[[2026-11-20-pi-readme]]）。
- **DeepSeek Harness 的权限模型在本批资料中是空白**：README 要求运行前先读 `SAFETY.md`，其内容未摄入（[[2026-11-20-deepseek-harness-readme]]）。

## 采用它的项目

| 项目 | 做法 | 来源 |
|---|---|---|
| [[claude-code\|Claude Code]] | 默认询问 + 多种模式，`Shift+Tab` 切换 | [[2026-11-20-how-claude-code-works]] |
| [[openharness\|OpenHarness]] | 三种模式 + 路径规则 + 命令黑名单（自述） | [[2026-11-20-openharness-readme]] |
| [[microsoft-agent-framework\|Microsoft Agent Framework]] | standing approvals + auto-approval 规则，默认开启 | [[2026-11-20-microsoft-learn-agent-harness]] |
| [[learn-claude-code]] | s03 教学实现：`PermissionRule` + approval pipeline | [[2026-11-20-learn-claude-code-readme]] |
| Go 练习仓库 | allow / deny / ask 规格与测试（实现待完成） | [[2026-11-20-harness-engineering-go-practice]] |
| [[pi\|Pi]] | 不内置，交给容器或沙箱 | [[2026-11-20-pi-readme]] |

## 相关概念

- [[sandboxing]]：另一条防线，限制影响范围。
- [[hooks]]：权限之后的确定性拦截点，也能阻止工具调用。
- [[planning-and-plan-mode]]：plan mode 的工作流一面。
- [[tools]]：权限检查挂在工具执行管线上。
- [[subagents]]：委派时权限如何继承。
- [[steering-and-cancel]]：人在循环中途介入的另一种方式。
- 横向比较见 [[开源-harness-设计取向对比]]。
