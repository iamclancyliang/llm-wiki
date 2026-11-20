---
title: Hooks in Claude Code（Claude Code 101 视频）
type: source
kind: talk
aliases: [Hooks in Claude Code]
tags: [claude-code, agent-harness, hooks, permissions, vendor-talk]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: raw/agent-harness/yt-hooks-in-claude-code.md
author: Anthropic
url: https://www.youtube.com/watch?v=IkaPHiMDazM
---

# Hooks in Claude Code（Claude Code 101 视频）

> [!note] 资料性质
> YouTube 视频的自动转录，无标点且有识别错误（"Cloud Code""claw.md""rough""claude project dur" 即 Claude Code、`CLAUDE.md`、ruff、`CLAUDE_PROJECT_DIR`）。事件名和路径的规范写法是我根据读音还原的，已在文中标出。[[anthropic|Anthropic]] 对自家产品的介绍，属于厂商自述。转录中没有作者署名和发布日期。

## 一段话概括

[[hooks]] 让用户在 [[claude-code|Claude Code]] 生命周期的不同节点运行命令。与课程里其他机制的关键区别是 hooks 是 **deterministic**（确定性）的，每次必定执行；写在 `CLAUDE.md` 里的指令则只是"多数时候"被遵守。结语："必须每次都发生的事，不要放进 prompt，放进 hook。"

## 要点

### 为什么需要

- 例：在 `CLAUDE.md`（[[context-files|context file]]）里要求每次编辑后跑 prettier，Claude 多数时候会做，但有时不会；hook 则无例外。
- 常见用途：文件编辑后自动 format；记录所有执行过的命令以满足合规；阻止危险操作（如修改生产文件）；Claude 完成任务时发通知。

### 配置

在 `settings.json` 中配置，三个要素：选一个 event；可选的 matcher（限定适用于哪些 [[tools]]）；要运行的 command。片尾还提到可以通过 `/hooks` 配置。

| Event（规范写法为还原） | 触发时机 |
|---|---|
| `UserPromptSubmit` | 用户提交 prompt 后、Claude 处理之前 |
| `PreToolUse` | tool call 执行之前 |
| `PostToolUse` | tool call 完成之后 |
| `Notification` | Claude 发出通知时 |
| `Stop` | Claude 完成回复时 |

### 两个典型模式

- **编辑后自动 format**（"最常见的 hook"）：`PostToolUse` hook，matcher 为 `Edit` 或 `MultiEdit`，Claude 每次改文件都触发；command 检查文件扩展名并运行对应 formatter（TypeScript 用 prettier、Go 用 gofmt、Python 用 ruff）。
- **阻止 tool call**：`PreToolUse` hook 从 stdin 收到 JSON 形式的 tool name 和 input。
  - exit code `0`：放行。
  - exit code `2`：阻止该动作，stderr 的内容反馈给 Claude，让它知道为什么被拦并调整。
  - 用于硬性规则：阻止写入生产配置目录、阻止含 `rm -rf` 的 bash 命令、阻止某类 commit（转录为 "block commits domain"，推断是 "commits to main"，无法确认）。这是 [[permissions]] 之外的另一层强制手段。

### 团队共享

- 项目级 settings 文件中的 hooks 可以提交进 repo，全团队自动获得相同的 hooks。转录此处为 "include/ settings.json"，推断指 `.claude/settings.json`。
- 在 command 中使用环境变量 `CLAUDE_PROJECT_DIR` 引用存放在项目里的脚本，这样无论 Claude 当前工作目录在哪都能运行。

## 值得记下的论据

- "hooks 每次都执行、prompt 指令不保证执行"是全片的核心论点，是作者主张，没有给出遵守率数据。
- exit code 约定（0 放行、2 阻止并回传 stderr）是具体可验证的接口事实。

## 与已有知识的关系

- 印证 [[2026-11-20-claude-code-101-course]] 对 hooks 的定位（formatting、command blocking、notifications 的确定性护栏）。
- 与 [[2026-11-20-the-claude-md-file]] 存在张力：那里说把纠正保存到 memory 后 Claude "每次都会知道"，本片明说 `CLAUDE.md` 里的指令"不完美、有时不会执行"。

## 遗留问题

- 转录只列了 5 个 event，是否为全集未说明；`Stop`、`Notification`、`UserPromptSubmit` 的 hook 能否阻止或改写行为也未说明。
- hook 自身失败（非 0 非 2 的 exit code）时的行为未说明。
