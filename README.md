# hello-lean-proof

Lean 4 で **証明を「探索ゲーム」として** 学ぶ日本語ハンズオン。
`hello-*` シリーズの一角。

前提知識は「プログラミングができる」ことだけ。論理記号は忘れていてよい。

## 動機

証明を書くとき、多くの人は「白い紙の前で閃きを待つ」イメージを持ってしまう。
しかし Lean の証明は、**1 手打つたびに画面（Infoview）に新しい盤面が出る探索ゲーム**であり、チェスの手と同じ構造を持つ。

| ゲームの概念 | Lean の対応物 |
|---|---|
| 盤面 | `⊢` の右（ゴール）＋ 左（仮定） |
| 手 | tactic（`intro` / `apply` / `exact` / `constructor`） |
| 勝利条件 | `No goals`（審判が 100% 正しさを保証） |
| 違反手 | 型エラー（失敗しても壊れず盤面は変わらない） |
| 自動探索 | `simp` / `omega` / `aesop` |

* **暗算がいらない**: 30 手先まで頭の中で考えるのではなく、目の前の盤面を見て次の 1 手を選ぶだけ
* **誤魔化しが効かない快感**: 型検査器が判定を下すので、`No goals` が出た瞬間のクリアは本物
  - ただし `sorry` を置いた場合も `No goals` は出る。本物かどうかは `#print axioms` で `sorryAx` が出ないことを確認する（README の「つまずきポイント」参照）
* **手動から戦略へ**: 最初は手で 1 手ずつ崩し、慣れたら `simp` / `omega` のような自動探索をどう使うかの戦略に移る

この対応を体に入れると、Lean の文法を暗記しなくても証明が読めるようになる。
そしてこの構造は、AI がコードを量産する時代の **検証層** の議論にそのまま繋がる（末尾の「背景」を参照）。

## 前提

- macOS / Linux / WSL / Windows（PowerShell）
- Lean 4.36.0（`lean-toolchain` で固定済み）
- 初回は 1〜2 GB のダウンロードが発生する

**Windows**: [docs/windows.md](docs/windows.md) を見る（`elan-init.ps1` を使う手順。Windows x64 / PowerShell 7 で動作報告あり。2026-11 時点）

**Python 経験者**: 先に [docs/python-comparison.md](docs/python-comparison.md) を読むと入りやすい（10 分）。「`sorry` は `pass`」の 1 行だけで見通しが変わる。

**読み物（題材例）**: [docs/fizzbuzz.md](docs/fizzbuzz.md) では、FizzBuzz を例に「テスト」と「証明ゲーム」の違いを解説している。

