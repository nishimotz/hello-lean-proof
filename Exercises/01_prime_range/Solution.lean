-- 01: 割る数を機械に並べさせる — List.range（解答）
--
-- 使い方: lake env lean Exercises/01_prime_range/Solution.lean

/-! ## この演習の目的

**手で並べたリストを、機械に計算させると壊れにくくなる**、と分かること。

## `List.range` とは

`List.range k` は `0` から `k-1` までの数を並べる。**`k` 個**入る（`k` 自体は入らない）。
-/

#eval List.range 5     -- [0, 1, 2, 3, 4]
#eval List.range 0     -- []

/-! ## 正しい版

`n = 7` のとき、割る数は `2..6` の 5 個。`List.range (7 - 2) = [0,1,2,3,4]` に `+2` する。
-/

def isPrime (n : Nat) : Bool :=
  2 ≤ n && (List.range (n - 2)).all (fun i => n % (i + 2) != 0)

#eval isPrime 7      -- true
#eval isPrime 8      -- false
#eval isPrime 13     -- true   ← 00 の簡易版では理由が誤っていた
#eval isPrime 97     -- true
#eval isPrime 1      -- false

/-! ## 00 の版との一致
-/

def isPrimeSmall (n : Nat) : Bool :=
  2 ≤ n && ([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].all (fun d => n % d != 0 || d == n))

example : (List.range 9).all (fun i => isPrimeSmall (i + 2) == isPrime (i + 2)) = true := by
  decide

/-! ## 演習 01-1 の解答 -/

example : isPrime 13 = true := by
  decide

/-! ## 演習 01-2 の解答

`decide` を各項に分けて書くと、「なぜ 13 が素数か」が読める形になる。

`13 % 2 = 1` とは「13 を 2 で割った余りは 1」の意味。0 でなければ割り切れない。
-/

example : (13 % 2, 13 % 3, 13 % 4, 13 % 5) = (1, 1, 1, 3) := by
  decide

example : 13 % 6 = 1 := by decide
example : 13 % 7 = 6 := by decide
example : 13 % 8 = 5 := by decide
example : 13 % 9 = 4 := by decide
example : 13 % 10 = 3 := by decide
example : 13 % 11 = 2 := by decide
example : 13 % 12 = 1 := by decide

-- まとめて「どれも 0 でない」
example : 13 % 2 ≠ 0 ∧ 13 % 3 ≠ 0 ∧ 13 % 4 ≠ 0 ∧ 13 % 5 ≠ 0 ∧
          13 % 6 ≠ 0 ∧ 13 % 7 ≠ 0 ∧ 13 % 8 ≠ 0 ∧ 13 % 9 ≠ 0 ∧
          13 % 10 ≠ 0 ∧ 13 % 11 ≠ 0 ∧ 13 % 12 ≠ 0 := by
  decide

-- 0 にならないことの意味: 割り切れない = 約数が無い
-- 13 の約数は 1 と 13 だけ。だから素数。

/-! ## 演習 01-3 の解答: わざと範囲を間違える

`List.range (n - 1)` は `n - 1` 個、つまり `0..n-2`、`+2` して `2..n` を調べる。
**`n` 自身で割って余り 0** になるから、素数でも `false` になる。
-/

def isPrimeBuggy (n : Nat) : Bool :=
  2 ≤ n && (List.range (n - 1)).all (fun i => n % (i + 2) != 0)

#eval isPrimeBuggy 7     -- false ← エラーではなく、間違った答えが「正しく」返る
#eval isPrimeBuggy 13    -- false

-- 何が起きたか: 7 は「7 で割り切れる」と判定された
#eval 7 % 7              -- 0

/-! ## まとめ

- `List.range k` は `0..k-1` の `k` 個
- 範囲を1つ間違えると、**エラーにならずに間違った答えが返る**（一番危ないバグ）
- `decide` は計算を全部やってくれるが、「なぜ」は言わない
- 手順を正しく書けば、機械は正しく検証する。手順が間違っていれば、機械は間違った答えを正しく返す

## 次へ

02 では「2 は偶数、3 は奇数」を題材に、`constructor` でゴールを 2 つに割る手を学ぶ。
-/
