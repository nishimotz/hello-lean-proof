-- 03: 場合分け — 盤面が分岐する
--
-- 使い方: lake env lean Exercises/03_case_split/Solution.lean
-- または VS Code で Infoview を見ながら Exercise.lean を埋める

/-! ## 記法の最小辞典（この章で使うもの）

| 記法 | 読み | 何をするか |
|---|---|---|
| `obtain ⟨a, b⟩ := h` | h から a と b を取り出す | `h : P ∧ Q` を `ha : P` と `hb : Q` に分解 |
| `rcases h with x | y` | h で場合分け | `h : P ∨ Q` を 2 つのケースに分ける |
| `⟨a, b⟩` | ペアを作る | `⟨hp, hq⟩` で `P ∧ Q` を 1 手で埋める |
| `Or.inl h` | 左を選ぶ | `h : P` から `P ∨ Q` を作る |
| `Or.inr h` | 右を選ぶ | `h : Q` から `P ∨ Q` を作る |
-/

/-! ## 例題: rcases で分岐する
-/

example (P Q : Prop) (h : P ∨ Q) : Q ∨ P := by
  rcases h with hp | hq
  · exact Or.inr hp
  · exact Or.inl hq

/-! ## 演習 3-1: obtain で分解する

`h : P ∧ Q` から `P` を取り出せ。
-/

example (P Q : Prop) (h : P ∧ Q) : P := by
  sorry

/-! ## 演習 3-2: 分解してから組み直す

`h : P ∧ Q` から `Q ∧ P` を作れ。
`obtain` で分解し、`constructor` で組み直す。
-/

example (P Q : Prop) (h : P ∧ Q) : Q ∧ P := by
  sorry

/-! ## 演習 3-3: 1 手でペアを作る

演習 3-2 を `exact ⟨…, …⟩` の 1 手で書け。
-/

example (P Q : Prop) (h : P ∧ Q) : Q ∧ P := by
  sorry

/-! ## 演習 3-4: 分配法則

`h : P ∧ (Q ∨ R)` から `(P ∧ Q) ∨ (P ∧ R)` を示せ。
`obtain` で分解し、`rcases` で場合分けする。
-/

example (P Q R : Prop) (h : P ∧ (Q ∨ R)) : (P ∧ Q) ∨ (P ∧ R) := by
  sorry

/-! ## 観察メモ

演習 3-4 で `rcases` を打った直後、ゴールはいくつになったか。
それぞれのケースで、どの仮定が使えるか。
-/
