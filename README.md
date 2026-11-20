# hello-lean-proof

Lean 4 で **証明を「探索ゲーム」として** 学ぶ日本語ハンズオン。
`hello-*` シリーズの一角。

前提知識は「プログラミングができる」ことだけ。論理記号は忘れていてよい。

## 動機

証明を書くとき、多くの人は「思いつき」を待ってしまう。
しかし Lean の証明は **盤面を見て手を選ぶ** 作業であり、チェスの手と同じ構造を持つ。

| ゲームの概念 | Lean の対応物 |
|---|---|
| 盤面 | `⊢` の右（ゴール）＋ 左（仮定） |
| 手 | tactic（`intro` / `apply` / `exact` / `constructor`） |
| 勝利条件 | `No goals` |
| 違反手 | 型エラー（盤面は変わらない） |
| 自動探索 | `simp` / `omega` / `aesop` |

この対応を体に入れると、Lean の文法を暗記しなくても証明が読めるようになる。
そしてこの構造は、AI がコードを量産する時代の **検証層** の議論にそのまま繋がる（末尾の「背景」を参照）。

## 前提

- macOS / Linux / WSL / Windows（PowerShell）
- Lean 4.36.0（`lean-toolchain` で固定済み）
- 初回は 1〜2 GB のダウンロードが発生する

**Windows**: [docs/windows.md](docs/windows.md) を見る（`elan-init.ps1` を使う手順。実機検証は未了）

**Python 経験者**: 先に [docs/python-comparison.md](docs/python-comparison.md) を読むと入りやすい（10 分）。「`sorry` は `pass`」の 1 行だけで見通しが変わる。

## クイックスタート

### 1. elan（Lean のバージョン管理）を入れる

```bash
curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o /tmp/elan-init.sh
sh /tmp/elan-init.sh -y --default-toolchain none
```

`~/.zshrc` か `~/.bashrc` に追記:

```bash
export PATH="$HOME/.elan/bin:$PATH"
```

### 2. このリポジトリを取得してビルド

```bash
git clone https://github.com/nishimotz/hello-lean-proof.git
cd hello-lean-proof
lake build
```

`Build completed successfully` が出れば環境は完成。
（本リポジトリは Lean 4.36.0 で `lake build` 11 ジョブ成功を確認済み）

### 3. エディタ

VS Code + 拡張 **Lean 4**（`leanprover.lean4`）。
ファイルを開くと右側に Infoview が出る。**これがゲーム画面**。

```
P Q : Prop          ← 仮定（持ち駒）
hp : P
hq : Q
⊢ P ∧ Q             ← ゴール（勝つべき盤面）
```

## 構成

| Exercise | 内容 | 形式 |
|---|---|---|
| `Exercises/01_first_tactic` | `constructor` で盤面が割れるのを見る | 実行 |
| `Exercises/02_backward_search` | `apply` でゴールが遡る（逆向き探索） | 実行 |
| `Exercises/03_case_split` | `rcases` で場合分け。`obtain` / `⟨…⟩` も | 実行 |
| `Exercises/04_automation` | `simp` / `omega`。失敗する手も見る | 実行 |
| `Exercises/05_synthesis` | 総合演習（ド・モルガン、分配法則、対偶） | 実行 |

各ディレクトリに `Exercise.lean`（穴埋め）と `Solution.lean`（解答）がある。

### 演習の進め方

```bash
# 穴埋めを解く（sorry があるので警告は出る）
lake env lean Exercises/01_first_tactic/Exercise.lean

# 自分の解答が正しいか確かめる
lake env lean Exercises/01_first_tactic/Solution.lean
```

VS Code なら `Exercise.lean` を開き、`sorry` を消して 1 行ずつ埋める。
`No goals` が出たら勝利。

## 90 分の使い方

### 事前準備必須

当日の初回インストールは現実的でない。**参加者は自宅で `lake build` 成功まで済ませてくる**。

間に合わない参加者向けに**読み専用コース**がある: `Solution.lean` を読みながら議論だけ参加する。それでも十分学べる。

### 進行表

| 時間 | 内容 | ねらい |
|---|---|---|
| 0–5 | 対応表の共有 | 背骨を揃える |
| 5–10 | 環境確認（`lake build`） | 詰まりを早期発見 |
| 10–30 | Exercise 01–02 | 盤面が変わる体験、逆向き探索 |
| 30–45 | Exercise 03 | 分岐と記法 |
| 45–60 | Exercise 04 | 自動化のブラックボックス化を議論 |
| 60–80 | Exercise 05 | 総合演習 |
| 80–90 | まとめ＋背景の話 | 検証層へ接続 |

### つまずきポイント（実際に詰まる順）

