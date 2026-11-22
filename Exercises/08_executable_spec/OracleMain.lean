-- 08: 実行可能仕様を Oracle にする — JSON Lines Oracle
--
-- 使い方:
--   lake build billing_oracle
--   printf '{"op":"total","rank":"gold","lines":[[4000,3]]}\n' | ./.lake/build/bin/billing_oracle
--
-- 1 行 1 JSON。stdin から読み、stdout に 1 行で返す。
-- 常駐プロセスとして使うので、ケースごとに Lean を起動しない。
import Lean
import Exercises.«08_executable_spec».Solution

open Lean
open Bill

/-! ## JSON の読み取り -/

private def numToInt? (n : JsonNumber) : Except String Int :=
  if n.exponent = 0 then .ok n.mantissa
  else .error s!"expected integer, got mantissa={n.mantissa} exponent={n.exponent}"

private def getNat? (j : Json) (k : String) : Except String Nat := do
  let v ← j.getObjVal? k |>.mapError (fun e => s!"{k}: {e}")
  match v with
  | .num n => .ok (← numToInt? n).toNat
  | v => .error s!"{k}: not a number ({v.compress})"

private def getInt? (j : Json) (k : String) : Except String Int := do
  let v ← j.getObjVal? k |>.mapError (fun e => s!"{k}: {e}")
  match v with
  | .num n => numToInt? n
  | v => .error s!"{k}: not a number ({v.compress})"

private def getStr? (j : Json) (k : String) : Except String String := do
  let v ← j.getObjVal? k |>.mapError (fun e => s!"{k}: {e}")
  match v with
  | .str s => .ok s
  | v => .error s!"{k}: not a string ({v.compress})"

private def rankOf : String → Except String Rank
  | "normal" => .ok .normal
  | "silver" => .ok .silver
  | "gold"   => .ok .gold
  | s        => .error s!"unknown rank: {s}"

private def currOf : String → Except String Currency
  | "jpy" => .ok .jpy
  | "usd" => .ok .usd
  | "chf" => .ok .chf
  | s     => .error s!"unknown currency: {s}"

private def linesOf (j : Json) : Except String (List Line) := do
  let v ← j.getObjVal? "lines" |>.mapError (fun e => s!"lines: {e}")
  let arr ← match v with
    | .arr a => .ok a.toList
    | v => .error s!"lines: not an array ({v.compress})"
  arr.mapM fun pair => do
    let items ← match pair with
      | .arr a => .ok a.toList
      | v => .error s!"line: not an array ({v.compress})"
    match items with
    | [u, q] =>
      let unit ← match u with
        | .num n => numToInt? n
        | v => .error s!"unit: not a number ({v.compress})"
      let qty ← match q with
        | .num n => pure (← numToInt? n).toNat
        | v => .error s!"qty: not a number ({v.compress})"
      pure (⟨unit, qty⟩ : Line)
    | _ => .error "line: expected [unit, qty]"

private def asStr : Json → Except String String
  | .str s => .ok s
  | v => .error s!"not a string ({v.compress})"

/-- `expr` は `["one", 5, "usd"]` / `["add", e1, e2]` の入れ子。 -/
private partial def exprOf : Json → Except String Bill.Expr
  | .arr a => do
    let items := a.toList
    match items with
    | ["one", amt, cur] =>
      let n ← match amt with
        | .num n => numToInt? n
        | v => .error s!"amount: not a number ({v.compress})"
      let c ← currOf (← asStr cur)
      return Bill.Expr.one ⟨n, c⟩
    | ["add", x, y] => return Bill.Expr.add (← exprOf x) (← exprOf y)
    | _ => .error "expr: expected [\"one\", amount, currency] or [\"add\", e1, e2]"
  | v => .error s!"expr: not an array ({v.compress})"

private def handle (j : Json) : Except String Json := do
  let op ← getStr? j "op"
  match op with
  | "total" =>
    let r ← rankOf (← getStr? j "rank")
    let ls ← linesOf j
    let t := total r ls
    return Json.mkObj [("ok", .bool true), ("total", .num ⟨t, 0⟩),
                       ("taxed", .num ⟨withTax t, 0⟩)]
  | "reduce" =>
    let e ← exprOf (← j.getObjVal? "expr" |>.mapError (fun x => s!"expr: {x}"))
    let to ← currOf (← getStr? j "to")
    match reduce e to with
    | .ok m => return Json.mkObj [("ok", .bool true), ("amount", .num ⟨m.amount, 0⟩)]
    | .error e => return Json.mkObj [("ok", .bool false), ("error", .str e)]
  | other => .error s!"unknown op: {other}"

private def respond (line : String) : Json :=
  let s := line.trimAscii.toString
  match Json.parse s with
  | .error e => Json.mkObj [("ok", .bool false), ("error", .str s!"parse: {e}")]
  | .ok j =>
    match handle j with
    | .ok v => v
    | .error e => Json.mkObj [("ok", .bool false), ("error", .str e)]

private partial def loop (stdin stdout : IO.FS.Stream) : IO Unit := do
  let line ← stdin.getLine
  if line.isEmpty then return ()
  stdout.putStrLn (respond line).compress
  stdout.flush   -- これが無いと pytest 側が永久に待つ
  loop stdin stdout

def main : IO Unit := do
  loop (← IO.getStdin) (← IO.getStdout)
