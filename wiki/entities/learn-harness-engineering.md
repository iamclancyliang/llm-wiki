---
title: Learn Harness Engineering
type: entity
kind: project
aliases: [learn-harness-engineering, walkinglabs 课程, walkinglabs/learn-harness-engineering]
tags: [harness-engineering, course, long-running-agents, verification]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-learn-claude-code-readme
---

# Learn Harness Engineering

> [!note] 资料边界
> 唯一的直接来源是 2026-11-20 导出的课程欢迎页。14 篇讲义、实战项目、模板和"前沿 Harness 拆解"的正文都没有导出；下文关于各讲的内容只是从标题和 URL slug 读出来的，不能当作讲义的实际论点（[[2026-11-20-learn-harness-engineering-course]]）。

## 是什么、解决什么问题

walkinglabs 的一门课程，自述"专注于 AI 编程智能体工程化落地"。它不教怎么写 agent 运行时，而是教怎么在代码仓库里为现成的 coding agent（[[codex|Codex]]、[[claude-code|Claude Code]]）搭一套工作环境。核心论断："Harness 的本质不是'让模型变聪明'，而是给模型建立一套闭环的工作系统。"（[[2026-11-20-learn-harness-engineering-course]]）

首页的学习目标对应五类失败：行为越界、跨会话丢失上下文、提前宣告完成、不验证自己的工作、过程黑箱（[[2026-11-20-learn-harness-engineering-course]]）。

## 关键事实

- 组织：walkinglabs；首页没有作者署名（[[2026-11-20-learn-harness-engineering-course]]）。
- 形式：GitHub Pages 静态站点，15 种语言版本（[[2026-11-20-learn-harness-engineering-course]]）。
- 版本号、更新日期、许可证、仓库 star 数：资料未提及。

## 工作原理概要：闭环工作系统

首页流程图把 [[agent-harness|harness]] 的每个环节绑定到仓库里的具体文件或命令（箭头走向是来源页根据边标签重建的，属推断）（[[2026-11-20-learn-harness-engineering-course]]）：

| 环节 | 载体 | 对应概念 |
|---|---|---|
| 明确目标 | `AGENTS.md` | [[context-files\|context file]] |
| 初始化检查 | `init.sh` | [[long-running-agents\|长任务]]的会话入口 |
| 运行反馈 | CLI 输出、日志 | [[verification-and-observability\|可观测性]] |
| 验证与评审 | 测试与 QA | 完成由测试判定，不由模型自述 |
| 清理与交接 | `claude-progress.md` | 跨会话交接 |
| 任务范围 | `feature_list.json` | 功能清单 |

也就是说，这里的 harness 主要由"仓库里的文件 + 约定的流程"构成，状态全部落盘，新会话读文件就能接上（[[2026-11-20-learn-harness-engineering-course]]）。

14 讲的标题线索（仅标题层面）：仓库是 system of record（L03）；一个巨大的指令文件会失败（L04，[[context-management]]）；初始化是独立阶段（L06）；功能清单是 harness primitive（L08）；防止提前宣告完成（L09）；端到端测试（L10）；可观测性属于 harness 内部（L11）；每个会话留下干净状态（L12）；L13 loop engineering；L14 graph engineering（[[2026-11-20-learn-harness-engineering-course]]）。

其他组成：实战项目（P01 "提示词 vs 规则驱动"）、可复制的模板资料库、技能栏目、"前沿 Harness 拆解"（[[pi|Pi]]、Claude Code、Codex、DeepSeek；来源页认为最后一项应指 [[deepseek-harness|DeepSeek Harness]]）（[[2026-11-20-learn-harness-engineering-course]]）。

## 理论来源

课程自述总结了 [[openai|OpenAI]] 的 harness engineering 文章、[[anthropic|Anthropic]] 的《Effective harnesses for long-running agents》和《Harness design for long-running application development》，以及 walkinglabs/awesome-harness-engineering（[[2026-11-20-learn-harness-engineering-course]]）。所以它是二手综合。前两篇本库有来源页，可以对照：

- `init.sh`、功能清单、进度文件与 Anthropic 的 initializer / coding agent 做法是同一套（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。
- "仓库是 system of record""巨大的指令文件会失败"对应 OpenAI 文章的两条经验（[[2026-11-20-openai-harness-engineering]]）。
- 第三篇《Harness design for long-running application development》不在本库 raw 中，无法对照。

> [!warning] 矛盾
> 进度文件的文件名在三处资料中各不相同：Anthropic 原文是 `claude-progress.txt`（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；本课程首页是 `claude-progress.md`（[[2026-11-20-learn-harness-engineering-course]]）；Go 练习仓库是 `progress.md`（[[2026-11-20-harness-engineering-go-practice]]）。这是命名差异而非机制差异，但引用文件名时要注明出处。

## 优缺点与适用场景

- 适用：已经在用 Claude Code 或 Codex，想让它在真实仓库里更可靠地做多会话任务；想要现成模板（[[2026-11-20-learn-harness-engineering-course]]）。
- 不适用：想理解 [[agent-loop|agent loop]]、工具调度、[[compaction]] 等运行时内部机制的读者。来源页推断课程把运行时当作给定的黑箱，依据是讲义标题里没有一讲讲运行时实现（[[2026-11-20-learn-harness-engineering-course]]）。
- 课程声称能让 agent"真正可靠地完成真实工程任务"，首页没有任何对比数据（[[2026-11-20-learn-harness-engineering-course]]）。

> [!warning] 矛盾
> "harness" 一词的所指不同：本课程指仓库内的规则、状态文件和验证流程（[[2026-11-20-learn-harness-engineering-course]]）；[[learn-claude-code]] 指包住模型的运行时代码（循环、工具、权限、压缩）（[[2026-11-20-learn-claude-code-readme]]）。两者都自称 [[harness-engineering|harness engineering]]。
>
> 对编排的态度也不同：本课程 L14 把"图工程"当作进阶方向（[[2026-11-20-learn-harness-engineering-course]]）；learn-claude-code 的 README 宣言把节点图式编排斥为"不是 agent"（[[2026-11-20-learn-claude-code-readme]]）。见 [[workflows-vs-agents]]。

## 同类替代品

- [[learn-claude-code]]：教运行时代码。
- Go 练习仓库：用可执行测试固定各机制的行为规格，其 `longrun` 包实现了同样的 `feature_list.json` 加进度文件，并用代码强制"只允许把 `passes` 从 false 改成 true"（[[2026-11-20-harness-engineering-go-practice]]）。
- 一手资料本身：OpenAI 与 Anthropic 的两篇文章。写概念页时应优先引用原文，把本课程当作组织框架（[[2026-11-20-learn-harness-engineering-course]]）。

## 未解问题

- "loop engineering""graph engineering"是课程自造术语还是通用说法（[[2026-11-20-learn-harness-engineering-course]]）。
- P01 对比实验的任务、模型和结果（[[2026-11-20-learn-harness-engineering-course]]）。
- "前沿 Harness 拆解"对四个真实 harness 的分析可能有一手信息量，值得单独摄入（[[2026-11-20-learn-harness-engineering-course]]）。
