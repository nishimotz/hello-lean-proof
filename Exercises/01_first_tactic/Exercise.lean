-- 01: 1手目を打つ — 盤面が変わるのを目で見る
--
-- 使い方: VS Code + Lean 4 拡張で開き、Infoview を見ながら 1 行ずつ進める
-- または: lake env lean Exercises/01_first_tactic/Exercise.lean

/-! ## 例題: ゴールが 2 つに割れる

`constructor` を打った瞬間にゴールが分岐する。
`·` は「いまのゴールにこのブロックを適用する」の印。
-/

example (P Q : Prop) (hp : P) (hq : Q) : P ∧ Q := by
  constructor
  · exact hp
  · exact hq

/-! ## 演習 1-1: 同じ形を自分で書く

仮定 `hp : P` と `hq : Q` から `Q ∧ P` を示せ。
`constructor` を使い、1 つめのゴールは `hq`、2 つめは `hp` で閉じる。
-/

example (P Q : Prop) (hp : P) (hq : Q) : Q ∧ P := by
  sorry

/-! ## 演習 1-2: `exact` だけで埋まる場面

ゴールと仮定の型が完全に一致するなら `exact` 1 手で終わる。
-/

example (P : Prop) (hp : P) : P := by
  sorry

/-! ## 観察メモ

1-1 で `constructor` を打った直後、Infoview には何と表示されたか。
ゴールの数と名前（`case left` / `case right` など）をメモせよ。
-/
