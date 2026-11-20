---
title: Context files（上下文文件）
type: concept
aliases: [context file, 上下文文件, CLAUDE.md, AGENTS.md, memory files, 规则文件, 项目规则文件, agent 指令文件]
tags: [context-files, agent-harness, harness-engineering, memory, context-management]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-the-claude-md-file
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-learn-harness-engineering-course
  - 2026-11-20-claude-code-101-course
  - 2026-11-20-context-management-in-claude-code
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-openharness-readme
  - 2026-11-20-deepseek-harness-readme
  - 2026-11-20-pi-readme
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
---

# Context files（上下文文件）

## 定义

Context file 是放在仓库或用户配置目录里、由 [[agent-harness|agent harness]] 在会话开始时自动读入的 Markdown 文件，用来告诉 agent 这个项目的规矩。两个常见文件名是 `CLAUDE.md`（[[claude-code|Claude Code]]）和 `AGENTS.md`（[[codex|Codex]]、[[pi|Pi]]、[[deepseek-harness|DeepSeek Harness]] 等）。Claude Code 课程把 `CLAUDE.md` 比作"codebase 的 onboarding script"（[[2026-11-20-the-claude-md-file]]）；[[learn-harness-engineering|Learn Harness Engineering]] 课程把 `AGENTS.md` 放在闭环的第一个环节"明确目标"，作用是规则与边界（[[2026-11-20-learn-harness-engineering-course]]）。

## 要解决的问题和动机

- **每次都从头开始**。没有它时，agent 每个 session 都要重新探索 codebase、弄清依赖和已实现的功能，有时只能靠假设，也更难被引导（[[2026-11-20-the-claude-md-file]]）。把长期有效的信息写进去，免得每次重新发现，也节省 context（[[2026-11-20-context-management-in-claude-code]]）。
- **agent 看不到仓库之外的知识**。Slack 上达成的共识、人脑里的约定，如果没进仓库，对 agent 就不存在（[[2026-11-20-openai-harness-engineering]]）。
- **团队一致**。项目级文件随版本控制共享，全团队的 agent 拿到相同的规则（[[2026-11-20-the-claude-md-file]]）。

## 工作原理

### 加载方式

- Claude Code 每次启动 session 时自动读取项目根目录的 `CLAUDE.md`；机制的唯一描述是"内容被 append 到你自己的 prompt 上"，没有区分是 [[system-prompt|system prompt]] 还是用户消息（[[2026-11-20-the-claude-md-file]]）。
- Go 练习仓库的规格：`FindContextFiles(dir, root)` 从当前目录向上找 `AGENTS.md`，到项目根为止、不越过根（上面的属于别的项目）；找到的每个文件作为一段拼进 system prompt；读不出来要报错，不能悄悄漏掉（截至 2026-11-20 的快照为待实现的桩，规格来自测试）（[[2026-11-20-harness-engineering-go-practice]]）。
- [[openai|OpenAI]] 团队的 `AGENTS.md` "注入上下文"（[[2026-11-20-openai-harness-engineering]]）；[[openharness|OpenHarness]] 自述会发现并注入 `CLAUDE.md`（[[2026-11-20-openharness-readme]]）。
- 文件里可以引用别的文档：Claude Code 用 `@` 加文件路径（[[2026-11-20-the-claude-md-file]]）。

### 层级

| 层级 | 位置 | 用途 | 来源 |
|---|---|---|---|
| user level | 用户的配置目录 | 只属于个人、跨所有项目生效，放个人偏好（如代码注释的写法） | [[2026-11-20-the-claude-md-file]] |
| project level | 项目根目录 | 随版本控制与团队共享 | [[2026-11-20-the-claude-md-file]] |
| 目录链 | 从项目根到当前目录路径上的每个 `AGENTS.md` | 返回顺序从外到内，离当前目录越近的越靠后、越"说了算" | [[2026-11-20-harness-engineering-go-practice]] |

Claude Code 课程称这是 "hierarchy of memory files"，但只讲了前两层；是否还有子目录级、各层冲突时谁优先，课程没有说明（[[2026-11-20-the-claude-md-file]]）。目录链一行是 Go 练习仓库的规格，不能当作 Claude Code 的行为。

### 写什么

Claude Code 课程展示的示例（[[2026-11-20-the-claude-md-file]]）：

- 技术栈：Next.js 15、App Router、Tailwind、Drizzle ORM。
- Commands：dev server、run tests、lint。
- Code style：两空格缩进、优先 named exports、API routes 的位置、能用 server actions 就不用 API routes。

起步顺序是先写 stack 和 preferences，再写 commands，之后边用边加（[[2026-11-20-the-claude-md-file]]）。

