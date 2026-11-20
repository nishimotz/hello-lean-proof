-- 04: 自動化に任せる — simp と omega
--
-- 使い方: lake env lean Exercises/04_automation/Solution.lean
--
-- この章の目的は「自動 tactic は便利だが、通った理由を説明できない」を体感すること。
-- 失敗する手もわざと載せてある。エラーは盤面を変えない（違反手）。

/-! ## 例題: simp

`simp` は書き換え規則を当てまくる。仮定をヒントとして渡せる。
-/

example (P Q : Prop) (hp : P) (hq : Q) : P ∧ Q := by
  simp [hp, hq]

/-! ## 演習 4-1: simp で等式を片付ける
-/

example (n : Nat) : n + 0 = n := by
  sorry

/-! ## 演習 4-2: omega

`omega` は整数・自然数の線形算術を解く。
-/

example (a b : Nat) (h : a = b) : b = a := by
  sorry

/-! ## 演習 4-3: omega で連立を解く
-/

example (a b : Nat) (h1 : a + 1 = b) (h2 : b = 3) : a = 2 := by
  sorry

/-! ## 失敗する手（わざと載せている）

次の 2 行は**必ずエラーになる**。写経すると赤くなるが、それは正常。
「エラー = 違反手。盤面は変わらない」を確認する。

1. `omega` は線形算術用。命題論理の `P ∧ Q` には効かない。

   ```lean
   example (P Q : Prop) (h : P ∧ Q) : Q ∧ P := by
     omega
   ```

2. `simp` は仮定を渡さないと何も分からないことがある。

   ```lean
   example (P Q : Prop) (h : P ∧ Q) : Q ∧ P := by
     simp
   ```

   この場合 `simp [h]` なら通る。**引数の有無で結果が変わる**のが分かりにくさの正体。

-/

/-! ## 議論ポイント

1. `simp` が通ったとき、あなたは**なぜ通ったか**を説明できるか。
2. 説明できないまま `simp` を残すと、半年後の自分は何が起きるか。
3. 「手で 1 回通す → 自動化に置き換える」順序を守らないと、何が壊れるか。
-/
