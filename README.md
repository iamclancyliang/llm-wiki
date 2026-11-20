# LLM Wiki

由 LLM 维护的个人知识库：我负责挑资料和提问，LLM 负责总结、交叉引用、归档和维护。

- `raw/` — 原始资料（只读）
- `wiki/` — LLM 撰写的 wiki，从 [wiki/index.md](wiki/index.md) 开始读
- `CLAUDE.md` — 维护规约，定义结构、页面格式和工作流

## 用法

在本目录打开 Claude Code，然后：

- **摄入**：把资料放进 `raw/`，说"处理 raw/xxx.md"
- **查询**：直接提问；有价值的回答可以让它存入 `wiki/analyses/`
- **体检**：说"给 wiki 做一次体检"

用 Obsidian 把本目录作为仓库（vault）打开即可浏览，附件目录设为 `raw/assets`。
