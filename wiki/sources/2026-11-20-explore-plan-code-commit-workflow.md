---
title: The explore → plan → code → commit workflow（Claude Code 101 视频）
type: source
kind: talk
aliases: [Explore Plan Code Commit workflow, explore-plan-code-commit]
tags: [claude-code, agent-harness, workflow, plan-mode, verification, vendor-talk]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/yt-explore-plan-code-commit-workflow.md
author: Anthropic
url: https://www.youtube.com/watch?v=xJQuF02NAK8
---

# The explore → plan → code → commit workflow（Claude Code 101 视频）

> [!note] 资料性质
> YouTube 视频的自动转录，有识别错误（"cloud code""Claw" 即 Claude Code、Claude；"Claude and Chrome extension" 应为 Claude in Chrome extension）。[[anthropic|Anthropic]] 对自家产品的介绍，属于厂商自述。转录中没有作者署名和发布日期。

## 一段话概括

官方推荐的使用 [[claude-code|Claude Code]] 的四步人机协作节奏：Explore、Plan、Code、Commit。核心主张是不要一上来就让 Claude 写代码（否则之后要更多纠偏），先用 plan mode 调研并产出计划，在写代码之前纠偏；计划里要写明什么算"正确"，并给 Claude 能自我验证的工具。开篇称这是整门课"最该带走的一件事"。

## 要点

### Explore + Plan：用 plan mode

- plan mode 下 Claude **不能编辑文件**，只读文件做调研。进入方式：按 `Shift+Tab` 直到输入框下方出现 plan mode（属于 [[permissions]] 模式之一）。
- 示例 prompt：给 image upload pipeline 加 WebP 转换，让它弄清转换应放在哪、是否需要新依赖、如何实现。Claude 会读相关文件、做 web search，然后给出行动计划。
- 用户审阅计划，不满意就让它补充或修改。资料称这是**最佳纠偏点**，因为还没有写任何代码（[[steering-and-cancel|steering]]）。
- 也可以不进 plan mode，直接让 Claude explore codebase。

### Code

- 计划满意后选择 approve，Claude 逐项执行计划中的条目；可以选择 auto accept 文件编辑，或每次询问。
- Claude 会先尽力自行排查问题再认定计划完成，但有时仍需人纠偏。资料称 plan mode 的好处之一：计划完成后，context 里留有"如何得到结果"的过程，有助于后续决策。

### 让 Claude 能验证自己

这一段对应 [[verification-and-observability|verification]]：

- 要让 Claude 对结果有把握，必须让它清楚什么算正确；写计划时把这一点写明。
- 给它能完成目标的 [[tools]]，可减少大量来回。例：做 web UI 时装 Claude in Chrome extension，让 Claude Code 控制一个 tab 测试 UI 后再认定完成。
- 项目里要有 test suite 供 Claude 持续验证；Claude 也可以代写测试。但交给它之前，要确保这些测试对你和团队是 source of truth，避免 false positives。
- 小技巧：Claude 反复遇到同一问题时，让它把解法存进 `CLAUDE.md`（[[context-files|context file]]）。

### Commit

- 自己测试并满意之后再 push。
- 提交前先跑一个 subagent code reviewer 审查代码（[[subagents]]）。
- 然后让 Claude 按你的风格生成 commit message。之后循环往复。

### 片尾对四步的定义

| 步骤 | 作用 |
|---|---|
| Explore | 为 Claude 提供项目的相关 context |
| Plan | 产出行动计划，Claude 用它判断自己是否成功 |
| Code | 人与 Claude 的来回，直到确定计划的最终结果 |
| Commit | 审查并 push 代码，以便开始下一个功能 |

## 值得记下的论据

- 没有数字或实验；"跳过此流程意味着之后更多纠偏"是作者主张。
- 这是由人驱动的固定步骤流程，套在 agent 自主循环之外，可作为 [[workflows-vs-agents|workflows vs agents]] 讨论的一个实例（这一归类是我的推断，资料未使用该术语）。

## 与已有知识的关系

- 印证 [[2026-11-20-how-claude-code-works]]：plan mode 只读、`Shift+Tab` 切换、verify 是 loop 的一环；本片补充了 verify 的具体手段（测试、浏览器）。
- 印证 [[2026-11-20-claude-code-101-course]] 的 code review 课定位（自己过目 + fresh-context reviewer）。
- 与 [[2026-11-20-context-management-in-claude-code]] 衔接：一个计划完成后开始新功能时应 `/clear`。

## 遗留问题

- approve 计划后是否保留调研阶段的全部 context，以及长计划执行中 context 用尽怎么办，本片未说明。
- "Claude 代写测试"与"测试须是 source of truth"之间如何把关，只给了原则。
