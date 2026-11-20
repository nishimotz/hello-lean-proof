-- 03: 逆向き探索 — apply でゴールが遡る
--
-- 使い方: lake env lean Exercises/03_backward_search/Solution.lean
-- または VS Code で Infoview を見ながら Exercise.lean を埋める

/-! ## 例題: apply でゴールが手前に戻る

ゴール `R` に対して `h2 : Q → R` を apply すると、
ゴールが `Q` に変わる。「R を示すには Q を示せばよい」と読み替える。
-/

example (P Q R : Prop) (h1 : P → Q) (h2 : Q → R) (hp : P) : R := by
  apply h2
  apply h1
  exact hp

/-! ## 演習 2-1: 1 段だけ遡る

`h : P → Q` と `hp : P` から `Q` を示せ。
-/

example (P Q : Prop) (h : P → Q) (hp : P) : Q := by
  sorry

/-! ## 演習 2-2: 2 段遡る

`h1 : A → B`、`h2 : B → C`、`ha : A` から `C` を示せ。
後ろから攻める。`apply h2` → `apply h1` → `exact ha`。
-/

example (A B C : Prop) (h1 : A → B) (h2 : B → C) (ha : A) : C := by
  sorry

/-! ## 演習 2-3: intro と apply の合わせ技

ゴールが含意（`→`）のとき、まず `intro` で仮定を盤面に置く。
そのあとで `apply` を使う。
-/

example (P Q : Prop) (h : Q → P) : Q → P := by
  sorry

/-! ## 観察メモ

演習 2-2 で `apply h2` を打った直後、ゴールは何になったか。
`apply h1` の後はどうなったか。**ゴールの変化を時系列で書け。**
-/
