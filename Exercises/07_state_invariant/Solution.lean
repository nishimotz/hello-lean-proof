-- 07: 状態機械の不変条件 — 解答
--
-- 使い方: lake env lean Exercises/07_state_invariant/Solution.lean
--
-- 検証: Lean 4.36.0、標準ライブラリのみ、rc=0。
-- 題材は hello-quint（Quint / TLA+ 版）と同じ。 https://github.com/nishimotz/hello-quint

namespace Ticket

structure St where
  stock   : Int
  sold    : Int
  checked : Nat
  deriving Repr, DecidableEq

def init : St := ⟨2, 0, 0⟩

def NoOversell (s : St) : Prop := s.sold ≤ 2

/-! ## 7-1: バグのある遷移 -/

inductive StepBuggy : St → St → Prop where
  | check : ∀ (a b : Int) (c : Nat), StepBuggy ⟨a, b, c⟩ ⟨a, b, c + 1⟩
  | purchase : ∀ (a b : Int) (c : Nat), 1 ≤ c →
      StepBuggy ⟨a, b, c⟩ ⟨a - 1, b + 1, c - 1⟩

inductive ReachBuggy : St → Prop where
  | init : ReachBuggy init
  | step (s t : St) : ReachBuggy s → StepBuggy s t → ReachBuggy t

/-! ## 7-2: 反例の構成（Quint の State 0〜6 に対応） -/

theorem buggy_oversell : ReachBuggy ⟨-1, 3, 0⟩ := by
  have h1 : StepBuggy ⟨2, 0, 0⟩ ⟨2, 0, 1⟩ := StepBuggy.check 2 0 0
  have h2 : StepBuggy ⟨2, 0, 1⟩ ⟨2, 0, 2⟩ := StepBuggy.check 2 0 1
  have h3 : StepBuggy ⟨2, 0, 2⟩ ⟨2, 0, 3⟩ := StepBuggy.check 2 0 2
  have h4 : StepBuggy ⟨2, 0, 3⟩ ⟨1, 1, 2⟩ := StepBuggy.purchase 2 0 3 (by decide)
  have h5 : StepBuggy ⟨1, 1, 2⟩ ⟨0, 2, 1⟩ := StepBuggy.purchase 1 1 2 (by decide)
  have h6 : StepBuggy ⟨0, 2, 1⟩ ⟨-1, 3, 0⟩ := StepBuggy.purchase 0 2 1 (by decide)
  exact ReachBuggy.step _ _ (ReachBuggy.step _ _
    (ReachBuggy.step _ _ (ReachBuggy.step _ _
      (ReachBuggy.step _ _ (ReachBuggy.step _ _ ReachBuggy.init h1) h2) h3) h4) h5) h6

theorem buggy_violates : ∃ s, ReachBuggy s ∧ ¬ NoOversell s := by
  refine ⟨⟨-1, 3, 0⟩, buggy_oversell, ?_⟩
  simp [NoOversell]

/-! ## 7-3: 直した実装 -/

inductive StepFixed : St → St → Prop where
  | check : ∀ (a b : Int) (c : Nat), StepFixed ⟨a, b, c⟩ ⟨a, b, c + 1⟩
  | purchase : ∀ (a b : Int) (c : Nat), 1 ≤ c → 0 < a →
      StepFixed ⟨a, b, c⟩ ⟨a - 1, b + 1, c - 1⟩
  | soldOut : ∀ (a b : Int) (c : Nat), 1 ≤ c → a ≤ 0 →
      StepFixed ⟨a, b, c⟩ ⟨a, b, c - 1⟩

inductive ReachFixed : St → Prop where
  | init : ReachFixed init
  | step (s t : St) : ReachFixed s → StepFixed s t → ReachFixed t

/-! ## 7-4: 不変条件の強化

`NoOversell` 単独では帰納的でない。`sold ≤ 2` から1手で `sold ≤ 2` を出すには
在庫との関係が要る。だから `sold + stock = 2` を連言で持つ。
-/

def Inv (s : St) : Prop := 0 ≤ s.stock ∧ s.sold + s.stock = 2

theorem inv_init : Inv init := by
  simp [Inv, init]

theorem inv_check (a b : Int) (c : Nat) (h : Inv ⟨a, b, c⟩) :
    Inv ⟨a, b, c + 1⟩ := by
  simpa [Inv] using h

theorem inv_purchase (a b : Int) (c : Nat) (_hc : 1 ≤ c) (ha : 0 < a)
    (h : Inv ⟨a, b, c⟩) :
    Inv ⟨a - 1, b + 1, c - 1⟩ := by
  simp only [Inv] at h ⊢
  omega

theorem inv_soldOut (a b : Int) (c : Nat) (_hc : 1 ≤ c) (_ha : a ≤ 0)
    (h : Inv ⟨a, b, c⟩) :
    Inv ⟨a, b, c - 1⟩ := by
  simpa [Inv] using h

/-! ## 7-5: 1手ずつの保存 -/

theorem inv_step (s t : St) (h : Inv s) (hs : StepFixed s t) : Inv t := by
  obtain ⟨a, b, c⟩ := s
  cases hs with
  | check a b c => exact inv_check a b c h
  | purchase a b c hc ha => exact inv_purchase a b c hc ha h
  | soldOut a b c hc ha => exact inv_soldOut a b c hc ha h

/-! ## 7-6: 主定理 -/

theorem fixed_no_oversell (s : St) (hr : ReachFixed s) : NoOversell s := by
  have h : Inv s := by
    induction hr with
    | init => exact inv_init
    | step s' t hr' hst ih => exact inv_step s' t ih hst
  obtain ⟨h1, h2⟩ := h
  simp only [NoOversell]
  omega

/-! ## 7-7: 具体値での確認 -/

theorem fixed_example_ok : NoOversell ⟨0, 2, 1⟩ := by
  simp [NoOversell]

theorem buggy_example_bad : ¬ NoOversell ⟨-1, 3, 0⟩ := by
  simp [NoOversell]

/-! ## Quint との対応

| 記事 / hello-quint（Quint） | この演習（Lean 4） |
|---|---|
| `pure val USERS = Set("alice","bob","carol")` | 人数を持たず `c : Nat` で任意 |
| `pure val INITIAL_STOCK = 2` | `NoOversell` と `Inv` にリテラル `2` |
| `val noOversell = sold <= INITIAL_STOCK` | `def NoOversell (s : St) : Prop := s.sold ≤ 2` |
| `quint run` でランダム探索 | 不要（証明が覆う） |
| `quint verify --backend=tlc` で29状態を全探索 | 帰納法1本。状態数に依存しない |
| 反例トレースの自動表示 | `buggy_oversell` を手で構成（State 0〜6 に対応） |
| ルールをそのまま渡せる | **`Inv` への強化が必要** |
| `--mbt` で実装に1000トレースを解かせる | Lean 単体では閉じない（別途、抽出か外部突き合わせ） |

Lean が有利な点: 人数・在庫数を固定しなくても証明が通る
（`a`/`b` は任意の `Int`、`c` は任意の `Nat`）。
不利な点: 強化を思いつかないと詰まる。Quint の「ルールを書け」は
Lean では「**帰納的な不変条件を書け**」に読み替えが必要。
-/

end Ticket
