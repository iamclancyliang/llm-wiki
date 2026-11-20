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

## 浏览

- **网站**：`wiki/` 会由 [Quartz](https://quartz.jzhao.xyz) 构建成静态网站，带双链、反向链接、图谱和全文搜索。`raw/` 不参与构建。
  - 本地预览：`bash site/build.sh --serve`，然后打开 http://localhost:8080 （需要 Node.js 22 以上；首次运行会把 Quartz 克隆到 `.quartz-build/`）
  - 线上：推送到 `main` 后由 GitHub Actions 发布到 GitHub Pages（需先在仓库 Settings → Pages 把 Source 设为 "GitHub Actions"）
  - 配置在 `site/quartz.config.yaml`
- **Obsidian**：把本目录作为仓库（vault）打开即可，附件目录设为 `raw/assets`。
