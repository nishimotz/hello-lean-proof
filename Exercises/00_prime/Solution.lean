-- 00: 素数を判定する — 手順を書くと機械が検証する（解答）
--
-- 使い方: lake env lean Exercises/00_prime/Solution.lean

/-! ## この演習の目的

**「どう確かめるか」を手順として書けば、機械が代わりに確かめてくれる**、と分かること。

## 素数とは

1 と自分自身以外では割り切れない、2 以上の整数。
- 7 は素数（2,3,4,5,6 のどれでも割り切れない）
- 8 は素数でない（2 で割り切れる）
- 1 は素数でない（2 未満）
- 2 は素数
-/

/-! ## 手順を書く（割る数を手で並べる版） -/

def isPrimeSmall (n : Nat) : Bool :=
  2 ≤ n && ([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].all (fun d => n % d != 0 || d == n))

/-! ## 動かしてみる

`#eval` は「この式を計算して結果を出せ」の命令。
-/

#eval isPrimeSmall 7     -- true
#eval isPrimeSmall 8     -- false
#eval isPrimeSmall 2     -- true
#eval isPrimeSmall 9     -- false
#eval isPrimeSmall 1     -- false

/-! ## 演習 00-1 の解答

`decide` は「具体的に計算して真偽を決めよ」の手。
-/

example : isPrimeSmall 7 = true := by
  decide

/-! ## 演習 00-2 の解答 -/

example : isPrimeSmall 8 = false := by
  decide

/-! ## 演習 00-3 の解答

ゴールが `A ∧ B` の形なので `constructor` で 2 つに割る。
-/

example : isPrimeSmall 7 = true ∧ isPrimeSmall 8 = false := by
  constructor
  · decide
  · decide

/-! ## この版の限界（実測値）

| n | isPrimeSmall n | 正しいか |
|---|---|---|
| 2 | true | ✓ |
| 7 | true | ✓ |
| 8 | false | ✓ |
| 11 | true | ✓ |
| 12 | false | ✓（12 は 2, 3, 4, 6 で割り切れる） |
| 13 | true | ✓（ただし偶然） |
| 14 | false | ✓ |

**13 が危ない**。13 は 13 で割り切れるが、13 はリストに無い。
だから「割り切れる数が無かった」と判断して `true` を返す。**理由が間違っている**。
次に 13 より上の素数が出てきたら破綻する（例: 素数を探すコードで 13 が「リスト外」になる）。

**手で並べたリストは範囲を間違えやすい**、というのがこの版の弱点。
13 以上を判定できないのはそのため。

2〜10 の範囲では正しい版と一致することを機械が確かめられる。

-/

/-! ## まとめ

- 素数を判定するには**手順**が要る（割ってみる）
- 手順を書けば、機械が**全部試して**くれる（`decide`）
- ただし手順が間違っていれば、機械は**間違った答えを正しく返す**
- 手で並べたリストは、範囲を間違えると壊れる

## 次へ

01 では「手で並べる」を「機械に並べさせる」（`List.range`）に変える。
-/