**第 2 部（業務のバグ）**: [docs/formal-rules.md](docs/formal-rules.md) では、チケット販売の売り越しを題材に「テストケースではなくルール（不変条件）を書く」を扱う。AI がコードもテストも書くと自作自演の満点になる問題から始め、同じ題材の Quint / TLA+ 版（[hello-quint](https://github.com/nishimotz/hello-quint)）と並べて、Lean では不変条件を**帰納的な形に強化する**必要があることを示す。演習は [07_state_invariant](Exercises/07_state_invariant)。

**第 3 部（仕様を実行する）**: [docs/executable-spec.md](docs/executable-spec.md) では、Lean で書いた仕様を実行可能な Oracle にして、Python の本番実装と差分テストする。題材は Kent Beck の Money 例と価格計算。Lean の `Int` 除算がゼロ除算で 0 を返すことから「仕様の全域性が抜けていると Oracle が嘘をつく」まで扱う。演習は [08_executable_spec](Exercises/08_executable_spec)。Python 3.12 と uv が必要。

**読み物（概念）**: [docs/type-safety-vs-proof.md](docs/type-safety-vs-proof.md) では、「型安全」と「証明」が別の話であることを、中2の合同証明を例に分けて説明している。

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
（`Build completed successfully` が出れば環境は完成。手元では `(40 jobs)`。内訳は下の「検証状況」表を参照）

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

| 演習 | 内容 | ファイル |
|---|---|---|
| [00_prime](Exercises/00_prime) | 素数判定の手順を書く。`decide` で機械に確かめさせる | [Exercise](Exercises/00_prime/Exercise.lean) / [Solution](Exercises/00_prime/Solution.lean) |
| [01_prime_range](Exercises/01_prime_range) | 割る数を機械に並べさせる（`List.range`）。範囲ミスの危険 | [Exercise](Exercises/01_prime_range/Exercise.lean) / [Solution](Exercises/01_prime_range/Solution.lean) |
| [02_first_tactic](Exercises/02_first_tactic) | `constructor` で盤面が割れるのを見る | [Exercise](Exercises/02_first_tactic/Exercise.lean) / [Solution](Exercises/02_first_tactic/Solution.lean) |
| [03_backward_search](Exercises/03_backward_search) | `apply` でゴールが遡る（逆向き探索） | [Exercise](Exercises/03_backward_search/Exercise.lean) / [Solution](Exercises/03_backward_search/Solution.lean) |
| [04_case_split](Exercises/04_case_split) | `rcases` で場合分け。`obtain` / `⟨…⟩` も | [Exercise](Exercises/04_case_split/Exercise.lean) / [Solution](Exercises/04_case_split/Solution.lean) |
| [05_automation](Exercises/05_automation) | `simp` / `omega`。失敗する手も見る | [Exercise](Exercises/05_automation/Exercise.lean) / [Solution](Exercises/05_automation/Solution.lean) |
| [06_synthesis](Exercises/06_synthesis) | 総合演習（ド・モルガン、分配法則、対偶） | [Exercise](Exercises/06_synthesis/Exercise.lean) / [Solution](Exercises/06_synthesis/Solution.lean) |
| [07_state_invariant](Exercises/07_state_invariant) | 状態機械の不変条件。「売り越し」をルールで捕まえる | [Exercise](Exercises/07_state_invariant/Exercise.lean) / [Solution](Exercises/07_state_invariant/Solution.lean) |
| [08_executable_spec](Exercises/08_executable_spec) | 仕様を実行して Oracle にする。差分テストと切り捨ての位置 | [Exercise](Exercises/08_executable_spec/Exercise.lean) / [Solution](Exercises/08_executable_spec/Solution.lean) |

各ディレクトリに `Exercise.lean`（穴埋め）と `Solution.lean`（解答）がある。リンクから GitHub 上で直接開ける。

### 演習の進め方

```bash
# 穴埋めを解く（sorry があるので警告は出る）
lake env lean Exercises/02_first_tactic/Exercise.lean

# 自分の解答が正しいか確かめる
lake env lean Exercises/02_first_tactic/Solution.lean
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
| 10–20 | [00_prime](Exercises/00_prime) | 手順を書くと機械が検証する、を体感 |
| 20–30 | [01_prime_range](Exercises/01_prime_range) | 範囲を機械に書かせる。範囲ミスが静かに壊れる |
| 30–45 | [02_first_tactic](Exercises/02_first_tactic) | ゴールを見て手を選ぶ |
| 45–55 | [03_backward_search](Exercises/03_backward_search) | 逆向き探索 |
| 55–65 | [04_case_split](Exercises/04_case_split) | 分岐と記法 |
| 65–75 | [05_automation](Exercises/05_automation) | 自動化のブラックボックス化を議論 |
| 75–85 | [06_synthesis](Exercises/06_synthesis) | 総合演習 |
| 85–90 | まとめ＋背景の話 | 検証層へ接続 |

**時間が足りない場合**: `03_backward_search` と `04_case_split` を読み専用にし、`02` → `05` → `06` に絞る。素数（`00`・`01`）は落とさない。ここが「機械が検証する」の入口なので、飛ばすと後が伝わらない。

### つまずきポイント（実際に詰まる順）

1. **`List.range` の範囲ミス** — `List.range (n-2)` と `(n-1)` の違い。間違えても**エラーにならず、間違った答えが返る**。`00` と `01` で必ず突き合わせる
2. **`exact` と `apply` の区別** — `exact` はゴールを丸ごと埋める。`apply` はゴールを別のゴールに変換する
3. **`intro` 忘れ** — ゴールが `P → Q` のとき、まず `intro hp` で仮定を盤面に置く
4. **`∧` と `→` の混同** — 形が違えば使える手も違う
5. **`sorry` で通ってしまう** — `sorry` は警告 1 行だけでコンパイルが通る。証明ではない。次の手順で検出する:

   ```lean
   theorem my_thm (P : Prop) : P := by sorry
   #print axioms my_thm
   -- 'my_thm' depends on axioms: [sorryAx]
   ```

   `example` は名前が無いので `#print axioms` で覗けない。**名前付きで書く**こと。

6. **Infoview が出ない** — VS Code が `lakefile.toml` のあるディレクトリを開いているか確認

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
| 全 `Solution.lean`（9 ファイル）のコンパイル | Lean 4.36.0 で通過、rc=0、警告 0 |
| 全 `Exercise.lean` のコンパイル | `sorry` 警告のみ（想定どおり）、エラー 0 |
| `lake build` | `Build completed successfully (40 jobs)`（エラー 0。ジョブ数は並列度で変わる） |
| `07_state_invariant` の `Exercise.lean` | `sorry` 警告 10 件のみ（想定どおり）、エラー 0 |
| `08_executable_spec` の `Exercise.lean` | `sorry` 警告 7 件のみ（想定どおり）、エラー 0 |
| `08_executable_spec` の Oracle | `lake build billing_oracle` 通過。JSON Lines で応答、未登録レートは `no_rate` |
| `08_executable_spec` の差分テスト | クリーンクローンで `uv run pytest` → 8 passed（Hypothesis 500 例 ×2 + 単体 4） |
| `08_executable_spec` のカバレッジ | `--cov=billing --cov-branch` で 100%（Stmts 17 / Branch 2、Missing 0） |
| `08_executable_spec` の Mutation Test | `tools/mutation_check.py` で 4/4 検出 |
| `00_prime` の判定が正しい範囲 | 0〜168。最初の破綻は 169 = 13²（実測。0〜300 の不一致は [169,221,247,289,299] の合成数のみ） |
| `05_automation` の「失敗する手」が実際に落ちること | 実測で確認（`omega could not prove the goal` / `simp made no progress`。**4.36.0 時点の文言**） |
| `06_synthesis` の自動化表（どの問題が `simp`/`omega` で解けるか） | 独立検証で再確認（5-1 `simp` ✓、5-2 `simp [h]` ✓、5-3 `simp [h]` ✗） |
| `sorryAx` 検出手順 | 実出力で再現 |
| VS Code Infoview の画面文言 | 公式仕様ベース。実機目視は未実施 |

## 背景: なぜ今これを学ぶのか

2026 年 11 月、AI コーディングエージェントの量産と品質をどう両立するかが話題になった。
Lauren Tan（`poteto`）の講演は、その答えを **「検証の証拠物を人間がレビューする形に仕事を変える」** に置いた。
Lean と TLA+ は、その証拠物を作る道具の一つとして実際に使われている。

この系譜（手計算 → Mathematica / SymPy → NumPy・SciPy → STUMPY → Lean / TLA+）と「各段が何を保証しないか」は [docs/lineage.md](docs/lineage.md) にまとめた。

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
