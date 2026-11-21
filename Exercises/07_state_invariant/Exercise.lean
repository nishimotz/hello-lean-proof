-- 07: 状態機械の不変条件 — 「売り越し」をルールで捕まえる
--
-- 使い方: lake env lean Exercises/07_state_invariant/Solution.lean
--
-- これは hello-quint（Quint / TLA+ 版）と同じ題材を Lean 4 で書いたもの。
-- https://github.com/nishimotz/hello-quint
--
-- 題材: チケット販売。確認画面で在庫を見て、確定ボタンで在庫を1枚減らす。
-- AI が書いた実装は確定時に在庫を再確認しないので、確認と確定の間に
-- 他の人が買うと在庫が負になる（売り越し）。
--
-- この演習の山場は「ルール（不変条件）を書くだけでは証明が通らない」こと。
-- 帰納法に載る形（帰納的な不変条件）に強化する必要がある。
-- モデル検査（Quint の `quint verify`）はこの強化を自動でやってくれない代わりに、
-- こちらは人数・在庫数を固定しなくても証明が通る。

/-! ## 状態

`stock` を `Int` にするのが要点。`Nat` にすると負にならず、
**売り越しというバグそのものが型で表現できなくなる**。
-/

namespace Ticket

structure St where
  stock   : Int   -- 在庫
  sold    : Int   -- 売れた枚数
  checked : Nat   -- 確認済み・未購入の人数
  deriving Repr, DecidableEq

/-- 初期状態: チケット2枚、誰も確認していない。 -/
def init : St := ⟨2, 0, 0⟩

/-- 守るべきルール: 売れた枚数は初期在庫を超えない。 -/
def NoOversell (s : St) : Prop := s.sold ≤ 2

/-! ## 演習 7-1: バグのある遷移を書く

`check` は確認画面を開く操作。`purchase` は確定ボタン。
AI が書いた実装は `purchase` で在庫を見ない。

コンストラクタは `∀ (a b : Int) (c : Nat), ...` と**明示的な束縛子**で書く。
`s : St` を暗黙にすると `cases` で名前が拾えない。
-/

inductive StepBuggy : St → St → Prop where
  | check : ∀ (a b : Int) (c : Nat), StepBuggy ⟨a, b, c⟩ ⟨a, b, c + 1⟩
  | purchase : ∀ (a b : Int) (c : Nat), 1 ≤ c →
      StepBuggy ⟨a, b, c⟩ ⟨a - 1, b + 1, c - 1⟩

/-- 到達可能 = `init` から `StepBuggy` を有限回。 -/
inductive ReachBuggy : St → Prop where
  | init : ReachBuggy init
  | step (s t : St) : ReachBuggy s → StepBuggy s t → ReachBuggy t

/-! ## 演習 7-2: 反例を構成する

3人が確認してから全員が確定すると、在庫2枚に対して3枚売れる。
`ReachBuggy.step` を6回つなぐ。

ヒント: `StepBuggy.check 2 0 0` のように引数を明示すると型が決まる。
`by decide` は `1 ≤ 3` のような具体値の不等式を閉じる。
-/

theorem buggy_oversell : ReachBuggy ⟨-1, 3, 0⟩ := by
  sorry

/-- だから AI の実装はルールを破る。 -/
theorem buggy_violates : ∃ s, ReachBuggy s ∧ ¬ NoOversell s := by
  sorry

/-! ## 演習 7-3: 直した実装

`purchase` の前提に `0 < a`（確定時に在庫がある）を足す。
在庫が尽きたあとの確定は `soldOut` で受ける（在庫は変えず、確認済みを減らす）。
-/

inductive StepFixed : St → St → Prop where
  | check : ∀ (a b : Int) (c : Nat), StepFixed ⟨a, b, c⟩ ⟨a, b, c + 1⟩
  | purchase : ∀ (a b : Int) (c : Nat), 1 ≤ c → 0 < a →
      StepFixed ⟨a, b, c⟩ ⟨a - 1, b + 1, c - 1⟩
  | soldOut : ∀ (a b : Int) (c : Nat), 1 ≤ c → a ≤ 0 →
      StepFixed ⟨a, b, c⟩ ⟨a, b, c - 1⟩

inductive ReachFixed : St → Prop where
  | init : ReachFixed init
  | step (s t : St) : ReachFixed s → StepFixed s t → ReachFixed t

/-! ## 演習 7-4: ここが山場 — 不変条件を強化する

`NoOversell`（`sold ≤ 2`）をそのまま帰納法に載せようとすると詰まる。
1手進めるには「在庫と売上の関係」が要るから。

**強化した不変条件**を書く。在庫が非負で、売上と在庫の合計が初期在庫に等しい。

これは Quint では不要な作業。`quint verify` は 29 状態を機械的に尽くすので、
人間が「証明が通る形」に書き直す必要がない。Lean では必要になる。
-/

def Inv (s : St) : Prop := 0 ≤ s.stock ∧ s.sold + s.stock = 2

theorem inv_init : Inv init := by
  sorry

theorem inv_check (a b : Int) (c : Nat) (h : Inv ⟨a, b, c⟩) :
    Inv ⟨a, b, c + 1⟩ := by
  sorry

theorem inv_purchase (a b : Int) (c : Nat) (_hc : 1 ≤ c) (ha : 0 < a)
    (h : Inv ⟨a, b, c⟩) :
    Inv ⟨a - 1, b + 1, c - 1⟩ := by
  sorry

theorem inv_soldOut (a b : Int) (c : Nat) (_hc : 1 ≤ c) (_ha : a ≤ 0)
    (h : Inv ⟨a, b, c⟩) :
    Inv ⟨a, b, c - 1⟩ := by
  sorry

/-! ## 演習 7-5: 1手ずつ保存されることを示す

`obtain ⟨a, b, c⟩ := s` で状態を分解してから `cases hs` すると、
コンストラクタの束縛子と衝突しない。
-/

theorem inv_step (s t : St) (h : Inv s) (hs : StepFixed s t) : Inv t := by
  sorry

/-! ## 演習 7-6: 主定理

`ReachFixed` の帰納法。`init` は `inv_init`、`step` は `inv_step`。
最後に `Inv` から `NoOversell` を出す（`omega`）。
-/

theorem fixed_no_oversell (s : St) (hr : ReachFixed s) : NoOversell s := by
  sorry

/-! ## 演習 7-7: 具体値でも確かめる

TLC の「29状態を全部見た」に相当する確認。証明の代わりではない。
-/

theorem fixed_example_ok : NoOversell ⟨0, 2, 1⟩ := by
  sorry

theorem buggy_example_bad : ¬ NoOversell ⟨-1, 3, 0⟩ := by
  sorry

end Ticket
