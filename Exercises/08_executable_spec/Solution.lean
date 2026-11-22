-- 08: 実行可能仕様を Oracle にする — 解答
--
-- 使い方: lake env lean Exercises/08_executable_spec/Solution.lean
--
-- 第3部。前編で「証明＝探索ゲーム」、第2部で「ルールを書け、ケースを書くな」を扱った。
-- ここでは仕様を **実行できる関数** にして、Python 実装の正解判定器（Test Oracle）にする。
-- 題材は Kent Beck の Money 例（TDD by Example, 2002, Part I）と、その先にある
-- 「切り捨ての位置」問題。
--
-- 出典: Kent Beck, *Test-Driven Development: By Example* (2002)
--       Test Desiderata (2019) https://testdesiderata.com/

namespace Bill

/-! ## 1. 通貨と換算（Beck の Money 例） -/

inductive Currency where
  | jpy | usd | chf
  deriving Repr, DecidableEq

structure Money where
  amount : Int
  cur    : Currency
  deriving Repr, DecidableEq

inductive Expr where
  | one (m : Money)
  | add (a b : Expr)
  deriving Repr

/-- 為替表。1 USD = 2 CHF だけ登録されている。未登録の組は `none`。
**ここが第1の山場**。`Option` にしないと、未登録レートが黙って 0 になる。 -/
def rate : Currency → Currency → Option Int
  | .jpy, .jpy => some 1
  | .usd, .usd => some 1
  | .chf, .chf => some 1
  | .chf, .usd => some 2
  | _, _ => none

/-- 式を通貨 `to` に換算する。失敗は `Except` で理由付きで返す。
Lean の `Int` 除算はゼロ除算で 0 を返す（`#eval (5:Int)/0 = 0`）ので、
`Option Int` のまま割り算すると未登録レートが静かに 0 円になる。 -/
def reduce : Expr → Currency → Except String Money
  | .one m, to =>
    match rate m.cur to with
    | some r => if r = 0 then .error "zero_rate" else .ok ⟨m.amount / r, to⟩
    | none   => .error "no_rate"
  | .add a b, to => do
    let ra ← reduce a to
    let rb ← reduce b to
    return ⟨ra.amount + rb.amount, to⟩

/-! ## 2. 価格計算（明細・割引・税） -/

inductive Rank where
  | normal | silver | gold
  deriving Repr, DecidableEq

/-- 明細。`unit` は `Int`（返金・値引き訂正のため負を許す）、
`qty` は `Nat`（個数なので 0 以上。0 の明細は 0 円として扱う）。 -/
structure Line where
  unit : Int
  qty  : Nat
  deriving Repr, DecidableEq

def lineAmount (l : Line) : Int := l.unit * (l.qty : Int)

def subtotal : List Line → Int
  | [] => 0
  | l :: ls => lineAmount l + subtotal ls

def discountPct : Rank → Int
  | .normal => 0
  | .silver => 5
  | .gold   => 10

/-- 正しい合計: 小計に割引を **1 回だけ** 適用し、切り捨てはその 1 回だけ。 -/
def total (r : Rank) (ls : List Line) : Int :=
  let s := subtotal ls
  s - s * discountPct r / 100

/-- 間違った合計: 明細ごとに割引を適用してから足す。AI が書きがちな形。
切り捨てが明細の数だけ起きる。 -/
def totalPerLine : Rank → List Line → Int
  | _, [] => 0
  | r, l :: ls =>
    let s := lineAmount l
    (s - s * discountPct r / 100) + totalPerLine r ls

def withTax (t : Int) : Int := t + t * 10 / 100

/-! ## 3. コンパイル時の具体例チェック -/

-- Beck の Money 例: $5 + 10 CHF = $10（2 CHF = 1 USD）
#guard (reduce (.add (.one ⟨5, .usd⟩) (.one ⟨10, .chf⟩)) .usd).toOption.map (·.amount) == some 10
-- 未登録の組は成功しない（静かに 0 にならない）
#guard ((reduce (.one ⟨100, .jpy⟩) .usd) : Except String Money).toOption.isNone
-- 小計 12000 円、gold（10%）→ 12000 - 1200 = 10800
#guard total .gold [⟨4000, 3⟩] == 10800
-- 税 10%: 10800 → 11880
#guard withTax 10800 == 11880

/-! ## 4. 定理: 仕様の性質 -/

/-- 単価が非負なら明細金額も非負。 -/
theorem lineAmount_nonneg (l : Line) (h : 0 ≤ l.unit) : 0 ≤ lineAmount l := by
  unfold lineAmount
  have hq : (0 : Int) ≤ (l.qty : Int) := Int.natCast_nonneg _
  exact Int.mul_nonneg h hq

/-- 単価がすべて非負なら小計も非負。 -/
theorem subtotal_nonneg (ls : List Line) (h : ∀ l ∈ ls, 0 ≤ l.unit) :
    0 ≤ subtotal ls := by
  induction ls with
  | nil => simp [subtotal]
  | cons l rest ih =>
    simp only [subtotal]
    exact Int.add_nonneg (lineAmount_nonneg l (h l (by simp)))
      (ih (fun x hx => h x (by simp [hx])))

/-- **第2の山場**: 明細ごとの割引と合計への割引は一致しない。
切り捨ての位置が違うので、割引があれば一般にはずれる。
反例: gold・999 円 × 1 と 1 円 × 1。
（「常に違う」ではない。割り切れる明細では一致する。） -/
theorem per_line_differs :
    totalPerLine .gold [⟨999, 1⟩, ⟨1, 1⟩] ≠ total .gold [⟨999, 1⟩, ⟨1, 1⟩] := by
  decide

/-- 割引率が 0 なら両者は一致する。差は「割引がある時だけ」出る。 -/
theorem normal_agrees (ls : List Line) :
    totalPerLine .normal ls = total .normal ls := by
  induction ls with
  | nil => simp [totalPerLine, total, subtotal]
  | cons l rest ih =>
    simp only [totalPerLine, total, subtotal, discountPct, lineAmount] at *
    simp [Int.mul_zero, ih]

end Bill
