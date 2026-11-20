---
title: Tools（工具）
type: concept
aliases: [工具, tool use, tool calling, function calling, agent-computer interface, ACI, 工具执行管线]
tags: [tools, agent-harness, tool-design, aci]
created: 2026-11-20
updated: 2026-11-20
sources:
  - 2026-11-20-anthropic-building-effective-agents
  - 2026-11-20-harness-engineering-go-practice
  - 2026-11-20-openharness-readme
  - 2026-11-20-deepseek-harness-agent-loop-source
  - 2026-11-20-microsoft-learn-agent-harness
  - 2026-11-20-learn-claude-code-readme
  - 2026-11-20-learn-claude-code-site
  - 2026-11-20-how-claude-code-works
  - 2026-11-20-hooks-in-claude-code
  - 2026-11-20-context-management-in-claude-code
  - 2026-11-20-ai-harness-crash-course
  - 2026-11-20-anthropic-effective-harnesses-for-long-running-agents
  - 2026-11-20-openai-harness-engineering
  - 2026-11-20-explore-plan-code-commit-workflow
  - 2026-11-20-pi-readme
---

# Tools（工具）

## 定义

工具是 [[agent-harness|agent harness]] 暴露给模型的动作接口：模型在回复里请求调用某个工具并给出参数，harness 负责执行并把结果回传。模型"决定要改文件"并不会改文件，得有工具去执行（[[2026-11-20-ai-harness-crash-course]]）。[[claude-code|Claude Code]] 课程称工具是"agent 工作方式的支柱"（[[2026-11-20-how-claude-code-works]]）。

Agent-computer interface（ACI）是 [[anthropic|Anthropic]] 提出的说法：像设计人机界面那样设计给模型用的工具接口（[[2026-11-20-anthropic-building-effective-agents]]）。

## 要解决的问题和动机

- 没有工具的模型只能文本进、文本出；工具让它读文件、跑命令、搜索 web，并用真实结果决定下一步（[[2026-11-20-how-claude-code-works]]）。
- 工具结果是 [[agent-loop|agent loop]] 里的 ground truth 来源（[[2026-11-20-anthropic-building-effective-agents]]）。
- 既然 agent 的实现往往很直白，**工具集及其文档的设计才是关键**。Anthropic 做 SWE-bench agent 时，花在优化工具上的时间多于整体 prompt（有具体实践支撑，未给量化数字）（[[2026-11-20-anthropic-building-effective-agents]]）。

## 工作原理

### 定义与注册

一个工具通常是"给模型看的规格"加"给 harness 调的函数"：

- Go 练习仓库：`Tool{Spec llm.ToolSpec; Run func(ctx, args json.RawMessage) (string, error)}`（[[2026-11-20-harness-engineering-go-practice]]）。
- [[openharness|OpenHarness]]（项目自述）：每个工具有 Pydantic 输入校验、自描述 JSON Schema、权限集成和 hook 支持；自定义工具继承 `BaseTool`，声明 `name`、`description`、`input_model`，实现 `execute`（[[2026-11-20-openharness-readme]]）。
- [[learn-claude-code]]：工具注册进 `TOOL_HANDLERS` dispatch map，循环本身不动（[[2026-11-20-learn-claude-code-readme]]）。
- 外部工具经 [[mcp|MCP]] server 接入，它给应用一个标准方式去发现和调用 server 暴露的工具（[[2026-11-20-ai-harness-crash-course]]）。
- [[deepseek-harness|DeepSeek Harness]]：每个 step 开始前解析出本 step 的 `toolSet`，step 结束后释放；声明给模型的工具和实际可分发的工具是同一份。工具集增减时往日志追加一条 `developer/message` 告知模型（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

### 执行管线

从模型发出请求到结果回到历史之间，各实现插入的环节大体相同：

