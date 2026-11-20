# 日志

只追加的操作记录。查看最近 5 条：`grep "^## \[" wiki/log.md | tail -5`

## [2026-11-20] schema | 初始化知识库
- 新建：`CLAUDE.md` 规约、目录结构、[[index]]、[[overview]]
- 备注：领域尚未确定，页面类型采用通用设置（来源 / 实体 / 概念 / 分析）

## [2026-11-20] schema | 按技术研究定制规约
- 更新：`CLAUDE.md` —— 实体和来源增加 `kind` 分类；新增技术内容约定（时效性、带条件的数字、主张与结论的区分、代码与术语）；细化论文、仓库、实体、概念、分析页的内容模板

## [2026-11-20] ingest | Agent Harness 资料批量摄入（20 份）
- 资料：NotebookLM 笔记本 "Agent Harness" 的 19 份全文（存于 `raw/agent-harness/`，清单见该目录 README）；本地 Go 练习仓库 `Learn-AI-Agent/harness-engineering`（只引用，未复制）
- 方式：批量摄入，未逐份与用户确认；来源页、概念页、实体页由并行子任务撰写，综述、索引由主会话撰写
- 新建来源页 20 个：见 [[index]] 的"来源"一节
- 新建概念页 23 个：[[agent-harness]]、[[harness-engineering]]、[[agent-loop]]、[[workflows-vs-agents]]、[[tools]]、[[permissions]]、[[sandboxing]]、[[hooks]]、[[planning-and-plan-mode]]、[[context-management]]、[[compaction]]、[[session-log]]、[[memory]]、[[system-prompt]]、[[context-files]]、[[skills]]、[[long-running-agents]]、[[error-recovery]]、[[steering-and-cancel]]、[[verification-and-observability]]、[[subagents]]、[[mcp]]、[[plugins-and-extensibility]]
- 新建实体页 11 个：[[claude-code]]、[[claude-agent-sdk]]、[[codex]]、[[openharness]]、[[deepseek-harness]]、[[pi]]、[[microsoft-agent-framework]]、[[learn-claude-code]]、[[learn-harness-engineering]]、[[anthropic]]、[[openai]]
- 新建分析页：[[开源-harness-设计取向对比]]
- 更新：[[overview]]（首次写入综述）、[[index]]
- 备注：
  - 笔记本中 YouTube 视频 `jKErNxuxPXg` 处于报错状态，未取得内容
  - 最初导出为纯文本；同日给 notebooklm 工具环境加装 `markdown` 组件后，用 markdown 格式重新导出并覆盖了 `raw/agent-harness/` 下的 19 个文件（保留标题层级、表格和链接）。来源页基于纯文本版撰写，正文内容相同
  - "harness" 一词在资料中有运行时层与仓库/环境层两种含义；learn-claude-code 的课程数在网站（20）与 README（17，另有 12 课旧轨道）之间不一致；其余矛盾见各概念页
  - 资料缺口：Learn Harness Engineering 的 14 讲正文、Claude Code 101 的 6 课正文、DeepSeek Harness 的架构文档与 Cordis 论文

## [2026-11-20] schema | 增加 Quartz 网站发布
- 新建：`site/quartz.config.yaml`、`site/build.sh`、`.github/workflows/deploy-site.yml`（只构建 `wiki/`，`raw/` 不发布）
- 更新：`CLAUDE.md` 增加发布约束（别名不带 `/`、空字段省略）；8 个页面的别名去掉 `/`；3 个来源页删除空的 `published` 字段；`README.md` 增加浏览方式
- 备注：Quartz v5.1.0；主题插件 `@quartz-themes/core` 因安装失败而停用，使用内置样式