### 写多长：目录还是百科

OpenAI 团队试过"一个巨大的 AGENTS.md"并判定失败，给出四条理由（单一团队的一手实践）（[[2026-11-20-openai-harness-engineering]]）：

1. **上下文是稀缺资源**：巨大的指令文件挤掉任务、代码和相关文档。
2. **过多指导等于没有指导**：一切都"重要"时，agent 只会做局部模式匹配。
3. **立刻腐烂**：变成陈旧规则的坟场，agent 无法判断哪些还有效。
4. **难以验证**：单个大文件无法做覆盖率、新鲜度、归属、交叉链接等机械检查。

最终做法是 `AGENTS.md` 约 100 行，只作目录，指向结构化的 `docs/`（design-docs、exec-plans、product-specs、references 等）和 `ARCHITECTURE.md`。作者称之为渐进式披露："给 Codex 一张地图，而不是一本 1000 页的说明书"（[[2026-11-20-openai-harness-engineering]]）。

其他资料的方向一致：

- Claude Code 课程建议保持精简、只含必要信息（[[2026-11-20-the-claude-md-file]]）。
- Learn Harness Engineering 的 L04 标题是"把指令拆分到不同文件里"，英文 slug 是 "why one giant instruction file fails"（仅标题，正文未摄入）（[[2026-11-20-learn-harness-engineering-course]]）。
- 运行时一侧的同构做法是 [[skills]]：system prompt 里只列目录，正文按需读取（[[2026-11-20-harness-engineering-go-practice]]）。

### 怎么维护

- **按纠错积累**：不得不纠正 agent 时，明确要求它把这条 save to memory（[[2026-11-20-the-claude-md-file]]）；agent 反复遇到同一问题时，让它把解法存进 `CLAUDE.md`（[[2026-11-20-explore-plan-code-commit-workflow]]）。
- **由 agent 生成**：Claude Code 的 `/init` 基于 codebase 生成一份（[[2026-11-20-the-claude-md-file]]）；OpenAI 团队最初的 `AGENTS.md` 也是 Codex 写的（团队自述）（[[2026-11-20-openai-harness-engineering]]）。
- **机械保鲜**：OpenAI 团队用专门的 linter 和 CI 作业检查知识库是否更新、是否交叉链接、结构是否正确，并定期运行 doc-gardening agent 扫描过时文档、开修复 PR（[[2026-11-20-openai-harness-engineering]]）。见 [[harness-engineering]]。

## 变体与演进

- **文件名的并存与桥接**：DeepSeek Harness 仓库的 README 写"For agents, follow AGENTS.md"，并在首个提交里把 `CLAUDE.md` 建成指向 `AGENTS.md` 的 symlink（[[2026-11-20-deepseek-harness-readme]]）。OpenHarness 直接沿用 `CLAUDE.md`（[[2026-11-20-openharness-readme]]）。
- **读者是谁**：Pi 的 README 说仓库根的 `AGENTS.md` 是"项目专属规则（对人和 agent 都适用）"（[[2026-11-20-pi-readme]]）；OpenAI 团队的 `AGENTS.md` 是给 agent 的目录（[[2026-11-20-openai-harness-engineering]]）。
- **从规则文件到一组文件**：Learn Harness Engineering 的模板把规则（`AGENTS.md`）、任务范围（`feature_list.json`）和进度（`claude-progress.md`）分成不同文件（[[2026-11-20-learn-harness-engineering-course]]）。后两者是 agent 自己读写的状态文件，不是自动注入的规则；[[anthropic|Anthropic]] 的长时运行做法里，它们靠 prompt 要求 agent 在每个 session 开场主动去读（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）。见 [[long-running-agents]]。

### "memory files" 的说法

Claude Code 课程把 `CLAUDE.md` 称为"持久记忆"和 "memory files"，课程大纲说它是"跨 session 的项目记忆"（[[2026-11-20-the-claude-md-file]]、[[2026-11-20-claude-code-101-course]]）。其他资料把这两件事分开：

- OpenHarness 同时有 `CLAUDE.md`（注入的上下文文件）和 `MEMORY.md`（跨会话持久记忆）（[[2026-11-20-openharness-readme]]）。
- AI Harness Crash Course 里的 long-term memory 指从对话里提炼出的事实，在未来的对话里被检索出来加入上下文（[[2026-11-20-ai-harness-crash-course]]）。
- [[microsoft-agent-framework|Microsoft Agent Framework]] 的文件记忆是一个按 session 隔离的内建 provider；该文档没有提到 `AGENTS.md` 一类的上下文文件，但不能据此断定框架不支持（[[2026-11-20-microsoft-learn-agent-harness]]）。

