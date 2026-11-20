---
title: harness-engineering：Go 迷你 agent harness 练习仓库
type: source
kind: repo
aliases: [harness-engineering Go 练习, Go mini harness, Learn-AI-Agent/harness-engineering]
tags: [agent-harness, harness-engineering, go, practice, agent-loop]
created: 2026-11-20
updated: 2026-11-20
sources: []
raw: /Users/ugreen/Project/github/Learn-AI-Agent/harness-engineering   # 本地练习仓库，仍在修改，未复制进 raw/
author: 用户本人（跟随课程编写的脚手架与练习）
---

# harness-engineering：Go 迷你 agent harness 练习仓库

> **快照说明**：本页依据 2026-11-20 读到的工作区，HEAD 为 `dd5ad26`（2026-11-19，"Verify the lessons against real runs and record what was observed"），该目录无未提交改动。仓库仍在随课程修改，下文"已实现 / 待实现"只对这个快照成立。未读取 `.env`。课程讲义在上级目录的 `lessons/`（HTML），不在本次摄入范围内。

## 一段话概括

一个用 Go 写的教学用 [[agent-harness|agent harness]]，约 3400 行（含测试和 README），零第三方依赖（`go.mod` 只有 `module harness` 和 `go 1.25.6`）。它是"测试先行"的练习脚手架：数据类型、模型客户端、命令行入口和**全部测试**已经写好，每一课要实现的机制留成带详细注释的 `TODO` 桩，验收标准是该课的测试由红变绿。因此这个仓库目前的价值不在可运行的实现，而在**接口签名、数据结构和测试断言所固定下来的设计规格**：它把 [[harness-engineering|harness engineering]] 的十几个机制各自压缩成了几条可执行的行为约定。

## 解决什么问题

让学习者自己写出围绕 [[agent-loop|agent loop]] 的每个机制，并且每一步都有确定的验收。假模型 `llm.Fake` 按剧本回复并记录每次收到的完整历史，所以测试能断言"harness 到底给模型看了什么"，不联网、不花钱、结果确定。

## 包结构与职责

| 包 | 职责 | 快照状态 |
|---|---|---|
| `llm/` | `Message` / `ToolCall` / `ToolSpec` 数据类型，`Model` 接口，DeepSeek 客户端（OpenAI 兼容 chat completions，默认模型 `deepseek-flash`），`Fake` 假模型，`APIError` | 已提供；`IsRetryable`、`Retry.Chat` 是桩 |
| `agent/` | 循环 `Run` 及其机制：`Options`、`Hooks`、`Event`、`Reason`、`Rules`、`Queue`、`Compact`、`Subagent`、`StopReason` | 类型、常量、`Queue`、`Size`、`Transcript` 已提供；`Run`、`Truncate`、`Rules.Decide`、`Compact`、`Subagent` 函数体、`StopReason` 是桩 |
| `tools/` | `bash`、`read_file`、`edit_file`、`write_file` | `bash`、`edit_file`、`write_file` 已实现；`ReadLines` 是桩 |
| `session/` | JSONL 会话日志 `Store` | `Append`、`Load` 是桩 |
| `longrun/` | 跨会话长任务：功能清单、两种提示词、驱动器 | `LoadFeatures`、`SaveFeatures`、两个提示词已实现；`NextPrompt`、`CheckEdit`、`Drive` 是桩 |
| `prompt/` | 系统提示词组装 | `LoadSkills` 已实现；`FindContextFiles`、`Build` 是桩 |
| `cmd/harness/` | 单次 run 的命令行入口，每课一个开关 | 已实现（接线完整，背后机制未实现时开关无效） |
| `cmd/longrun/` | 长任务入口 | 已实现 |
| `demo/` | 独立 Go 模块，`stats.Average` 故意从下标 1 开始累加，测试是红的，供 harness 来修 | 已提供 |

