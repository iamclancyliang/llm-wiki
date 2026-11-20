---
title: Skills（按需加载的知识与工作流）
type: concept
aliases: [skill, 技能, Agent Skills, SKILL.md, skill loading, 按需加载]
tags: [agent-harness, skills, progressive-disclosure, context-management]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-context-management-in-claude-code
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-openharness-readme
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-pi-readme
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-the-claude-md-file
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-learn-harness-engineering-course
---

# Skills（按需加载的知识与工作流）

## 定义

skill 是一份打包好的专门知识或工作流说明，[[agent-harness|agent harness]] 平时只让模型看到它的名字和简介，模型判断任务需要时才把正文读进 context。[[openharness|OpenHarness]] 的定义是"按需知识，模型需要时才加载"（[[2026-11-20-openharness-readme]]）；learn-claude-code s07 的格言是 "Load knowledge on demand, not upfront"，做法是先列目录、用到时才展开注入（[[2026-11-20-learn-claude-code-readme]]）；[[claude-code|Claude Code]] 官方课程把它定位为"经常重复的任务或工作流"的载体（[[2026-11-20-claude-code-101-course]]）。

## 要解决的问题和动机

- **context 是稀缺资源**。专门知识如果全部预先塞进 prompt，会挤掉任务本身。learn-claude-code 网站的一句话是"只在任务真正需要时注入专门知识"（[[2026-11-20-learn-claude-code-site]]）；README 把"按需加载而不是预先加载"写进 harness 工程师"整理知识"的职责里（README 原文，来源页未摘录这一句；[[2026-11-20-learn-claude-code-readme]]）。
- **重复的工作流不必每次重讲**。Claude Code 课程说 subagents 和 skills 用于"你经常重复的工作流"（[[2026-11-20-claude-code-101-course]]）。
- **节省 context 的手段之一**。官方视频把"用 skills"与"写具体的 prompt、用 `CLAUDE.md`、关掉无关的 MCP servers、用 subagents"并列为五条节省 context 的做法（[[2026-11-20-context-management-in-claude-code]]）。

## 工作原理

### 两段式加载

Go 练习仓库用测试把最小行为固定了下来（`LoadSkills` 已实现，组装函数 `Build` 在快照中仍是桩；[[2026-11-20-harness-engineering-go-practice]]）：

- [[system-prompt|system prompt]] 里每个 skill 只放名字、描述和路径；顺序是基础指令 → 各级 `AGENTS.md` → skill 清单。
- 完整内容由模型在需要时用 `read_file` 去读，不需要专门的加载工具。
- 测试断言正文不出现在提示词里，且两个 skill 的清单不超过 600 个字符。

learn-claude-code s07 的 `SkillLoader` 是同一思路（[[2026-11-20-learn-claude-code-readme]]）；网站 s10 把 skills 列为生成 system prompt 的四种输入之一（策略、工具、skills、上下文）（[[2026-11-20-learn-claude-code-site]]）。OpenHarness 的工具清单里有一个 Skill 元工具（[[2026-11-20-openharness-readme]]）；它是否就是"展开正文"的入口，README 没有说明。

### SKILL.md 布局与发现路径

OpenHarness 自述兼容 anthropics/skills，采用 `<skill>/SKILL.md` 的目录布局（[[2026-11-20-openharness-readme]]）：

- 用户级：`~/.openharness/skills/<skill>/SKILL.md`、`~/.claude/skills/<skill>/SKILL.md`、`~/.agents/skills/<skill>/SKILL.md`。
- 项目级：`<project>/.openharness/skills/`、`.agents/skills/`、`.claude/skills/` 下的同名布局，从当前工作目录向上找到 git root。
- skill 还可以来自内置（bundled）、ohmo 和插件。`/skills` 列出已加载的 skills 及其来源和路径；可由用户调用的 skill 能直接当斜杠命令运行（README 的例子是 `/deploy staging`）。
- 自定义 skill 的示例是一个带 frontmatter 的 markdown：`name`、`description`，正文分 "When to use" 和 "Workflow" 两节。