| 环节 | 做法 | 来源 |
|---|---|---|
| 权限裁决 | Allow / Deny / Ask；拒绝优先于放行；无人值守时 Ask 按拒绝处理 | [[2026-11-20-harness-engineering-go-practice]] |
| 执行前 hook | 可拦截，拦截理由成为工具结果；Claude Code 的 `PreToolUse` 以 exit code 2 阻止并把 stderr 反馈给模型 | [[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-hooks-in-claude-code]] |
| 执行 | 一个 step 的全部 tool call 作为一个批次交给工具服务，并发度由 `maxParallelToolCalls` 控制 | [[2026-11-20-deepseek-harness-agent-loop-source]] |
| 执行后 hook | 可改写结果，例如抹掉输出里的密钥；Claude Code 用 `PostToolUse` 在编辑后自动 format | [[2026-11-20-harness-engineering-go-practice]]、[[2026-11-20-hooks-in-claude-code]] |
| 截断与回传 | 超长输出截断并明示；结果按 ID 与请求配对 | [[2026-11-20-harness-engineering-go-practice]] |

OpenHarness README 把这条管线写成"权限检查 → PreToolUse hook → 执行 → PostToolUse hook → 结果"（示意伪代码，非源码）（[[2026-11-20-openharness-readme]]）。Go 练习仓库固定了顺序约定：权限在前、hook 在后，权限已拒绝的调用不再触发执行前 hook（[[2026-11-20-harness-engineering-go-practice]]）。详见 [[permissions]] 与 [[hooks]]。

工具还可以反过来影响循环：DeepSeek Harness 的工具能返回 `additionalContexts`（排进 next-step 队列，下一步作为用户侧消息进入），也能让结果 `concluded` 为真从而宣告 turn 结束（[[2026-11-20-deepseek-harness-agent-loop-source]]）。

### 错误是给模型的信息

Go 练习仓库的规格：模型请求了不存在的工具（测试里故意拼错成 `read_flie`），循环不崩溃，回一条结果，内容包含错误的名字和所有可用工具名；工具返回错误时错误文字成为结果；`bash` 把命令失败也当结果返回，注释是"命令失败也是 ground truth"（[[2026-11-20-harness-engineering-go-practice]]）。被拦截的调用同理：拦截原因要反馈给模型，让它知道为什么并调整（[[2026-11-20-hooks-in-claude-code]]）。见 [[error-recovery]]。

### 输出截断

- Go 练习仓库：`Truncate` 按 rune 截断（中文不能按字节切），上限 `MaxToolOutput = 20000` 字符，并追加一句"输出太长，已截断：共 N 个字符，只保留了前 max 个"。断言强调必须告诉模型内容不完整，"否则它会以为看到了全部"（[[2026-11-20-harness-engineering-go-practice]]）。
- 工具结果也是 [[compaction]] 的首要削减对象：learn-claude-code 的 s08 先削减工具结果，仍超限再总结历史（只有章节表里的关键词）（[[2026-11-20-learn-claude-code-readme]]）；Claude Code 的自动 compaction 会移除不必要的 tool call 结果（[[2026-11-20-context-management-in-claude-code]]）。
- 搜索类工具用预算代替截断：Microsoft 的 `file_access_grep` 限制 pattern 最长 256 字符、整次搜索 10 秒，超限返回错误并建议缩小范围（[[2026-11-20-microsoft-learn-agent-harness]]）。

### 文件读、写、编辑工具的设计

| 设计点 | 做法 | 目的 | 来源 |
|---|---|---|---|
| 分页读取 | `ReadLines` 带行号，默认一次 200 行，后面还有内容时提示用 `offset` | 不让一个大文件撑爆上下文，并告诉模型怎么继续 | [[2026-11-20-harness-engineering-go-practice]] |
| 字符串替换式编辑 | `edit_file` 要求 `old_text` 在文件里恰好出现一次，零次或多次都返回带指引的错误 | 避免改错位置 | [[2026-11-20-harness-engineering-go-practice]] |
| 行号式编辑 | grep 找 1-based 行号 → 读闭区间（每行带"行号 + tab"前缀）→ 整行替换并传入 `expected_line` | `expected_line` 防止行号过期或错位时改错行 | [[2026-11-20-microsoft-learn-agent-harness]] |
| 绝对路径 | 工具始终要求绝对路径 | agent 离开根目录后相对路径会出错；改后作者称模型"用得毫无差错"（无量化数字） | [[2026-11-20-anthropic-building-effective-agents]] |