1. **`exact` と `apply` の区別** — `exact` はゴールを丸ごと埋める。`apply` はゴールを別のゴールに変換する
2. **`intro` 忘れ** — ゴールが `P → Q` のとき、まず `intro hp` で仮定を盤面に置く
3. **`∧` と `→` の混同** — 形が違えば使える手も違う
4. **`sorry` で通ってしまう** — `sorry` は警告 1 行だけでコンパイルが通る。証明ではない。次の手順で検出する:

   ```lean
   theorem my_thm (P : Prop) : P := by sorry
   #print axioms my_thm
   -- 'my_thm' depends on axioms: [sorryAx]
   ```

   `example` は名前が無いので `#print axioms` で覗けない。**名前付きで書く**こと。

5. **Infoview が出ない** — VS Code が `lakefile.toml` のあるディレクトリを開いているか確認

## 記法の最小辞典

演習で出てくる記法だけを並べる。

| 記法 | 読み | 何をするか |
|---|---|---|
| `constructor` | ゴールを分解 | `P ∧ Q` を 2 つのゴールに割る |
| `exact h` | h をそのまま置く | ゴールと型が完全一致するとき |
| `apply h` | h を当てる | ゴールを h の前提に変換する |
| `intro hp` | 仮定を導入 | ゴールが `P → Q` のとき `hp : P` を置く |
| `obtain ⟨a, b⟩ := h` | h から取り出す | `h : P ∧ Q` を 2 つの仮定に分解 |
| `rcases h with x \| y` | h で場合分け | `h : P ∨ Q` を 2 ケースに分ける |
| `⟨a, b⟩` | ペアを作る | `⟨hp, hq⟩` で `P ∧ Q` を 1 手で埋める |
| `simp [h]` | 書き換える | 規則と仮定を当てまくる。自動探索 |
| `omega` | 線形算術 | 整数・自然数の等式/不等式 |

**全ての問題は `constructor` と `exact` だけで解ける**（Lean 4.36.0 で実測）。ただし `exact` に直接証明項を書く場面があり、読みにくくなる。`intro` / `apply` / `obtain` / `rcases` はその段階を分けて書くための**別の手**であって、`exact` の短縮形ではない。

> `exact h` は「ゴールと型が同じ」だけでなく、Lean が同じ型とみなす範囲（定義上等しい場合）でも通る。

## 検証状況

| 項目 | 状態 |
|---|---|
| 全 `Solution.lean`（5 ファイル）のコンパイル | Lean 4.36.0 で通過、rc=0、警告 0 |
| 全 `Exercise.lean` のコンパイル | `sorry` 警告のみ（想定どおり）、エラー 0 |
| `lake build` | `Build completed successfully (22 jobs)`（✔5 / ⚠5=Exercise の sorry / エラー 0） |
| 04 章の「失敗する手」が実際に落ちること | 実測で確認（`omega could not prove the goal` / `simp made no progress`。**4.36.0 時点の文言**） |
| 05 章の自動化表（どの問題が `simp`/`omega` で解けるか） | 独立検証で再確認（5-1 `simp` ✓、5-2 `simp [h]` ✓、5-3 `simp [h]` ✗） |
| `sorryAx` 検出手順 | 実出力で再現 |
| VS Code Infoview の画面文言 | 公式仕様ベース。実機目視は未実施 |

## 背景: なぜ今これを学ぶのか

2026 年 11 月、AI コーディングエージェントの量産と品質をどう両立するかが話題になった。
Lauren Tan（`poteto`）の講演は、その答えを **「検証の証拠物を人間がレビューする形に仕事を変える」** に置いた。
Lean と TLA+ は、その証拠物を作る道具の一つとして実際に使われている。

この教材の探索ゲームは、その道具の入口にすぎない。
だが **「盤面を見て手を選ぶ」** という感覚は、コードベースを見て制約を選ぶ感覚と同じ形をしている。

### 出典

- 講演: **All Code Is Slop (Except Mine) — Lauren Tan, SpaceXSI**
  - 会場: AI Engineer Code Summit 2026（San Francisco, Hilton Union Square, 2026-11-10〜12）
  - 講演日: 2026-11-11 メインステージ、18 分
  - 話者: Lauren Tan（SpaceXSI Principal Engineer、Grok Bot チーム）
  - 動画: https://www.youtube.com/watch?v=O_zcc6Xl12g
  - 会議ページ: https://ai.engineer/code/2026
  - 話者の一次情報: https://x.com/poteto / https://github.com/poteto
- 証明を探索ゲームとして扱う解説: くわラジ #29「証明は"探索ゲーム"だ——Lean・Isabelleで学ぶ形式手法の証明の仕組み」 https://www.youtube.com/watch?v=m19Oz8S3kro
- Lean 4 公式: https://lean-lang.org/
- Functional Programming in Lean: https://lean-lang.org/functional_programming_in_lean/
- Theorem Proving in Lean 4: https://lean-lang.org/theorem_proving_in_lean4/

## ライセンス

本リポジトリのコードは **MIT ライセンス**（[LICENSE](LICENSE) を参照）。
講演内容を引用する場合は出典を明記すること。
