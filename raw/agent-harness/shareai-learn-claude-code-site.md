Learn Claude Code
[Learn Claude Code](https://learn.shareai.run/zh/) [学习路径](https://learn.shareai.run/zh/timeline/) [版本对比](https://learn.shareai.run/zh/compare/) [架构层](https://learn.shareai.run/zh/layers/)
EN 中文 日本語

### Learn Claude Code

从 0 到 1 构建 nano Claude Code-like agent，每次只加一个机制
[开始学习 →](https://learn.shareai.run/zh/timeline/)

#### 核心模式

所有 AI 编程 Agent 共享同一个循环：调用模型、执行工具、回传结果。生产级系统会在其上叠加策略、权限和生命周期层。
agent\_loop.py

```
while True:
    response = client.messages.create(messages=messages, tools=tools)
    if response.stop_reason != "tool_use":
        break
    for tool_call in response.content:
        result = execute_tool(tool_call.name, tool_call.input)
        messages.append(result)
```

#### 消息增长

观察 Agent 循环执行时消息数组的增长
messages[] len= 6
user
assistant
tool\_call
tool\_result
assistant
tool\_call

#### 学习路径

20 个渐进式课程，从简单循环到完整多 Agent Harness
[s01 102 行

##### The Agent Loop

The smallest useful agent is a loop that calls the model, runs tools, and feeds results back.](https://learn.shareai.run/zh/s01/)
[s02 135 行

##### Tool Use

The loop stays stable while capabilities register into a dispatch table.](https://learn.shareai.run/zh/s02/)
[s03 180 行

##### Permission

Dangerous actions need a harness decision point before the shell runs.](https://learn.shareai.run/zh/s03/)
[s04 232 行

##### Hooks

Cross-cutting behavior belongs around the loop, not tangled inside it.](https://learn.shareai.run/zh/s04/)
[s05 236 行

##### TodoWrite

Explicit plans keep long-running work visible and correctable.](https://learn.shareai.run/zh/s05/)
[s06 304 行

##### Subagent

Subagents give each subtask a clean message history while preserving the main thread.](https://learn.shareai.run/zh/s06/)
[s07 335 行

##### Skill Loading

Inject specialized knowledge only when the task actually needs it.](https://learn.shareai.run/zh/s07/)
[s08 414 行

##### Context Compact

Compression keeps the conversation usable when the context window gets crowded.](https://learn.shareai.run/zh/s08/)
[s09 528 行

##### Memory

Some facts should survive summarization and future sessions.](https://learn.shareai.run/zh/s09/)
[s10 166 行

##### System Prompt

The system prompt is a generated product of policy, tools, skills, and context.](https://learn.shareai.run/zh/s10/)
[s11 287 行

##### Error Recovery

A robust harness classifies failures and decides what kind of retry is worthwhile.](https://learn.shareai.run/zh/s11/)
[s12 297 行

##### Task System

A task graph turns vague goals into ordered, observable work.](https://learn.shareai.run/zh/s12/)
[s13 379 行

##### Background Tasks

The agent can keep reasoning while slow work completes elsewhere.](https://learn.shareai.run/zh/s13/)
[s14 645 行

##### Cron Scheduler

Recurring work should be created by the harness, not remembered by the model.](https://learn.shareai.run/zh/s14/)
[s15 745 行

##### Agent Teams

Persistent teammates let work continue in parallel without stuffing every thought into one context.](https://learn.shareai.run/zh/s15/)
[s16 709 行

##### Team Protocols

Multi-agent systems need explicit message contracts, not vibes.](https://learn.shareai.run/zh/s16/)
[s17 648 行

##### Autonomous Agents

Teammates become useful when they can discover and claim work themselves.](https://learn.shareai.run/zh/s17/)
[s18 802 行

##### Worktree Isolation

Parallel agents need isolated filesystems as much as isolated conversations.](https://learn.shareai.run/zh/s18/)
[s19 835 行

##### MCP Tools

External services can become agent tools through a standard discovery and call protocol.](https://learn.shareai.run/zh/s19/)
[s20 1708 行

##### Comprehensive Agent

The final harness is still one loop, now surrounded by the systems that make it production-shaped.](https://learn.shareai.run/zh/s20/)

#### 架构层次

五个正交关注点组合成完整的 Agent

##### Tools & Execution

4 个版本
[s01: The Agent Loop](https://learn.shareai.run/zh/s01/) [s02: Tool Use](https://learn.shareai.run/zh/s02/) [s03: Permission](https://learn.shareai.run/zh/s03/) [s04: Hooks](https://learn.shareai.run/zh/s04/)

##### Planning & Control

5 个版本
[s05: TodoWrite](https://learn.shareai.run/zh/s05/) [s06: Subagent](https://learn.shareai.run/zh/s06/) [s07: Skill Loading](https://learn.shareai.run/zh/s07/) [s10: System Prompt](https://learn.shareai.run/zh/s10/) [s11: Error Recovery](https://learn.shareai.run/zh/s11/)

##### Memory Management

2 个版本
[s08: Context Compact](https://learn.shareai.run/zh/s08/) [s09: Memory](https://learn.shareai.run/zh/s09/)

##### Concurrency & Scheduling

2 个版本
[s13: Background Tasks](https://learn.shareai.run/zh/s13/) [s14: Cron Scheduler](https://learn.shareai.run/zh/s14/)

##### Multi-Agent Platform

7 个版本
[s12: Task System](https://learn.shareai.run/zh/s12/) [s15: Agent Teams](https://learn.shareai.run/zh/s15/) [s16: Team Protocols](https://learn.shareai.run/zh/s16/) [s17: Autonomous Agents](https://learn.shareai.run/zh/s17/) [s18: Worktree Isolation](https://learn.shareai.run/zh/s18/) [s19: MCP Tools](https://learn.shareai.run/zh/s19/) [s20: Comprehensive Agent](https://learn.shareai.run/zh/s20/)