两种编辑协议都在回避 Anthropic 指出的那类格式开销：写 diff 需要在写新代码之前就知道 chunk header 里的行数；在 JSON 里写代码比在 markdown 里多出换行和引号转义（[[2026-11-20-anthropic-building-effective-agents]]）。说两者"都在回避"是笔者的归纳，Go 仓库和 Microsoft 文档没有引用 Anthropic 的论述。

### ACI 原则

Anthropic 附录 2 的要点（[[2026-11-20-anthropic-building-effective-agents]]）：

- 工具定义应得到与整体 prompt 同等的 prompt engineering 投入。
- 选格式：给模型足够 token 先"思考"；格式贴近模型在互联网文本中自然见过的样子；消除格式开销（精确计数、字符串转义）。
- 好的工具定义包含示例用法、边界情况、输入格式要求、与其他工具的界限；像给 junior developer 写 docstring 那样改参数名和描述。
- 跑大量样例看模型怎么犯错再迭代；用 poka-yoke（防呆）改参数，让错误更难发生。绝对路径就是一个例子。

### Bash 作为通用工具

- learn-claude-code 的副标题是 "Bash is all you need"，s01 只用一个工具（bash）加一个循环（[[2026-11-20-learn-claude-code-readme]]）。
- 代价是它绕过了所有专用工具的约束：Go 练习仓库的 README 警告，完成权限一课之前 `bash` 没有任何检查；`bash` 自带 30 秒超时（[[2026-11-20-harness-engineering-go-practice]]）。网站一版把权限的动机写成"危险操作在 shell 执行前需要一个 harness 决策点"（[[2026-11-20-learn-claude-code-site]]）。
- 因此 shell 往往被单独对待：Microsoft 的 shell 执行不在默认能力里，来自预发布的工具包（截至 2026-10-28）（[[2026-11-20-microsoft-learn-agent-harness]]）；[[pi|Pi]] 的一种隔离模式把内置工具和 `!` 命令路由进本地 micro-VM，凭据留在宿主机（[[2026-11-20-pi-readme]]）。见 [[sandboxing]]。

## 变体与演进

- **工具集的规模**：从一个 bash，到 learn-claude-code 归纳的 Claude Code 工具集（bash、read、write、edit、glob、grep、browser 等，作者的逆向归纳）（[[2026-11-20-learn-claude-code-readme]]），到 OpenHarness 自述的 43 个工具（[[2026-11-20-openharness-readme]]）。Pi 的"强力默认值"具体含哪些工具，README 未列（[[2026-11-20-pi-readme]]）。
- **工具定义占用上下文**：Claude Code 里 MCP server 默认把全部可用工具加载进 context，与项目无关的 server 应关掉；[[skills]] "不会把全部内容放进 context"（厂商自述，加载机制未说明）（[[2026-11-20-context-management-in-claude-code]]）。
- **命名空间**：多个文件访问 provider 并存时用 `tool_name_prefix` 避免工具名冲突，审批规则要匹配带前缀的名字（[[2026-11-20-microsoft-learn-agent-harness]]）。
- **把别的机制包装成工具**：[[subagents|subagent]] 是一个名为 `task` 的工具（[[2026-11-20-harness-engineering-go-practice]]）；OpenHarness 把模式切换也做成工具（`EnterPlanMode`、`ExitPlanMode`）（[[2026-11-20-openharness-readme]]）。
- **用于验证的工具**：浏览器自动化让 agent 像人类用户那样测试。Anthropic 用 Puppeteer MCP server，称其"显著提升了表现"（无量化数据），已知盲区是看不到浏览器原生 alert modal（[[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]]）；[[openai|OpenAI]] 团队接入 Chrome DevTools Protocol（[[2026-11-20-openai-harness-engineering]]）；Claude Code 课程推荐 Claude in Chrome extension（[[2026-11-20-explore-plan-code-commit-workflow]]）。见 [[verification-and-observability]]。

