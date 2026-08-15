#!/usr/bin/env bash
# ユーザーレベル (~/.claude/skills/) に skills/ 配下のスキルをインストールする。
# ここに入れたスキルは、プロジェクトを問わず Claude Code のどこからでも使える。
#
#   ./install-skills.sh          # インストール
#   ./install-skills.sh --list   # インストール済みの確認のみ
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/skills"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

if [[ "${1:-}" == "--list" ]]; then
  echo "インストール先: $DEST_DIR"
  ls -1 "$DEST_DIR" 2>/dev/null || echo "(ディレクトリなし)"
  exit 0
fi

mkdir -p "$DEST_DIR"

for skill_path in "$SRC_DIR"/*/; do
  skill_name="$(basename "$skill_path")"

  # synced/ は claude.ai 側が管理する領域なので絶対に触らない
  if [[ "$skill_name" == "synced" ]]; then
    continue
  fi

  if [[ ! -f "$skill_path/SKILL.md" ]]; then
    echo "スキップ: $skill_name (SKILL.md が無い)"
    continue
  fi

  mkdir -p "$DEST_DIR/$skill_name"
  cp -R "$skill_path." "$DEST_DIR/$skill_name/"
  echo "インストール: $skill_name -> $DEST_DIR/$skill_name"
done

echo
echo "完了。Claude Code を再起動すると /grill-me が使えるようになります。"
