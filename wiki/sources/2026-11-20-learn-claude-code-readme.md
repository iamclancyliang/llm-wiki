---
title: learn-claude-code 仓库 README（shareAI-lab）
type: source
kind: repo
aliases: [learn-claude-code README, "Bash is all you need", shareAI-lab learn-claude-code]
tags: [agent-harness, harness-engineering, tutorial, claude-code, python]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/github-shareai-learn-claude-code.md
author: shareAI-lab（64 位贡献者）
url: https://github.com/shareAI-lab/learn-claude-code
---

# learn-claude-code 仓库 README（shareAI-lab）

> 资料是 2026-11-20 导出的 GitHub 仓库首页纯文本（含页面导航、文件列表和 README 全文）。README 没有标注发布日期，所以 frontmatter 不填 `published`；下文的"截至 2026-11-20"均指导出当天页面上的状态。

## 一段话概括

[[learn-claude-code]] 是一个教学仓库，副标题是 "Bash is all you need — A nano claude code–like agent harness, built from 0 to 1"。它用 17 个渐进章节（`s01`–`s17`，每章一个可独立运行的 `code.py`）从一个 `while True` 循环出发，每章只加一个机制，最终拼出一个类似 [[claude-code|Claude Code]] 的 [[agent-harness|agent harness]]。README 的前半部分是一篇立场鲜明的宣言：agency（感知、推理、行动的能力）来自模型训练，不来自外部代码编排；工程师能做的是 [[harness-engineering|harness engineering]]，即给模型造"车"，而模型是"司机"。

## 解决什么问题

- 面向想理解 coding agent 内部构造的工程师：不读 Claude Code 源码，而是"抓住关键设计，自己写一遍"（README 结尾原话的意思）。
- 纠正一个作者认为普遍存在的误解：把"用 if-else、节点图、prompt chain 把 LLM API 串起来"当成"构建 agent"。

## 作者主张（未经本资料验证）

以下都是作者的立场或自述，README 没有给出实验支撑：

1. **Agency 是训练出来的，不是编码出来的。** 论据是一串历史里程碑：DeepMind DQN（2013，7 个 Atari 游戏；2015 扩展到 49 个）、OpenAI Five（2019，自对弈 45,000 年、公开赛 42,729 场胜率 99.4%）、AlphaStar（2019，欧服 Grandmaster，前 0.15%）、腾讯"绝悟"（2019）、2024–2025 的 LLM coding agent。这些数字是 README 转引的，各自带外链，本页未逐一核对原始出处。
2. **"Agent" 一词被 prompt 编排行业劫持。** 拖拽式工作流、no-code agent 平台、prompt chain 库被称为 "Rube Goldberg machines"、"shell script with grandiose pretensions"。这是与 [[workflows-vs-agents]] 话题直接相关的强立场，措辞带明显修辞色彩。
3. **Agent 产品 = Model + Harness**，并给出 harness 的组成公式：

   ```
   Harness = Tools + Knowledge + Observation + Action Interfaces + Permissions
   ```

   （出处：README "The Mindshift" 一节）

4. **Claude Code 是"最优雅、最完整的 agent harness 实现"**，理由是它"不做什么"：不替模型做决策、不强加固定工作流、不用手写决策树代替模型判断。这是作者评价，不是比较实验的结论。
5. **s05 的格言里说"先列步骤，完成率翻倍"（completion rate doubles）。** 没有给出任务集、指标或对照条件，按 wiki 约定只能当作未证实的自述。
6. **部署轨迹是训练信号。** harness 工程师的职责之一是收集 trajectory data，用于微调下一代模型。

## 架构与关键设计决策

**不变的核心：[[agent-loop|agent loop]]。** README 给出的最小实现（Anthropic Messages API 形态）：