## 优缺点和权衡

- 专用工具对比 bash：专用工具能做输入校验、防呆和细粒度权限，但要逐个设计和维护；bash 通用，但安全边界只能靠[[permissions|权限]]规则或 [[sandboxing|沙箱]]。Go 练习仓库的字符串前缀规则容易被绕过（如 `ls; curl … | sh` 因以 `ls` 开头而放行），这是来源页读代码后的推断（[[2026-11-20-harness-engineering-go-practice]]）。
- 工具越多能力越强，但每个定义都占上下文（[[2026-11-20-context-management-in-claude-code]]）。
- 工具输出会离开本机：即使工具在本地运行，输出也可能被发给托管模型，还可能存进 session 历史、日志或长期记忆（[[2026-11-20-ai-harness-crash-course]]）。
- 工具读到的内容是不可信数据："agent 在文件里读到一条指令，不代表它应该照做"（[[2026-11-20-ai-harness-crash-course]]）。

## 不同来源的分歧

> [!warning] 矛盾
> **并行还是串行。** OpenHarness 自述支持"并行工具执行"，但同一份 README 的伪代码是串行 `for`，两者如何对应没有说明（[[2026-11-20-openharness-readme]]）。DeepSeek Harness 有明确的并发度配置 `maxParallelToolCalls`（[[2026-11-20-deepseek-harness-agent-loop-source]]）；Go 练习仓库串行执行（[[2026-11-20-harness-engineering-go-practice]]）。

- **管线放在哪**：OpenHarness 的伪代码把权限和 hook 写在循环里（[[2026-11-20-openharness-readme]]）；DeepSeek Harness 的 loop 把整个批次外包给工具服务，loop 文件里没有 PreToolUse / PostToolUse 级别的事件（[[2026-11-20-deepseek-harness-agent-loop-source]]）。见 [[agent-loop]]。
- **接口设计的范围**：Anthropic 的 ACI 讲的是工具定义（[[2026-11-20-anthropic-building-effective-agents]]）；OpenAI 把同一思路推到 lint 错误信息、文档和可观测性栈（[[2026-11-20-openai-harness-engineering]]）。见 [[harness-engineering]]。
- **存疑**：Claude Code 课程称它"uses semantic searching to determine when to call a tool"，原文只有这一句，没有解释机制，含义不明，不宜引用为事实（[[2026-11-20-how-claude-code-works]]）。

## 采用它的项目

[[claude-code|Claude Code]]（[[2026-11-20-how-claude-code-works]]）、[[openharness|OpenHarness]]（[[2026-11-20-openharness-readme]]）、[[deepseek-harness|DeepSeek Harness]]（[[2026-11-20-deepseek-harness-agent-loop-source]]）、[[microsoft-agent-framework|Microsoft Agent Framework]]（[[2026-11-20-microsoft-learn-agent-harness]]）、[[learn-claude-code]]（[[2026-11-20-learn-claude-code-readme]]）、Go 练习仓库（`bash`、`read_file`、`edit_file`、`write_file`）（[[2026-11-20-harness-engineering-go-practice]]）。

## 相关概念

[[agent-loop]]、[[agent-harness]]、[[permissions]]、[[hooks]]、[[sandboxing]]、[[mcp]]、[[skills]]、[[subagents]]、[[compaction]]、[[context-management]]、[[error-recovery]]、[[verification-and-observability]]、[[system-prompt]]、[[harness-engineering]]
