---
title: The CLAUDE.md file（Claude Code 101 视频）
type: source
kind: talk
aliases: [The CLAUDE.md file]
tags: [claude-code, agent-harness, context-files, memory, vendor-talk]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/yt-the-claude-md-file.md
author: Anthropic
url: https://www.youtube.com/watch?v=O0FGCxkHM-U
---

# The CLAUDE.md file（Claude Code 101 视频）

> [!note] 资料性质
> YouTube 视频的自动转录，有识别错误（"claw.md""cloud.md""clot.md" 都是 `CLAUDE.md`，"Nex.js15""Drizzle OM" 应为 Next.js 15、Drizzle ORM）。[[anthropic|Anthropic]] 对自家产品的介绍，属于厂商自述。转录中没有作者署名和发布日期。

## 一段话概括

`CLAUDE.md` 是放在项目根目录的 markdown 文件，[[claude-code|Claude Code]] 每次启动 session 时自动读取，为它提供关于项目的"持久记忆"，资料比作"codebase 的 onboarding script"。本片讲它的作用、示例内容、层级和三条维护建议。属于 [[context-files|context file]] 这一类机制。

## 要点

### 作用与机制

- 没有 `CLAUDE.md` 时，Claude Code 每次都从头开始：重新探索 codebase、弄清依赖和已实现的功能，有时只能靠假设，也更难被引导到正确方向。
- 机制的一句话描述："`CLAUDE.md` 的内容被 append 到你自己的 prompt 上"。
- `/init` 命令让 Claude 基于 codebase 生成一份。

### 示例内容（片中展示）

- 技术栈：Next.js 15 app，使用 App Router、Tailwind、Drizzle ORM。
- Commands：dev server、run tests、lint。
- Code style：两空格缩进；优先 named exports；所有 API routes 放在 `app/api`；能用 server actions 就不用 API routes。
- 效果（自述）：此后让它创建 React component，它直接知道用 Tailwind 写样式，不必先摸清项目。

### 层级

资料称存在 "hierarchy of memory files"，按受众区分，具体讲了两层：

| 层级 | 位置 | 用途 |
|---|---|---|
| project level | 项目根目录 | 随版本控制与团队共享 |
| user level | 用户的配置目录 | 只属于个人、跨所有项目生效；放个人偏好，如代码注释的写法 |

### 三条建议

1. 如果不得不纠正 Claude（例："始终用 server actions 而不是 API routes"），就明确要求 Claude 把它 save to memory，下次回到项目时它就知道。
2. 想让 Claude 参考项目内的文档，用 `@` 加文件路径引用。
3. 建议新项目**先不写** `CLAUDE.md`，观察哪些地方需要反复纠正 model，再据此补充；这样文件保持精简，只含必要信息。

- 起步顺序：先写 stack、preferences，再写 commands，之后边用边加。

## 值得记下的论据

- 没有数字或对照实验；"沮丧的 session 与高效的 session 的差别在于 context" 是作者主张。
- "append 到 prompt" 是对注入位置的唯一描述，没有区分是 [[system-prompt|system prompt]] 还是用户消息。

## 与已有知识的关系

- 印证 [[2026-11-20-claude-code-101-course]] 与 [[2026-11-20-context-management-in-claude-code]]：跨 session 要记住的东西放 `CLAUDE.md`。
- [[2026-11-20-explore-plan-code-commit-workflow]] 给出同一做法的另一个触发条件：Claude 反复遇到同一问题时，让它把解法存进 `CLAUDE.md`。
- 与 [[2026-11-20-hooks-in-claude-code]] 存在张力：本片说保存后 Claude "每次都会知道"，hooks 一课明说 `CLAUDE.md` 指令并非每次都被执行。
- 片内张力：既介绍 `/init` 自动生成，又建议新项目先不写、按纠错逐步积累；资料没有说明两者如何取舍。

## 遗留问题

- "hierarchy" 是否还有更多层级（如子目录级），以及各层冲突时的优先级，本片未说明。
- `CLAUDE.md` 过长时对 context window 的占用（[[context-management|context management]]）只以"保持精简"带过。