```python
def agent_loop(messages):
    while True:
        response = client.messages.create(model=MODEL, system=SYSTEM,
                                          messages=messages, tools=TOOLS)
        messages.append({"role": "assistant", "content": response.content})
        tool_calls = [b for b in response.content if b.type == "tool_use"]
        if not tool_calls:
            return
        results = [{"type": "tool_result", "tool_use_id": b.id,
                    "content": TOOL_HANDLERS[b.name](**b.input)} for b in tool_calls]
        messages.append({"role": "user", "content": results})
```

（出处：README "Core Pattern"，此处为等价压缩写法）

设计上的要点：停不停由模型决定（响应里没有 `tool_use` 块就返回）；代码只负责执行模型请求的工具并把结果追加回 `messages[]`。README 的总结句是 "The loop belongs to the agent. The mechanisms belong to the harness."

**README 对 Claude Code 的拆解**（作者归纳，不是 [[anthropic|Anthropic]] 官方描述）：一个 agent loop + 工具（bash、read、write、edit、glob、grep、browser…）+ 按需加载 skill + context compaction + subagent + 带依赖图的 task system + 异步 mailbox 团队协作 + 绑定任务的 worktree + 权限治理 + hooks + memory 持久化 + MCP 外部能力路由。

**17 章各自的机制**（格言与关键概念均来自 README 的章节表）：

| 章 | 主题 | 机制要点 |
|---|---|---|
| s01 | Agent Loop | `messages` / `while True` / `tool_use`；一个工具（bash）加一个循环 |
| s02 | Tool Use | [[tools\|工具]]注册进 `TOOL_HANDLERS` dispatch map，循环本身不动；涉及并发 |
| s03 | Permission | [[permissions\|权限]]：`PermissionRule` / approval pipeline，区分可执行、必须拦下、需要审批 |
| s04 | Hooks | [[hooks]]：`PreToolUse` / `PostToolUse`，"围着循环挂，不改循环" |
| s05 | TodoWrite | `TodoItem`，plan-then-execute |
| s06 | Subagent | [[subagents\|subagent]]：全新的 `messages[]`，只把最终文本作为一条 tool result 返回 |
| s07 | Skill Loading | [[skills\|skill]]：`SkillLoader` 先列目录，用到时才展开注入 |
| s08 | Context Compact | [[compaction]]：`tool_result_budget` / `snip_compact` / `micro_compact` / `compact_history` 四步，先削减工具结果，仍超限再总结历史 |
| s09 | Memory | selection / extraction / consolidation 三个子系统 |
| s10 | Task System | `TaskRecord` / `blockedBy` / 落盘的任务图 |
| s11 | Background Tasks | 后台线程执行慢命令，完成后通过 notification queue 注入 |
| s12 | Cron Scheduler | durable scheduling / session-scoped triggers |
| s13 | Agent Teams | 常驻队友、原子化任务认领、task-bound worktrees、typed protocols |
| s14 | MCP Plugin | [[mcp\|MCP]]：tool discovery、带命名空间的工具、合并进同一个 tool pool |
| s15 | Integrated Harness | 把前面的机制接回同一个循环 |
| s16 | Workflow Runtime | "编排形状固定时就写进代码"：脚本编排、lifecycle events、可恢复的 journal |
| s17 | Goal Loop | goal gate：独立 evaluator 审查每次"想停"；不可能、失败或超限的目标把控制权交还用户 |

**学习路径分七个阶段**：让 agent 行动（s01–s04）→ 处理复杂工作（s05、s06、s08）→ 跨会话记忆（s09）→ 跑长任务（s10–s12）→ 多 agent 协作（s13）→ 扩展与组装（s07、s14、s15）→ 编排与目标闭环（s16、s17）。s08 和 s09 对应 [[context-management|上下文管理]]，s10–s12 与 s17 对应 [[long-running-agents|长时间运行的 agent]]。

**课程边界**：s15 是累积式运行时；s16 在其上加 workflow 编排；s17 用更小的工具集单独演示"目标控制的继续执行"，README 明确说它是机制示例，不是又一个累积运行时。