```markdown
---
name: my-skill
description: Expert guidance for my specific domain
---
# My Skill
## When to use
## Workflow
```
（出处：OpenHarness README "Add a Custom Skill"，有删节；转引自 [[2026-11-20-openharness-readme]]）

[[microsoft-agent-framework|Microsoft Agent Framework]] 的 Go SDK 默认从工作目录做基于文件的 skill 发现，并排除 memory 子树；带脚本的 skill 需要显式配置 script runner（[[2026-11-20-microsoft-learn-agent-harness]]）。

### 渐进式披露

"渐进式披露"（progressive disclosure）一词在本批资料里出自 [[openai|OpenAI]] 的 harness engineering 文章，原本讲的是 [[context-files|context files]]：`AGENTS.md` 只有约 100 行，只作目录，指向结构化的 `docs/`，让 agent 从一个小而稳定的入口开始，被告知下一步去哪看（[[2026-11-20-openai-harness-engineering]]）。skills 的"清单在前、正文按需"是同一原则用在可复用知识上；把这个词用于 skills 是本页的归纳，资料没有这样用。

## 与 MCP 和 context files 的区别

| | skills | [[mcp\|MCP]] | [[context-files\|context files]] |
|---|---|---|---|
| 提供什么 | 知识与工作流说明 | 外部工具与数据源 | 项目约定与规则 |
| 何时进 context | 清单常驻，正文按需 | 默认把全部可用工具加载进 context | 每次启动 session 自动读取 |
| 来源 | [[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-openharness-readme]] | [[2026-11-20-context-management-in-claude-code]] | [[2026-11-20-the-claude-md-file]] |

- 官方视频的原话是 skills "与 MCP servers 类似，但不会把全部内容放进 context"（[[2026-11-20-context-management-in-claude-code]]）。来源页的评语是这个类比很粗；skills "不把全部内容放进 context" 的具体加载机制，视频没有说明。
- skill 的正文是给模型读的文字，可以附带脚本；Microsoft 文档里带脚本的 skill 要另配 script runner 才能执行（[[2026-11-20-microsoft-learn-agent-harness]]）。
- skill 也可以是驱动工具的操作说明：OpenAI 团队写了处理 DOM 快照、截图、导航的 skills，配合接入的 Chrome DevTools Protocol，让 [[codex|Codex]] 能复现 bug、验证修复（团队自述；[[2026-11-20-openai-harness-engineering]]）。

## 变体与演进

- **默认开还是关**：Microsoft 的 Agent Skills 在 .NET 和 Go 默认开启，Python 需通过 `skills_provider` 或 `skills_paths` 显式开启；文档没有解释为什么不一致（截至 2026-10-28；[[2026-11-20-microsoft-learn-agent-harness]]）。
- **运行时 skill 与"写 harness 用的 skill"**：Microsoft 文档特意区分运行时能力 Agent Skills 与 `agent-framework-builder-python`，后者是帮助 coding agent 编写 harness 应用的外部 skill（[[2026-11-20-microsoft-learn-agent-harness]]）。
- **作为分发单元的一部分**：[[pi|Pi]] 把 skills 列为四种定制手段之一，可打包进 Pi package（[[2026-11-20-pi-readme]]）；OpenHarness 的插件位置也能提供 skills（[[2026-11-20-openharness-readme]]）。见 [[plugins-and-extensibility]]。
- **嵌在仓库里**：OpenAI 团队的 skills 嵌在代码仓库中，与本地脚本一起作为 Codex 的标准开发工具（[[2026-11-20-openai-harness-engineering]]）。

## 优缺点和权衡

