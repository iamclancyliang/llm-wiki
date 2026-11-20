---
title: Learn Harness Engineering 课程首页（walkinglabs，中文版）
type: source
kind: doc
aliases: [Learn Harness Engineering, walkinglabs 课程, learn-harness-engineering]
tags: [harness-engineering, agent-harness, course, long-running-agents, verification]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/walkinglabs-learn-harness-engineering.md
author: walkinglabs
url: https://walkinglabs.github.io/learn-harness-engineering/zh/
---

# Learn Harness Engineering 课程首页（walkinglabs，中文版）

> 资料是 2026-11-20 导出的课程欢迎页纯文本（216 行，其中大半是导航和语言切换链接）。只有首页，14 篇讲义、实战项目、模板和"前沿 Harness 拆解"的正文都没有导出。页面没有标注发布日期，frontmatter 不填 `published`。

## 一段话概括

[[learn-harness-engineering|Learn Harness Engineering]] 是 walkinglabs 的一门课程，自述"专注于 AI 编程智能体工程化落地"。它不教怎么从零写一个 agent 运行时，而是教怎么**在代码仓库里**为现成的 coding agent（[[codex|Codex]]、[[claude-code|Claude Code]]）搭一套工作环境：用规则文件划定边界、用状态文件保持跨会话连续、用测试和评审防止提前宣告完成、用日志让过程可观测。首页的核心论断是："Harness 的本质不是'让模型变聪明'，而是给模型建立一套闭环的工作系统。"

## 解决什么问题

课程第一讲的标题就是问题本身："模型能力强，不等于执行可靠"。首页列出的学习目标对应五类失败：

1. agent 行为越界 → 用明确的规则和边界约束。
2. 跨会话的长任务丢失上下文 → 保持上下文连续性。
3. agent 提前宣告任务完成 → 设置完成的硬条件。
4. agent 不验证自己的工作 → 用完整流水线测试自我验证。
5. 过程黑箱 → 让运行过程可观测、可调试。

## 理论来源（课程自述）

首页声明课程"深度研究并总结了"下列资料：

- [[openai|OpenAI]]：Harness engineering: leveraging Codex in an agent-first world
- [[anthropic|Anthropic]]：Effective harnesses for long-running agents
- Anthropic：Harness design for long-running application development
- walkinglabs/awesome-harness-engineering（同组织的资料汇总仓库）

所以这门课是二手综合，其框架的可靠性取决于它对这几篇一手资料的转述是否准确。本 wiki 的 `raw/agent-harness/` 里有前两篇原文，写概念页时应优先引用原文，把这门课当作组织框架。

## 架构与关键设计决策：闭环工作系统

首页用一张流程图表达 [[agent-harness|harness]] 的核心机制。导出文本丢了图的结构，只剩节点和边的标签，按文字顺序可以重建为：

```
明确目标（AGENTS.md）
  → 初始化检查（init.sh）
  → 运行任务（AI Agent） ⇄ 运行反馈（CLI / Logs）   遇到障碍 → 自动修复
  → 代码完成 → 验证与评审（Test & QA）
        未通过 → 回到运行任务
        通过   → 清理与交接（claude-progress.md）
```

（出处：首页"Harness 的核心机制"一节。箭头走向是根据"遇到障碍 / 自动修复 / 代码完成 / 未通过 / 通过"这些边标签重建的，属于推断。）

这张图里每个节点都绑定了一个**仓库里的具体文件或命令**，这是这门课最有辨识度的设计取向：

| 环节 | 载体 | 作用 |
|---|---|---|
| 明确目标 | `AGENTS.md` | 规则与边界，属于 [[context-files\|context file]] |
| 初始化检查 | `init.sh` | 每次会话开工前先确认环境可用 |
| 运行反馈 | CLI 输出、日志 | agent 看到的 ground truth |
| 验证与评审 | 测试与 QA | 判定"完成"的是测试，不是模型的自述 |
| 清理与交接 | `claude-progress.md` | 会话结束时写下进度，供下一个会话接手 |
| 任务范围 | `feature_list.json` | 功能清单，约束 agent 该做什么（出现在资料库模板的描述里） |

也就是说，这里的 harness 主要由"仓库里的文件 + 约定的流程"构成，而不是一段运行时代码。状态全部落盘，任何一个新会话读文件就能接上。

## 14 讲讲义的结构

首页侧栏给出全部讲义标题（中文标题是面向做法的，英文 URL slug 是面向问题的，两者对照很有信息量）：

| 讲 | 中文标题 | URL slug 透露的问题 |
|---|---|---|
| L01 | 模型能力强，不等于执行可靠 | why capable agents still fail |
| L02 | Harness 的定义 | what a harness actually is |
| L03 | 让代码仓库成为唯一的事实来源 | why the repository must become the system of record |
| L04 | 把指令拆分到不同文件里 | why one giant instruction file fails |
| L05 | 让跨会话的任务保持上下文连续 | why long-running tasks lose continuity |
| L06 | 让 agent 每次工作前先初始化 | why initialization needs its own phase |
| L07 | 给 agent 划清每次任务的边界 | why agents overreach and under-finish |
| L08 | 用功能清单约束 agent 该做什么 | why feature lists are harness primitives |
| L09 | 防止 agent 提前宣告完成 | why agents declare victory too early |
| L10 | 跑通完整流程才算真正验证 | why end-to-end testing changes results |
| L11 | 让 agent 的运行过程可观测 | why observability belongs inside the harness |
| L12 | 每次会话结束前都做好交接 | why every session must leave a clean state |
| L13 | 从手动驱动到自动循环 | loop engineering |
| L14 | 从单循环到图工程 | graph engineering |

