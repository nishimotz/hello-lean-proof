# Python 経験者のための Lean 4 入門

このページは「Python は書けるが、Lean は触ったことがない」人のための読み物。
演習を始める前に 10 分で読む想定。

---

## 1. 一番大きい違い: 型は消えるか、消えないか

Python:

```python
def double(x: int) -> int:
    return x * 2
```

型ヒントは**実行時にはほぼ消える**（ただし dataclass や Pydantic のように実行時に読むライブラリもある）。`double("a")` は `"aa"` を返すかもしれない。
`typing` モジュールは主に道具（mypy など）への情報提供で、実行時チェックではない。

Lean:

```lean
def double (x : Nat) : Nat := x * 2
```

型は**コンパイル時（型検査時）に検査される**。`double "a"` はコンパイルエラー。
Lean では「型が合っている」ことが保証であり、その保証の上で証明を書く。

> **ここが全ての出発点**。Python の型は「お願い」、Lean の型は「契約」。

### 補足: `Nat` とは何か

上の例に出てきた `Nat` は **自然数（Natural number）** で、**`0` を含む 0 以上の整数（`0, 1, 2, ...`）** を表す型。負の数は入らない。

- **Python の `int` に近いのは `Int`**: Lean にも負の数を扱える `Int` 型がある。それでも Lean で `Nat` がよく使われるのは、回数・長さ・インデックスなど「負にならない値」を型で制限できると、証明や再帰の停止性を扱いやすいため。
- **引き算の注意点**: `Nat` には負の数が無いため、`3 - 5` を計算するとエラーでも `-2` でもなく **`0`** になる（0 未満に落ちない）。負の数を扱う計算では `Int` を使う。

---

## 2. 対応表

Python の直感で読める範囲の対応。**入り口としては便利だが、出口では嘘になる**（後述）。

| Lean | Python での近いもの | 注意 |
|---|---|---|
| `P : Prop` | 型ヒント `x : int` | 型ではなく**主張** |
| `example (P : Prop) : P := by ...` | `def f(x) -> T: ...` | 返り値が「証明」 |
| 証明項 | 関数の本体 | 型検査器が「その型の値を返しているか」を見る |
| `by` ブロック | 関数本体 | 制御フローが「ゴールの書き換え」 |
| `intro hp` | 引数を受け取る `def f(hp: P)` | 仮定を盤面に置く |
| `exact hp` | `return hp` | ゴールと型が完全一致するときだけ |
| `apply h` | `h(...)` を呼ぶ | h の前提が新しいゴールになる |
| `constructor` | `return (a, b)` | `P ∧ Q` を 2 つのゴールに割って埋める |
| `simp` / `omega` | 自動で `assert` ループ | 挙動が読めない。ブラックボックス |
| `sorry` | `pass` | **通るが中身が無い** |
| `#print axioms thm` | `grep pass` | `pass` が残っていないかの確認 |

### 補足: `def` と `theorem` / `example` の使い分け

Lean は定理証明器であると同時にプログラミング言語でもあるため、用途によってキーワードを書き分ける。

- `def`: 計算や値を返す**普通の関数**を定義するときに使う（上の `def double` は Python と同じ役割）
- `theorem`: 命題が成り立つことを**証明**するときに使う（名前付き。`#print axioms` で検証できる）
- `example`: 名前の無い**練習用・使い捨ての証明**を書くときに使う

---

## 3. 一番刺さる 2 つ

### `sorry` は `pass`

```lean
example (P : Prop) : P := by
  sorry
```

Python でいえば:

```python
def f(p):
    pass
```

**コンパイルは通る。警告が 1 行出るだけ。証明ではない。**

### `#print axioms` は「`pass` が残っていないか確認する grep」

```lean
theorem my_thm (P : Prop) : P := by sorry
#print axioms my_thm
-- 'my_thm' depends on axioms: [sorryAx]
```

`sorryAx` が出たら未証明。出なければ本物。
（`example` は名前が無いので `#print axioms` で覗けない。**名前付きで書く**こと）

Python の `pass` と違って、Lean は「`pass` を使ったことを記録に残す」。だから後から検出できる。

---

## 4. 出口では嘘になる点

`assert` との類推は**入り口では便利**だが、Lean の証明は `assert` ではない。3 つだけ明示する。

### (a) `by` ブロックは「手続き」ではない

Python の関数本体は「上から順に実行して `return` で抜ける」。
Lean の `by` ブロックは**ゴールを書き換えていく**。`return` に相当する概念が無い。

```lean
example (P Q R : Prop) (h1 : P → Q) (h2 : Q → R) (hp : P) : R := by
  apply h2   -- ゴールが R から Q に変わる
  apply h1   -- ゴールが Q から P に変わる
  exact hp   -- ゴールが消える
```

「命令を並べる」のではなく「**盤面を変えていく**」。ここが Python の関数と最も違う。

### (b) 実行時エラーという概念が無い

Python は「テストで見つける」。Lean は「型検査で通るか通らないか」。
だから Lean のコードに `try/except` は無い。エラーは**コンパイル時に全部出る**か、**出ない**か。

### (c) 証明は「実行」されない

Python の関数は呼ぶと仕事をする。Lean の証明は**型検査を通ったら終わり**で、実行時に何もしない。
だから「証明が速い/遅い」という話は基本無い（型検査の計算量は別）。

---

## 5. Python 経験者が持ち込みやすい誤解

| 誤解 | 実際 |
|---|---|
| 「証明は実行して確認する」 | 型検査が確認する。実行は無い |
| 「`sorry` は `pass` みたいに一時的に置くだけ」 | 置けるが**記録が残る**。`sorryAx` で検出される |
| 「tactic はライブラリ関数」 | tactic は**ゴールを変形する手**。戻り値が無い |
| 「`exact` と `apply` は同じ」 | `exact` は埋める。`apply` は変換する。**別物** |
| 「型ヒントを書けば Lean に近づく」 | 近づかない。Python の型は実行時に消える |

---

## 6. 次の一歩

`README.md` のクイックスタートで環境を作り、`Exercises/02_first_tactic` から始める。

最初の 3 分で分かること:
- `constructor` を打つと Infoview のゴールが 2 つに割れる
- `exact hp` で 1 つ消える
- `No goals` が出たら勝ち

**Python の `assert` を書く感覚で始めてよい。ただし「`assert` が通った」ではなく「型検査が通った」と言い直す癖をつける。**

---

## 参考

- Lean 4 公式: https://lean-lang.org/
- Functional Programming in Lean（Python 経験者に読みやすい）: https://lean-lang.org/functional_programming_in_lean/
- Theorem Proving in Lean 4: https://lean-lang.org/theorem_proving_in_lean4/
