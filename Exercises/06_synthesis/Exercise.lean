-- 06: 総合演習 — 手で解いてから自動化に置き換える
--
-- 使い方: lake env lean Exercises/06_synthesis/Solution.lean
--
-- 進め方:
--   1. Exercise.lean を開き、まず手で解く（constructor / exact / apply / intro / obtain / rcases）
--   2. 解けたら Solution.lean で別解（自動 tactic）と比べる
--   3. 「なぜ通ったか」を説明できるか自問する

/-! ## 演習 5-1: ド・モルガン（片方向）

`¬(P ∨ Q)` から `¬P ∧ ¬Q` を示せ。
`intro` で仮定を置き、`constructor` で 2 つに割り、背理法気味に `Or.inl` / `Or.inr` を当てる。
-/

example (P Q : Prop) : ¬(P ∨ Q) → ¬P ∧ ¬Q := by
  sorry

/-! ## 演習 5-2: 分配法則

`P ∧ (Q ∨ R)` から `(P ∧ Q) ∨ (P ∧ R)` を示せ。
-/

example (P Q R : Prop) (h : P ∧ (Q ∨ R)) : (P ∧ Q) ∨ (P ∧ R) := by
  sorry

/-! ## 演習 5-3: 対偶

`P → Q` から `¬Q → ¬P` を示せ。
-/

example (P Q : Prop) (h : P → Q) : ¬Q → ¬P := by
  sorry

/-! ## 演習 5-4: 自動化で置き換える

上の 3 問のうち、`simp` か `omega` だけで解けるものはあるか。
実際に試して、通ったものと落ちたものを記録せよ。

| 問題 | `simp` | `omega` | 手で解く |
|---|---|---|---|
| 5-1 ド・モルガン | | | |
| 5-2 分配法則 | | | |
| 5-3 対偶 | | | |

**考察**: 自動 tactic が通らなかった問題は、なぜ通らなかったか。
-/