可以这样区分（笔者归纳）：context file 是人或 agent 显式维护、每次整份注入的规则；[[memory|记忆]]是系统提炼、按需检索的事实。Claude Code 的"save to memory"把纠错写回 `CLAUDE.md`，正好落在两者的交界处。

## 优缺点和权衡

- **可靠性有限，是提示不是强制**。Claude Code 课程的例子：在 `CLAUDE.md` 里要求每次编辑后跑 prettier，Claude 多数时候会做，但有时不会；[[hooks]] 是确定性的，每次必定执行。结语是"必须每次都发生的事，不要放进 prompt，放进 hook"（厂商自述，无遵守率数据）（[[2026-11-20-hooks-in-claude-code]]）。OpenAI 团队的说法是"文档不够时，把规则变成代码"，用 linter 和结构测试强制不变量（[[2026-11-20-openai-harness-engineering]]）。

| | context file | hooks / linter |
|---|---|---|
| 执行方 | 模型读了之后自己决定是否照做 | harness 或 CI 执行 |
| 可靠性 | "多数时候" | 每次 |
| 适合 | 约定、偏好、导航信息 | formatting、阻止危险操作、架构不变量 |

（[[2026-11-20-hooks-in-claude-code]]、[[2026-11-20-openai-harness-engineering]]）

- **占用上下文**。每个 session 都整份加载，写长了挤占任务空间；课程只以"保持精简"带过（[[2026-11-20-the-claude-md-file]]）。
- **会腐烂**。规则随代码演进而过时，需要机械检查或专人（专 agent）维护（[[2026-11-20-openai-harness-engineering]]）。
- **信任问题**（笔者推断）。Crash Course 提醒仓库里的文件可能含有恶意指令，应当作不可信数据（[[2026-11-20-ai-harness-crash-course]]）；OpenHarness 为此允许关闭不可信仓库的项目级 skills（[[2026-11-20-openharness-readme]]）。自动注入的 context file 面临同样的风险，但本批资料没有讨论这一点。

## 不同来源的分歧

> [!warning] 矛盾
> **写进去的指令会不会每次生效。** `CLAUDE.md` 一课说把纠正保存到 memory 后，下次回到项目 Claude "每次都会知道"（[[2026-11-20-the-claude-md-file]]）；同一门课的 hooks 一课明说 `CLAUDE.md` 里的指令只是"多数时候"被遵守、有时不会执行（[[2026-11-20-hooks-in-claude-code]]）。两者都是 Anthropic 的厂商自述，后者与其他资料"控制要靠软件强制"的论点一致（[[2026-11-20-ai-harness-crash-course]]）。

> [!warning] 矛盾
> **新项目该不该一开始就生成。** 同一支视频既介绍 `/init` 自动生成，又建议新项目先不写 `CLAUDE.md`、观察哪里需要反复纠正再补充，没有说明两者如何取舍（[[2026-11-20-the-claude-md-file]]）。OpenAI 团队的做法是开局就让 Codex 写出初始 `AGENTS.md`（[[2026-11-20-openai-harness-engineering]]）。

- **内容取向**：Claude Code 课程的示例把技术栈、命令、代码风格直接写在文件里（[[2026-11-20-the-claude-md-file]]）；OpenAI 团队只放目录，实质内容都在 `docs/`（[[2026-11-20-openai-harness-engineering]]）。两者规模差别很大（入门示例对百万行仓库），不一定冲突。
- **注入位置**：见 [[system-prompt]] 的分歧一节。

## 采用它的项目

- `CLAUDE.md`：[[claude-code|Claude Code]]（[[2026-11-20-the-claude-md-file]]）、[[openharness|OpenHarness]]（[[2026-11-20-openharness-readme]]）。
- `AGENTS.md`：OpenAI 团队的 [[codex|Codex]] 仓库（[[2026-11-20-openai-harness-engineering]]）、[[pi|Pi]]（[[2026-11-20-pi-readme]]）、[[deepseek-harness|DeepSeek Harness]]（[[2026-11-20-deepseek-harness-readme]]）、[[learn-harness-engineering]] 的模板（[[2026-11-20-learn-harness-engineering-course]]）、Go 练习仓库（[[2026-11-20-harness-engineering-go-practice]]）。

## 相关概念

[[system-prompt]]、[[memory]]、[[hooks]]、[[skills]]、[[context-management]]、[[harness-engineering]]、[[long-running-agents]]、[[planning-and-plan-mode]]、[[agent-harness]]、[[permissions]]
