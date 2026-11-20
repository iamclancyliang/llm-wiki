# 索引

知识库全部页面的目录。每次摄入或新增页面后由 LLM 更新。当前主题：agent harness 与 harness engineering。

## 综述

- [[overview]] — 当前的综合理解：harness 的两层含义、运行时机制清单、主要分歧、证据成色与资料缺口

## 概念

**基础**

- [[agent-harness]] — harness 是什么；运行时层与仓库/环境层两种含义；各资料对其组成的切分
- [[harness-engineering]] — 为 agent 设计环境、约束和反馈回路的工程实践
- [[agent-loop]] — 循环的控制流、turn 与 step、停止条件、loop 的职责边界
- [[workflows-vs-agents]] — 预定义流程与模型自主的区分、五种 workflow 模式、何时用哪种

**工具与控制**

- [[tools]] — 工具定义、执行管线、输出截断、agent-computer interface 原则
- [[permissions]] — 权限规则与模式、检查在管线中的位置、弱点，以及"不做权限系统"的立场
- [[sandboxing]] — 执行环境隔离：容器、micro-VM、worktree、文件访问范围
- [[hooks]] — 生命周期钩子：事件粒度、配置、退出码协议、确定性
- [[planning-and-plan-mode]] — 显式计划、todo 工具、plan mode、计划作为一等工件

**上下文与记忆**

- [[context-management]] — context window 作为有限工作记忆及其管理手段总览
- [[compaction]] — 上下文压缩的触发、不变量、代价和局限
- [[session-log]] — 只追加的会话日志、从日志派生请求、恢复与续跑
- [[memory]] — 跨会话的持久记忆及其与日志、压缩、上下文文件的区别
- [[system-prompt]] — 系统提示词的组装、指令的层次与顺序
- [[context-files]] — CLAUDE.md / AGENTS.md：层级、加载、写法和可靠性局限
- [[skills]] — 按需加载的知识与工作流、渐进式披露

**运行与可靠性**

- [[long-running-agents]] — 跨多个会话完成任务：初始化 agent、feature list、进度文件、git 检查点
- [[error-recovery]] — 重试、输出截断、悬空 tool call 的补全
- [[steering-and-cancel]] — 运行中插话与取消：队列、边界式注入、取消的不变量
- [[verification-and-observability]] — 完成门槛、验证手段、停止原因、事件与遥测、事后评估

**分工与扩展**

- [[subagents]] — 独立上下文的子 agent、用途、与多 agent 团队的区别
- [[mcp]] — Model Context Protocol 在各 harness 中的角色与上下文代价
- [[plugins-and-extensibility]] — 三种扩展模型：固定子系统、小核心加外置包、一切皆插件

## 实体

**项目**

- [[claude-code]] — Anthropic 的 coding agent；本库中资料最多的 harness 实例
- [[claude-agent-sdk]] — Anthropic 的 agent SDK，长时运行实验所用的 harness
- [[codex]] — OpenAI 的 coding agent，harness engineering 文章的主角
- [[openharness]] — HKUDS 的 Python harness，格式上贴近 Claude Code，附带个人 agent ohmo
- [[deepseek-harness]] — 基于 Cordis、"一切皆插件"的 TypeScript harness
- [[pi]] — 自称最小化、可扩展的 harness，不内置权限、subagent 和 plan mode
- [[microsoft-agent-framework]] — Microsoft 的 agent 框架及其组合式 harness
- [[learn-claude-code]] — 从零实现类 Claude Code harness 的教学仓库和网站
- [[learn-harness-engineering]] — walkinglabs 的 harness engineering 课程

**组织**

- [[anthropic]] — 在本主题下的文章、产品和课程
- [[openai]] — harness engineering 一文的来源

## 分析

- [[开源-harness-设计取向对比]] — OpenHarness、DeepSeek Harness、Pi、Microsoft harness 与 Claude Code 的设计取向对比表

## 来源

均为 2026-11-20 摄入。

**厂商文章与文档**

- [[2026-11-20-anthropic-building-effective-agents]] — Anthropic：workflow 与 agent 的区分、五种模式、工具接口设计
- [[2026-11-20-anthropic-effective-harnesses-for-long-running-agents]] — Anthropic：用初始化 agent、feature list 和进度文件支撑跨会话长任务
- [[2026-11-20-openai-harness-engineering]] — OpenAI：零手写代码团队如何为 Codex 搭建仓库级环境
- [[2026-11-20-microsoft-learn-agent-harness]] — Microsoft Learn：Agent Framework 的 harness 概念与能力矩阵

**开源 harness**

- [[2026-11-20-openharness-readme]] — OpenHarness 仓库页面
- [[2026-11-20-deepseek-harness-readme]] — DeepSeek Harness 仓库页面
- [[2026-11-20-deepseek-harness-agent-loop-source]] — DeepSeek Harness 的 agent loop 源码解读
- [[2026-11-20-pi-readme]] — Pi 仓库页面

**教程与课程**

- [[2026-11-20-learn-claude-code-readme]] — learn-claude-code 仓库：17 课轨道与"Model + Harness"宣言
- [[2026-11-20-learn-claude-code-site]] — learn-claude-code 网站首页：20 课目录与五层切分
- [[2026-11-20-learn-harness-engineering-course]] — Learn Harness Engineering 课程欢迎页与 14 讲大纲
- [[2026-11-20-ai-harness-crash-course]] — 入门视频：上下文与记忆、工具、运行时安全、评估四分法
- [[2026-11-20-harness-engineering-go-practice]] — 本地 Go 练习仓库：12 课测试固定下来的 harness 规格

**Claude Code 官方课程**

- [[2026-11-20-claude-code-101-course]] — Claude Code 101 课程大纲
- [[2026-11-20-what-is-claude-code]] — Claude Code 是什么、使用前要知道的三件事
- [[2026-11-20-how-claude-code-works]] — agentic loop 与三种权限模式
- [[2026-11-20-context-management-in-claude-code]] — `/compact`、`/clear`、`/context` 与省上下文的做法
- [[2026-11-20-hooks-in-claude-code]] — hooks 的事件、配置和退出码
- [[2026-11-20-the-claude-md-file]] — CLAUDE.md 的层级与写法建议
- [[2026-11-20-explore-plan-code-commit-workflow]] — 探索、计划、编码、提交的工作流