从标题可以读出的主张（都只是标题层面，正文未摄入）：

- **仓库是 system of record（L03）**：agent 需要的知识应当在仓库里，而不是在聊天记录或人的脑子里。
- **一个巨大的指令文件会失败（L04）**：指令要拆分到多个文件。这与 [[context-management|上下文管理]]里"按需加载"的思路一致。
- **初始化是独立阶段（L06）**、**每个会话必须留下干净状态（L12）**：两者合起来就是 [[long-running-agents|长任务]]跨会话接力的入口和出口。
- **功能清单是 harness 的 primitive（L08）**：agent 的两种典型偏差是"做过头"和"没做完"（L07），清单同时约束这两头。
- **端到端测试改变结果（L10）**、**可观测性属于 harness 内部（L11）**：对应 [[verification-and-observability|验证与可观测性]]。
- **L13 → L14 的递进**：从人手动驱动，到自动循环（loop engineering），再到"图工程"（graph engineering）。L14 的存在说明这门课并不排斥用图结构编排，这与 [[workflows-vs-agents]] 的讨论有关。

## 课程的其他组成部分

- **项目**：实战，第一个是 P01 "提示词 vs 规则驱动"（slug 为 baseline-vs-minimal-harness），让学习者对比有无最小 harness 时的结果。
- **资料库**：开箱即用的模板（`AGENTS.md`、`feature_list.json` 等），可直接复制进自己的仓库；导航里的 "Try Harness" 指向模板目录。
- **技能**：导航里有 skills 一栏，内容未导出。
- **前沿 Harness 拆解**：用课程框架逐层拆解 [[pi|Pi]]、Claude Code、Codex、DeepSeek（应指 [[deepseek-harness]]，首页只写了 "DeepSeek"）的真实 harness 设计。

## 适用与不适用的场景

- 适用：已经在用 Claude Code 或 Codex，想让它在真实仓库里更可靠地做多会话任务；想要现成模板。
- 不适用：想理解 agent loop、工具调度、[[compaction]] 这些运行时内部机制的读者。从首页看，这门课把运行时当作给定的黑箱，工作面在仓库和流程上（推断，依据是讲义标题里没有任何一讲讲运行时实现）。

## 成熟度

- 文档站是托管在 GitHub Pages 的静态站点（页面锚点 `VPContent` 提示它用 VitePress 生成，属推断），有 15 种语言版本（简体中文、英语、繁体中文、日语、西班牙语、法语、德语、土耳其语、阿拉伯语、越南语、韩语、乌兹别克语、俄语、巴西葡萄牙语、乌克兰语）。
- 首页没有版本号、更新日期、许可证或作者署名；仓库的 star 数和活跃度不在导出内容里。

## 与已有知识的关系

- 印证：流程图里的 `init.sh`、功能清单、进度文件，与 Anthropic《Effective harnesses for long-running agents》里的 initializer / coding agent 做法是同一套（课程自己列了这篇为来源）。本地练习仓库的 `longrun` 包也实现了同样的 `feature_list.json` 加进度文件（见 `2026-11-20-harness-engineering-go-practice`），文件名略有不同：课程用 `claude-progress.md`，练习仓库用 `progress.md`。
- 分歧（定义层面）：这里的 "harness" 指仓库内的规则、状态文件和验证流程；learn-claude-code 的 "harness" 指包住模型的运行时代码（循环、工具、权限、压缩）。两者都自称 harness engineering，但工作对象不同，概念页需要把这两层含义分开写。
- 分歧（对编排的态度）：L14 "图工程"把图式编排当作进阶方向；learn-claude-code 的 README 则把节点图式的编排斥为"不是 agent"。

## 涉及的实体和概念

实体：[[learn-harness-engineering]]、[[codex]]、[[claude-code]]、[[pi]]、[[deepseek-harness]]、[[openai]]、[[anthropic]]。
概念：[[harness-engineering]]、[[agent-harness]]、[[context-files]]、[[context-management]]、[[long-running-agents]]、[[verification-and-observability]]、[[workflows-vs-agents]]、[[compaction]]。

## 局限与遗留问题

- 只有首页。上面关于每一讲的内容都是从标题和 slug 读出来的，不能当作讲义的实际论点引用。
- "loop engineering" 和 "graph engineering" 是这门课自己的术语还是业内通用说法？L13、L14 的正文需要补摄入。
- 课程声称能让 agent "真正可靠地完成真实工程任务"，首页没有给出任何对比数据；P01 的对比实验结果是什么、在什么任务和模型上做的，未知。
- "前沿 Harness 拆解"对四个真实 harness 的分析是这门课最可能有一手信息量的部分，值得单独摄入。