**如实说明**：在这个快照上运行 `go test ./...`，6 个有测试的包全部 FAIL。`agent.Run` 直接返回"还没有实现"的错误；`Truncate` 和 `Compact` 原样返回；`Rules.Decide` 一律 `Allow`；`session.Store` 的两个方法是空操作；`Retry.Chat` 只是转发。README 提到的 `runTool` 在代码里还不存在，要学习者自己创建。少数测试在桩状态下碰巧通过（例如"文件不存在返回错误"），不代表机制已实现。README 也警告：完成第 5 课之前 `bash` 没有任何权限检查。

核心接口（出处：`llm/llm.go`、`agent/tool.go`、`agent/loop.go`）：

```go
type Model interface {
    Chat(ctx context.Context, messages []Message, tools []ToolSpec) (Message, error)
}
type Tool struct {
    Spec llm.ToolSpec
    Run  func(ctx context.Context, args json.RawMessage) (string, error)
}
func Run(ctx context.Context, model llm.Model, tools []Tool,
    messages []llm.Message, opts Options) ([]llm.Message, error)
```

两个贯穿全局的设计决策：

- **模型无状态，历史由调用方持有。** `Run` 接收历史、返回"输入加上新产生的全部消息"，自己不保存任何东西。
- **机制通过 `Options` 的零值关闭。** 每课对应 `Options` 里一组字段，留空即不启用，所以后面课程的机制不会影响前面课程的测试。重试则更进一步：`Retry` 自己实现 `Model` 接口，包在模型外面，循环完全不知道它存在。

## 各课机制与测试固定下来的设计

README 的验收表从第 3 课到第 14 课共 12 行（第 1–2 课是概念课，没有代码练习）。

**第 3 课：agent loop。** turn 定义为"一次模型调用加它引发的一批工具执行"。断言：无工具调用时只调一次模型；工具结果必须作为 `tool` 消息回到历史且 `ToolCallID` 对得上，第二次调用时模型看到 `[user, assistant(tool_calls), tool]`；`MaxTurns=3` 时恰好调用 3 次模型后返回 `ErrMaxTurns`。

**第 4 课：[[tools|工具]]与截断。** 错误不是异常，而是给模型的信息：
- 模型请求了不存在的工具（测试里故意拼错成 `read_flie`）：循环不崩溃，回一条 `tool` 消息，内容要包含错误的名字和所有可用工具名。
- 工具返回 `error`：`Run` 不报错，错误文字成为结果。`bash` 把命令失败也当结果返回（注释："命令失败也是 ground truth"），并有 30 秒超时。
- `Truncate(s, max)` 按 rune 截断（中文不能按字节切），并追加 `[输出太长，已截断：共 N 个字符，只保留了前 max 个]`。`MaxToolOutput = 20000`。断言强调必须告诉模型内容不完整，"否则它会以为看到了全部"。
- `ReadLines` 带行号输出，默认一次 200 行，后面还有内容时追加 `[文件共 N 行，这里显示第 A–B 行。要看后面的内容，用 offset 参数]`。
- `edit_file` 要求 `old_text` 在文件里恰好出现一次，零次或多次都返回带指引的错误。

**第 5 课：[[permissions|权限]]规则。** `Policy func(call) Decision`，裁决为 `Allow` / `Deny` / `Ask`。`Rules.Decide` 的顺序：工具名在 `AllowTools` → 放行；`bash` 命令包含 `DenyContains` 任一项 → 拒绝；以 `AllowPrefixes` 任一项开头 → 放行；其余一律 `Ask`。断言：拒绝优先于放行（`ls && sudo rm x` 被拒）；命令前导空格不影响前缀匹配；`Deny` 时不再去问人；`Ask` 时把完整调用交给 `Approve` 看；**`Approve` 为 nil（无人值守）按拒绝处理**，注释："安全相关的默认值要选保守的那一边"；无论批不批准循环都继续，模型拿到固定文字 `MsgDenied` 或 `MsgRejected`。

