-- 01: 割る数を機械に並べさせる — List.range
--
-- 使い方: VS Code + Lean 4 拡張で開く
-- または: lake env lean Exercises/01_prime_range/Solution.lean

/-! ## この演習の目的

**手で並べたリストを、機械に計算させると壊れにくくなる**、と分かること。

00 では割る数を `[2, 3, 4, ..., 12]` と手で書いた。だから 13 以上で破綻した。
ここでは「2 から n-1 まで」を機械に作らせる。

## `List.range` とは

`List.range k` は `0` から `k-1` までの数を並べる。

```lean
#eval List.range 5     -- [0, 1, 2, 3, 4]
#eval List.range 0     -- []
```

**`k` 個の数**が入る（`k` 自体は入らない）。ここが最初の落とし穴。
-/

/-! ## 落とし穴: 範囲を1つ間違えると壊れる

`n = 7` のとき、割る数は `2, 3, 4, 5, 6` の5個。
`List.range` で作るなら `[0,1,2,3,4]` を作って `+2` すればよい。つまり `List.range 5`。

`n - 2` で `5` になる。だから `List.range (n - 2)` が正しい。

**もし `List.range (n - 1)` と書いたら**、`[0..5]` に `+2` で `2..7` を調べる。
**7 自身で割って余り 0** になるから、`isPrime 7` が `false` になる。エラーにはならず、答えだけが間違う。
-/

/-! ## 正しい版
-/

def isPrime (n : Nat) : Bool :=
  2 ≤ n && (List.range (n - 2)).all (fun i => n % (i + 2) != 0)

#eval isPrime 7      -- true
#eval isPrime 8      -- false
#eval isPrime 13     -- true  （00 の簡易版は 169 から壊れる）
#eval isPrime 97     -- true
#eval isPrime 1      -- false

/-! ## 00 の版との比較

00 の `isPrimeSmall` と、この `isPrime` が 2〜10 で一致することを機械に確かめさせる。
-/

def isPrimeSmall (n : Nat) : Bool :=
  2 ≤ n && ([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].all (fun d => n % d != 0 || d == n))

-- 2 から 10 までは同じ答え
example : (List.range 9).all (fun i => isPrimeSmall (i + 2) == isPrime (i + 2)) = true := by
  decide

/-! ## 演習 01-1: 13 が素数であることを確かめる

`decide` で計算させるだけでよい。まず動く形を体験する。
-/

example : isPrime 13 = true := by
  sorry

/-! ## 演習 01-2: `decide` を使わずに、13 が素数である理由を書く

これがこの章の本題。`decide` は「全部計算した」としか言わない。
**なぜ 13 が素数なのか** を、割り算の結果で示せ。

13 が素数と言えるのは「2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 のどれでも割り切れない」から。
Lean では `decide` を各項に分けて書ける。
-/

example : (13 % 2, 13 % 3, 13 % 4, 13 % 5) = (1, 1, 1, 3) := by
  decide

-- 残りも確かめて、「どれも 0 でない」を並べる
example : 13 % 2 ≠ 0 ∧ 13 % 3 ≠ 0 ∧ 13 % 4 ≠ 0 ∧ 13 % 5 ≠ 0 ∧
          13 % 6 ≠ 0 ∧ 13 % 7 ≠ 0 ∧ 13 % 8 ≠ 0 ∧ 13 % 9 ≠ 0 ∧
          13 % 10 ≠ 0 ∧ 13 % 11 ≠ 0 ∧ 13 % 12 ≠ 0 := by
  sorry

/-! ## 演習 01-3: 範囲をわざと間違える

`List.range (n - 1)` にした版を書いて、`isPrimeBuggy 7` が `false` になることを確かめよ。
**エラーではなく、間違った答えが正しく返る**。これが一番危ない種類のバグ。

（98 行目の `#eval` は何も警告しない。もし `example : isPrimeBuggy 7 = true := by decide` と書けば、
「`isPrimeBuggy 7 = true` は偽である」とエラーになる。この差を見よ）
-/

def isPrimeBuggy (n : Nat) : Bool :=
  2 ≤ n && (List.range (n - 1)).all (fun i => n % (i + 2) != 0)

#eval isPrimeBuggy 7     -- 何が出るか予想してから実行

/-! ## まとめ

- `List.range k` は `0..k-1` の `k` 個
- 範囲を1つ間違えると、**エラーにならずに間違った答えが返る**
- `decide` は計算を全部やってくれるが、「なぜ」は言わない
- 手順を正しく書けば、機械は正しく検証する。手順が間違っていれば、機械は間違った答えを正しく返す
-/