**两条轨道并存**：根目录 `s01_*`–`s17_*` 是当前规范版本；`docs/` 与 `agents/` 保留旧的 12 课版本（含 `agents/s_full.py`）。README 给了新旧映射表：旧 s03→新 s05（TodoWrite）、旧 s04→新 s06、旧 s05→新 s07、旧 s06→新 s08、旧 s07→新 s10、旧 s08→新 s11、旧 s09–s12 全部并入新 s13；新增的是 s03 Permission、s04 Hooks、s09 Memory、s12 Cron、s14 MCP、s15–s17。

## 适用与不适用的场景

- 适用：从零理解 harness 各机制如何围绕一个循环叠加；每章单文件可运行，便于对照自己的实现。
- 不适用（README 自述）：这里教的是"用完即弃"式 harness（开终端、给任务、关掉，下次重新开始）。常驻型助手所需的 heartbeat（每 30 秒唤醒一次）、cron 自调度、IM 多渠道路由等放在姊妹仓库 claw0 里，以 OpenClaw 为参照。
- 推断：教学代码以可读为先，README 没有声称它具备生产级的隔离或安全性；s03 的权限机制是教学实现。

## 成熟度（截至 2026-11-20 页面快照）

- Star 80.6k、Fork 12.9k、Watcher 307；252 次提交，64 位贡献者；Issues 36、PR 20；12 个分支，0 个 tag（没有版本号）。
- 语言：Python 70.4%、TypeScript 28.8%（`web/` 是从根目录课程生成的网站，`npm run dev` 起在 `localhost:3000`）。
- 许可证 MIT。最近提交是导出前 3 天的 `448c75b`（"fix: workflow discovery and guarded owned-task recovery"），s13–s16 仍在被修；文件列表里最早的提交约在 9 个月前，提交说明写的是"11 progressive sessions"，可见课程从 11 课扩到 12 课再到 17 课。
- 依赖 `ANTHROPIC_API_KEY`；`.env.example` 的提交说明提到"provider compatibility limits"，具体限制 README 未展开。
- 后续产品（自述）：Kode Agent CLI（`@shareai-lab/kode`）与 Kode Agent SDK。

## 与已有知识的关系

- 补充：给出一份"Claude Code 由哪些 harness 机制组成"的清单，可作为各概念页的索引骨架。
- 分歧：对 workflow 的态度前后有张力。宣言部分把节点图和硬编码路由斥为"不是 agent"，但 s16 又主张"编排形状固定时就写进代码"。两者可以调和（模型在节点内自主、形状固定的部分交给代码），但 README 没有明确说明边界在哪。
- 分歧：章节数与配套网站不一致，见 `2026-11-20-learn-claude-code-site`（网站列 20 课，含 README 当前轨道里没有的 System Prompt、Error Recovery）。

## 涉及的实体和概念

实体：[[learn-claude-code]]、[[claude-code]]、[[anthropic]]、[[openai]]（仅作为历史里程碑和"agent"定义的引用方出现）。
概念：[[agent-harness]]、[[harness-engineering]]、[[agent-loop]]、[[tools]]、[[permissions]]、[[hooks]]、[[subagents]]、[[skills]]、[[compaction]]、[[context-management]]、[[long-running-agents]]、[[mcp]]、[[workflows-vs-agents]]。

## 局限与遗留问题

- 导出只有仓库首页，各章 README 和 `code.py` 均未摄入；表里的"机制要点"只是关键词，四步 compaction、memory 三子系统、team 协议的具体做法需要读章节原文才能写进概念页。
- "Claude Code = …" 清单是作者的逆向归纳，是否与 Claude Code 的实际实现一致，本资料无法证明。
- "完成率翻倍"没有出处。
- s17 的独立 evaluator 用什么判据、与 s05 TodoWrite 的关系是什么，README 没有说明。
- README 把 harness 定义为五要素，没有把 [[verification-and-observability|验证与可观测性]]单列（Observation 指的是模型看到的环境反馈），这与其他课程把"验证"当作 harness 核心的框架不同，值得在概念页对比。