**第 6 课：[[hooks]]。** 三个插入点，注释说名字与 [[pi]] 保持一致：

```go
type Hooks struct {
    BeforeToolCall   func(ctx context.Context, call llm.ToolCall) *Block
    AfterToolCall    func(ctx context.Context, call llm.ToolCall, output string) string
    TransformContext func(ctx context.Context, messages []llm.Message) []llm.Message
}
```

`BeforeToolCall` 返回非 nil 即拦截，`Block.Reason` 成为工具结果；`AfterToolCall` 可改写结果（测试用它把输出里的密钥抹掉，并断言模型下一次调用看不到原文）；`TransformContext` 只改"这一次发给模型的历史"，不改循环保存的历史。顺序约定：**权限在前，hook 在后**，权限已拒绝的调用不再触发 `BeforeToolCall`。

**第 7 课：[[session-log|会话日志]]。** JSONL，一行一条消息，只追加。`Append` 要把 JSON 和换行拼成一个 `[]byte` 只 `Write` 一次（一行要么完整写下要么没写），文件权限 `0o600`。`Load` 的容错是不对称的：文件不存在是新会话而非错误；**最后一行**不是合法 JSON 就丢弃（进程可能写到一半被杀）；**中间行**损坏则报错并指出行号（"文件坏了，不能假装没事"）；要能读回超过 64KB 的行，所以不能用 `bufio.Scanner`。循环一侧，`OnMessage` 对每条新增消息恰好调用一次，传入的旧历史不再通知（否则恢复会话时会重复写）。

**第 8 课：[[compaction]]。** `Compact(ctx, model, messages, keepRecent)` 的规格：保留开头连续的 system 消息；切点默认是 `len - keepRecent`，若落在 `tool` 消息上就向前挪，**不能把工具请求和结果拆开**（否则出现孤儿 `tool` 消息，接口会拒绝）；把中间那段用 `Transcript` 转成文字，以 `SummaryPrompt` 为 system 调一次模型，不带工具；结果是 `[system…, user(SummaryPrefix+摘要), 最近的消息…]`。摘要提示词要求包含用户目标、已完成的事、读过或改过的文件、未完成的事、踩过的坑。其他断言：没东西可压时不调用模型（"调一次就花一次钱"）；不修改传入的切片；写摘要失败要返回错误，"不能悄悄丢掉历史"。触发条件在 `Run` 里：`Size(messages) > MaxContextChars` 时在调用模型前压缩。`Size` 按字符数粗估，不是 token 数。这是本仓库里 [[context-management|上下文管理]]的唯一手段。

**第 9 课：[[long-running-agents|长任务]]。** 注释注明做法来自 [[anthropic|Anthropic]] 的《Effective harnesses for long-running agents》。状态只在磁盘上：`feature_list.json`（`Feature{Description, Steps, Passes}` 数组）和 `progress.md`。`NextPrompt`：清单不存在 → `InitializerPrompt`（只搭环境：写清单、`init.sh`、进度文件，不实现功能，所有 `passes` 为 false）；全部通过 → `done`；否则 `CodingPrompt`（读进度和清单、跑 `init.sh`、只做一个功能、验证后才改 `passes`、追加进度）。`CheckEdit(before, after)` 只允许把 `Passes` 从 false 改成 true，项数变化、描述被改写、true 改回 false 都报错。`Drive` 每轮开一个全新上下文的会话，会话后校验清单，不合规就用会话前的清单覆盖回去；开满 `maxSessions` 返回 `ErrMaxSessions`。测试里有一个"作弊会话"把未完成项直接删掉，断言清单被恢复、任务不算完成。设计理由写在注释里："提示词是请求，模型可能不照做；代码是规则，模型绕不过去。"完成与否由清单判定，不由模型的一句话判定。`cmd/longrun` 里单个会话用完 turn 数不算失败，进度在磁盘上，下一个会话接着做。

