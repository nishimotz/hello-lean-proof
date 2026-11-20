-- 02: 1手目を打つ — ゴールを見て手を選ぶ（解答）
--
-- 使い方: lake env lean Exercises/02_first_tactic/Solution.lean
--
-- Exercise.lean を先に開いて自分で考え、詰まったらこのファイルを見る。

/-! ## この演習の目的

**証明は「思いつき」ではなく「ゴールを見て手を選ぶ作業」だ**、と体で分かること。

## 記号

| 記号 | 読み | 意味 |
|---|---|---|
| `P Q : Prop` | ピー、キューは命題 | 真か偽かが決まる主張 |
| `hp : P` | エイチピーはピーの証明 | 「P は成り立つ」という証明に付けた名前 |
| `P ∧ Q` | ピーかつキュー | 両方が成り立つ |
| `⊢ P ∧ Q` | ゴール | 「これを示せ」 |
-/

/-! ## 例題: ゴールが 2 つに割れる -/

example (P Q : Prop) (hp : P) (hq : Q) : P ∧ Q := by
  constructor
  · exact hp
  · exact hq

/-! ## 演習 1-1 の解答

3 つの候補のうち、通るのは (b) `constructor` だけ。

### (a) `exact hp` を打つと

```lean
example (P Q : Prop) (hp : P) (hq : Q) : P ∧ Q := by
  exact hp
```

エラー: `type mismatch`
`hp` の型は `P`。ゴールの型は `P ∧ Q`。**形が違うので置けない**。

### (c) `apply hp` を打つと

```lean
example (P Q : Prop) (hp : P) (hq : Q) : P ∧ Q := by
  apply hp
```

エラー: `application type mismatch`
`apply` は「`hp` を関数としてゴールに当てる」手。`hp : P` は関数ではない（引数を取らない）。だから当たらない。

### (b) `constructor` で通る

ゴールが `A ∧ B` の形なら `constructor` が 2 つに割る。
-/

example (P Q : Prop) (hp : P) (hq : Q) : P ∧ Q := by
  constructor
  · exact hp
  · exact hq

/-! ## 演習 1-2 の解答: 順序を入れ替える

ゴールが `Q ∧ P` に変わった。`constructor` で割ると、1 つめのゴールが `Q`、2 つめが `P`。
だから **`exact` に渡す順序を入れ替える**。

- 前: `exact hp` → `exact hq`
- 今: `exact hq` → `exact hp`

**変えるのは `exact` の引数だけ。手の種類（`constructor`）は変わらない。**
-/

example (P Q : Prop) (hp : P) (hq : Q) : Q ∧ P := by
  constructor
  · exact hq
  · exact hp

/-! ## 演習 1-3 の解答: `exact` だけで埋まる場面

ゴールが `P` で、仮定に `hp : P` がある。**型が完全に一致**するので `exact` 1 手で終わる。
`constructor` は要らない（`constructor` は `∧` や `∨` のような「組み立てる」ゴールにしか効かない）。
-/

example (P : Prop) (hp : P) : P := by
  exact hp

/-! ## まとめ

- 証明は**ゴールを見て手を選ぶ**作業
- `constructor` は「ゴールを分解する」手
- `exact` は「仮定でゴールを埋める」手。**型が一致するときだけ**効く
- 通らない手を打っても**壊れない**。エラーが出るだけで盤面は元のまま

## 次へ

02 では `apply` を学ぶ。`exact` が「埋める」だったのに対し、`apply` は「変換する」。
-/