- **优点**：常驻 context 的只有清单，Go 练习仓库的测试把两个 skill 的清单压在 600 字符以内（[[2026-11-20-harness-engineering-go-practice]]）。
- **依赖模型自己判断何时加载**：清单里的描述写得不好，模型就不会去读正文（笔者推断；资料没有讨论 skill 未被触发的情况）。
- **不可信仓库的 skills 是攻击面**：项目级 skills 随仓库而来，其内容会作为指令进入模型的 context。OpenHarness 默认启用项目级 skills，对不可信仓库提供 `oh config set allow_project_skills false` 关闭（[[2026-11-20-openharness-readme]]）。这与 Crash Course 讲的 prompt injection 是同一类问题：仓库里的文件应被当作不可信数据（把两者联系起来是笔者推断；[[2026-11-20-ai-harness-crash-course]]）。其他项目是否有同类开关，资料没有说明。
- 没有资料给出 skills 对任务成功率或 context 占用的测量数据。

## 不同来源的分歧

> [!warning] 矛盾
> OpenHarness 的 README 对 skill 文件放哪里前后不一致：
> - "Skills System" 一节约定的布局是 `~/.openharness/skills/<skill>/SKILL.md`（一个 skill 一个目录），并说兼容 anthropics/skills 要用这种布局。
> - "Add a Custom Skill" 一节的示例路径却是 `~/.openharness/skills/my-skill.md`（单个文件）。
>
> 两处都在同一份 README 里（[[2026-11-20-openharness-readme]]）；`skills/` 目录的注释写的也是 "`.md` files"。是两种布局都支持还是示例过时，需要读源码确认。

- **定位的侧重点**：Claude Code 课程大纲强调"重复的工作流"（[[2026-11-20-claude-code-101-course]]）；同一门课的 context management 视频强调"省 context"（[[2026-11-20-context-management-in-claude-code]]）；OpenHarness 和 learn-claude-code 强调"知识"（[[2026-11-20-openharness-readme]]、[[2026-11-20-learn-claude-code-readme]]）。三者不冲突，但写 skill 时的取向不同。
- **归层**：learn-claude-code 网站把 Skill Loading 放在 "Planning & Control" 层（[[2026-11-20-learn-claude-code-site]]）；README 把它放在"扩展与组装"阶段，与 MCP 相邻（[[2026-11-20-learn-claude-code-readme]]）；OpenHarness 的 system prompt 组装目录 `prompts/` 同时负责 `CLAUDE.md` 和 skills（[[2026-11-20-openharness-readme]]）。

## 采用它的项目

| 项目 | 情况 | 来源 |
|---|---|---|
| [[claude-code\|Claude Code]] | 定制机制之一，有专课（正文未摄入） | [[2026-11-20-claude-code-101-course]] |
| [[openharness\|OpenHarness]] | `SKILL.md` 布局，多级发现路径；README 的可用 skill 列表举了 8 个并写 "40+ more"（自述） | [[2026-11-20-openharness-readme]] |
| [[microsoft-agent-framework\|Microsoft Agent Framework]] | Agent Skills，各 SDK 默认值不同 | [[2026-11-20-microsoft-learn-agent-harness]] |
| [[pi\|Pi]] | 四种定制手段之一，细节在未摄入的文档里 | [[2026-11-20-pi-readme]] |
| [[codex\|Codex]]（OpenAI 团队的用法） | 嵌在仓库里的 skills | [[2026-11-20-openai-harness-engineering]] |
| [[learn-claude-code]] | s07 Skill Loading | [[2026-11-20-learn-claude-code-readme]] |
| Go 练习仓库 | 第 10 课：清单进 prompt、正文按需读 | [[2026-11-20-harness-engineering-go-practice]] |
| [[deepseek-harness\|DeepSeek Harness]] | 从分支名 `feat/upstream-skills` 和 commit 里的 "review skill" 推断有 skills 机制 | [[2026-11-20-deepseek-harness-readme]] |
| [[learn-harness-engineering]] | 课程导航有 skills 一栏，内容未导出 | [[2026-11-20-learn-harness-engineering-course]] |

## 相关概念

[[context-files]]、[[mcp]]、[[system-prompt]]、[[context-management]]、[[plugins-and-extensibility]]、[[subagents]]（另一种省 context 的手段）、[[tools]]、[[sandboxing]]；横向比较见 [[开源-harness-设计取向对比]]。