**第 10 课：[[system-prompt|系统提示词]]组装。** `Build(base, contextFiles, skills)` 顺序为基础指令 → 每个 `AGENTS.md` 一段（标题 `# 项目规则（来自 <路径>）`）→ skill 清单。`FindContextFiles(dir, root)` 从当前目录向上找到 `root` 为止，不越过 `root`（上面的属于别的项目），返回顺序从外到内，这样离当前目录越近的 [[context-files|context file]] 越靠后、越"说了算"。[[skills|skill]] 只放名字、描述和路径，完整内容由模型需要时用 `read_file` 去读；测试断言正文不出现在提示词里，且两个 skill 的清单不超过 600 个字符。规则文件读不出来要报错，不能悄悄漏掉。

**第 11 课：[[steering-and-cancel|插话与取消]]。** 两个队列语义不同：`Steering` 在每个 turn 结束后取一次；`FollowUp` 只在 agent 本来要停下时取。断言：插话排在工具结果之后，不能插进请求和结果之间；模型想停但有插话时必须再跑一个 turn；两者都在排队时历史顺序是 `一, 插话, 二, 后续, 三`，即 follow-up 要等 steering 引出的工作也做完。取消：`ctx` 已取消时一次模型都不调；工具执行期间被取消，当前结果留在历史里，不再调模型，返回 `context.Canceled`；**一批工具执行到一半被取消，没执行的每个请求也要补一条 `MsgCanceled` 结果**，否则带着这份历史再调模型会报错，会话就接不上了。`Queue` 用互斥锁保证界面 goroutine 的 `Push` 与循环的 `Drain` 并发安全。

**第 12 课：重试与截断处理（[[error-recovery|错误恢复]]）。** `IsRetryable`：429 和 5xx 重试；其他 4xx（401、400）不重试；`context.Canceled` / `DeadlineExceeded` 不重试；其他错误（多半是网络问题）重试；要用 `errors.As` 穿透包装。`Retry{Model, Attempts, Backoff}`：`Attempts` 含第一次；试满后返回**最后一次**的错误；等待期间 `ctx` 取消要立刻返回；`Backoff` 收到的是第几次失败（1、2…）。`ExponentialBackoff(base)` 为 `base << (attempt-1)`。截断：assistant 消息的 `FinishReason == "length"` 且带工具调用时，参数可能只写了一半，**一个都不执行**，每个请求回一条 `MsgTruncated`（提示模型把内容拆小重来），循环继续。

**第 13 课：[[subagents|subagent]]。** `Subagent(model, tools, system, opts) Tool` 把"再开一个循环"包装成名为 `task` 的工具。子 agent 的历史只有 `[system, user(prompt)]`，跑完只返回最后一条消息的文字。断言：子 agent 产生三万字输出后，主历史只有 4 条且 `Size ≤ 200`，主模型看不到中间过程；空 prompt 报错；子 agent 受自己的 `Options` 约束，它撞上 `MaxTurns` 时主 agent 收到一条含"出错"的结果而不是跟着失败；取消通过 `ctx` 传到子 agent。`cmd/harness` 里子 agent 拿到的工具集不含 `task`（不能递归），并继承父级的权限策略。

**第 14 课：停止原因、完成门槛、事件（[[verification-and-observability|验证与可观测性]]）。**
- `StopReason(err)`：nil → `completed`；`ErrMaxTurns` → `max-turns`；取消或超时 → `aborted`；其他 → `error`。
- 完成门槛 `Verify func(ctx) (ok bool, output string)`：只在模型不再请求工具时调用；失败则把 `VerifyFailedPrefix + output` 作为一条 user 消息交还，循环继续；验证永远不过时仍由 `MaxTurns` 兜底。命令行里 `-verify` 就是跑一条 shell 命令看退出码。
- 事件流 `OnEvent`，名字与 pi 一致。一个带一次工具调用的 run 的序列被测试固定为：`agent_start`，`turn_start`、`message_end`、`tool_execution_start`、`tool_execution_end`、`message_end`、`turn_end`，`turn_start`、`message_end`、`turn_end`，`agent_end`。无论怎么结束，最后一个事件都是带 `Reason` 的 `agent_end`。

