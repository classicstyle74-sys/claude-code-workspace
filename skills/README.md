# ユーザーレベルスキル

`~/.claude/skills/` に配置して、プロジェクトを問わず Claude Code のどこからでも使うスキルの保管場所。

インストールはリポジトリルートの `install-skills.sh` で行う。

```bash
./install-skills.sh
```

## 収録スキル

### grill-me / grilling

アイデア・計画・意思決定を、質問攻めで詰めて磨き上げるための対話スキル。2つで1組。

| スキル | 呼び出し方 | 役割 |
| --- | --- | --- |
| `grill-me` | `/grill-me` と入力（ユーザーのみ） | 入口。`disable-model-invocation: true` が付いており、Claude が勝手に発動することはない |
| `grilling` | Claude が自動で判断、または `/grilling` | 本体の面接ロジック。`grill-me` から呼ばれる |

`grill-me` の SKILL.md は「`/grilling` セッションを実行する」の一文だけなので、**`grilling` が無いと動かない**。必ず両方を入れること。

#### 動作の要点

- 対象を **design tree**（決定が決定を枝分かれさせる木）としてモデル化する
- **frontier**（前提が既に確定していて、いま正直に聞ける質問の集合）を1ラウンドで一括提示する
- 質問は `❓ **Q1** - **タイトル**: 本文` ＋ `➡️ 推奨する答え` の形式で番号付き。「1 はい、2 後者、3 いいえ」と番号で返せる
- 事実の調査は Claude の仕事（サブエージェントで調べる）、**決定はユーザーの仕事**
- frontier が空になったら終了。ユーザーが合意を確認するまで実行に移らない
- ステートレス。ファイルを一切書かない

#### 使い方のコツ（上流ドキュメントより）

- **新しい会話で始める**。既に書かせた計画の上に乗せない
- **plan mode はオフ**にする。計画を急がせる方向に働き、探究と逆になる
- 質問の数ではなく**ラウンド数**を数える。4ラウンドで46問は普通
- 200問に膨らんだらスコープが大きすぎる。分割してから個別に grill する
- 「見た目・感触をどうするか」は話しても決まらない（ungrillable）。試作して戻る
- 頷き続けるのが最大の失敗。**反論が一度も出ないセッションは不要だったセッション**
- 1問ずつにしたい場合は グローバル `CLAUDE.md` に `When grilling, ask one question at a time.` を追記

## 出典とライセンス

- 取得元: https://github.com/mattpocock/skills (`skills/productivity/grill-me`, `skills/productivity/grilling`)
- コミット: `8b78b531ab965735c5dc74f6f7a219e1e37326df` (2026-08-13)
- ライセンス: MIT / Copyright (c) 2026 Matt Pocock — 全文は `LICENSE.upstream` を参照
- SKILL.md は上流のまま無改変。更新したい場合は上流を再取得して差し替える

上流リポジトリには他に `grill-with-docs`（コードベースを読み `CONTEXT.md` と ADR を書く版）や `wayfinder`（大きすぎる案件を地図化する版）もある。必要になったら同じ手順で追加できる。

なお、上流には各スキルに `agents/openai.yaml` が同梱されているが、これは OpenAI 系エージェント向けのメタデータで Claude Code では未使用のため取り込んでいない。
