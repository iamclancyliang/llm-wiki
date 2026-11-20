#!/usr/bin/env bash
# 用 Quartz 把 wiki/ 构建成静态网站，输出到 public/。raw/ 不参与构建。
#
#   bash site/build.sh            构建一次
#   bash site/build.sh --serve    构建并在 http://localhost:8080 预览，改动后自动刷新
#
# Quartz 本体不放进本仓库：首次运行时克隆到 .quartz-build/（已被 git 忽略）。
# 需要 Node.js 22 以上。
set -euo pipefail

QUARTZ_VERSION="v5.1.0"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUARTZ_DIR="$ROOT/.quartz-build"

if [ ! -f "$QUARTZ_DIR/.version" ] || [ "$(cat "$QUARTZ_DIR/.version")" != "$QUARTZ_VERSION" ]; then
  rm -rf "$QUARTZ_DIR"
  git clone --quiet --depth 1 --branch "$QUARTZ_VERSION" https://github.com/jackyzha0/quartz.git "$QUARTZ_DIR"
  (cd "$QUARTZ_DIR" && npm ci --no-audit --no-fund)
  echo "$QUARTZ_VERSION" > "$QUARTZ_DIR/.version"
fi

cp "$ROOT/site/quartz.config.yaml" "$QUARTZ_DIR/quartz.config.yaml"
cd "$QUARTZ_DIR"
npx quartz plugin install --from-config
npx quartz build -d "$ROOT/wiki" -o "$ROOT/public" "$@"