## 适用与不适用的场景

- 适用：作为各机制"最小正确行为"的可执行规格；对照其他 harness 的实现时，这些断言是一份现成的检查清单。
- 不适用：不是可用的 agent。没有流式输出、没有 token 计数、没有 sandbox、没有并行工具执行、没有 MCP、没有 memory。

## 成熟度

个人练习仓库，最近 3 次提交（重写第 1–3 课、补第 4–16 课的脚手架与测试、对照真实运行验证）都在 2026-11-19，无版本号，本目录内没有许可证文件。脚手架作者自述已"对照真实运行验证过课程"（提交说明），但练习本身尚未完成。提交说明提到"lessons 4-16"，而 README 的验收表只到第 14 课，第 15–16 课的内容从本目录看不出来。

## 与已有知识的关系

- 印证：长任务部分是 Anthropic initializer / coding agent 做法的直接实现；`feature_list.json` 加进度文件与 learn-harness-engineering 课程首页的闭环图一致（见 `2026-11-20-learn-harness-engineering-course`）。
- 印证：subagent "全新历史、只回最终文本"与 learn-claude-code s06 的表述相同；skill "只列目录、按需读取"与其 s07 相同。
- 补充：给出了其他资料只有标题的两项的具体规格，即错误分类与重试，以及"停止原因 + 完成门槛 + 事件"三件套。
- 分歧：这里停不停不完全由模型决定。`Verify`、`FollowUp`、`Steering` 都能在模型想停时让循环继续，`MaxTurns` 和取消能在模型不想停时让它停下。

## 涉及的实体和概念

实体：[[pi]]（hook 与事件命名的参照）、[[anthropic]]（长任务做法的出处）。模型后端是 DeepSeek 的 API，与 deepseek-harness 项目无关。
概念：[[agent-harness]]、[[agent-loop]]、[[tools]]、[[permissions]]、[[hooks]]、[[session-log]]、[[context-management]]、[[compaction]]、[[long-running-agents]]、[[system-prompt]]、[[context-files]]、[[skills]]、[[steering-and-cancel]]、[[error-recovery]]、[[subagents]]、[[verification-and-observability]]。

## 局限与遗留问题

以下除注明外都是我读代码后的推断：

- **权限规则靠字符串匹配，容易绕过。** 前缀放行意味着 `ls; curl … | sh` 会因为以 `ls` 开头而放行（除非命中 `DenyContains`）；`cmd/harness` 的白名单含 `cat `，所以 `cat .env` 不需要批准。真正的隔离需要 sandbox，这里没有。
- **`CheckEdit` 的规格不校验 `Steps`**，模型可以改写验证步骤让功能更容易"通过"；第一个会话（清单尚不存在）写出的清单不经过校验，initializer 可以直接写 `passes: true`。
- **压缩后 `Run` 返回哪份历史没有被测试固定**：测试只断言模型看到的是压缩后的历史、输入切片不被修改。压缩后的历史与只追加的会话日志如何对应（恢复会话时加载原文还是摘要）是未决的设计点。
- **`Verify`、`Steering`、`FollowUp` 三者在"模型想停"这一刻的先后顺序**只测了 steering 先于 follow-up，验证与两者的顺序未规定。
- **`FinishReason == "length"` 但没有工具调用**（纯文本被截断）时怎么办，没有测试。
- 工具串行执行；`Size` 以字符数近似 token 数，对中文和代码的偏差方向不同。
- 仓库在变动中：本页的状态描述需要在练习完成后重写，届时应补上"学习者实际实现与规格的差异"。
