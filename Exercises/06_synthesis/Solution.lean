-- 06: 総合演習 — 手で解いてから自動化に置き換える
--
-- 使い方: lake env lean Exercises/06_synthesis/Solution.lean
--
-- 進め方:
--   1. Exercise.lean を開き、まず手で解く（constructor / exact / apply / intro / obtain / rcases）
--   2. 解けたらこのファイルで別解（自動 tactic）と比べる
--   3. 「なぜ通ったか」を説明できるか自問する

/-! ## 演習 5-1: ド・モルガン（片方向）

`¬(P ∨ Q)` から `¬P ∧ ¬Q` を示せ。
`intro` で仮定を置き、`constructor` で 2 つに割り、`Or.inl` / `Or.inr` を当てる。
-/

example (P Q : Prop) : ¬(P ∨ Q) → ¬P ∧ ¬Q := by
  intro h
  constructor
  · intro hp
    exact h (Or.inl hp)
  · intro hq
    exact h (Or.inr hq)

-- 別解: simp 単独でも通る（Lean 4.36.0 で実測）
example (P Q : Prop) : ¬(P ∨ Q) → ¬P ∧ ¬Q := by
  simp

/-! ## 演習 5-2: 分配法則

`P ∧ (Q ∨ R)` から `(P ∧ Q) ∨ (P ∧ R)` を示せ。
-/

example (P Q R : Prop) (h : P ∧ (Q ∨ R)) : (P ∧ Q) ∨ (P ∧ R) := by
  obtain ⟨hp, hqr⟩ := h
  rcases hqr with hq | hr
  · exact Or.inl ⟨hp, hq⟩
  · exact Or.inr ⟨hp, hr⟩

-- 別解: 仮定 h を simp に渡すと通る（実測）
example (P Q R : Prop) (h : P ∧ (Q ∨ R)) : (P ∧ Q) ∨ (P ∧ R) := by
  simp [h]

/-! ## 演習 5-3: 対偶

`P → Q` から `¬Q → ¬P` を示せ。
-/

example (P Q : Prop) (h : P → Q) : ¬Q → ¬P := by
  intro hnq hp
  exact hnq (h hp)

/-! ## 演習 5-4: 自動化で置き換える

上の 3 問は、`simp` や `omega` で解けるか。**Lean 4.36.0 で実際に検証した結果**は次のとおり。

| 問題 | `simp` 単独 | `simp [h]` | `omega` | 手で解く |
|---|---|---|---|---|
| 5-1 ド・モルガン | **✓ 通る** | — | ✗ | ✓ |
| 5-2 分配法則 | ✗（no progress） | **✓ 通る** | ✗ | ✓ |
| 5-3 対偶 | ✗（no progress） | **✗ 落ちる**（実測） | ✗ | ✓ |

**この表から読み取ること**:

1. `omega` は命題論理を解かない（線形算術専用）。3 問とも ✗。
2. `simp` が通るかどうかは**仮定をヒントとして渡すか**で変わる。5-2 は `simp` 単独では落ち、`simp [h]` で通る。
3. **5-3 は `simp [h]` でも落ちる**。仮定が含意（`P → Q`）の形で、`simp` の書き換え規則に乗りにくいため。ここは手で解くしかない。

**結論**: 「手で 1 回解いてから自動化に置き換える」順序を守ると、どこで自動化が効いてどこで効かないかを判断できる。逆順（自動化から入る）だと、5-3 のような問題で延々と試行錯誤することになる。

**注意**: `simp` のエラー文言（`made no progress`）は Lean のバージョンで変わりうる。ここは 4.36.0 時点の記述。
-/
