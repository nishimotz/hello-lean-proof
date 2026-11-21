# ルールを書け、ケースを書くな — 不変条件でバグを捕まえる

この教材の第 2 部。前編（[README](../README.md)）で「証明＝盤面を見て手を選ぶゲーム」を体験した。ここでは**そのゲームを業務のバグに当てる**。

題材はチケット販売の売り越し。AI がコードもテストも書くと、テストは通るのにバグが残る。その構造と、形式仕様でどう捕まえるかを扱う。

- 所要: 60〜90 分（演習 [07_state_invariant](../Exercises/07_state_invariant/) を含む）
- 前提: 前編の `constructor` / `intro` / `exact` / `omega` が読めること
- 対応する Quint 版: https://github.com/nishimotz/hello-quint

---

## 1. 問題: 自作自演の満点

AI にチケット販売サービスを書かせると、こういうコードが出る。

```python
class TicketService:
    def check(self, user):
        self.phase[user] = "Checked" if self.stock > 0 else "SoldOut"

    def purchase(self, user):
        # 在庫は check() で確認済みなので、ここでは減らすだけでOK  ← バグ
        self.stock -= 1
        self.sold += 1
        self.phase[user] = "Bought"
```

テストも頼むと3本書いてくる。在庫があれば買える、在庫がなければ売り切れ、2人が順に買うと0になる。**3本とも通る。バグは残っている。**

「確認と確定の間に他人が買う」場面を、実装した AI が想定していないので、テストにも出てこない。先生と生徒が同じ人物で、自作自演の満点になっている。これはソフトウェアテストの古典的な **テストオラクル問題**（何が正しい結果かをどう知るか）の一形態。

別のモデルに敵対レビューさせても足りない。同じ塾の同じ教科書を使った隣の席の生徒に出題させるようなもので、**ケースを1つずつ考える**というやり方が同じなら出題範囲の穴は埋まらない。

## 2. 発想の転換: ケースではなくルール

「この場面ではこうなる」を並べるのをやめ、**「どんな場面でも、これだけは守られる」**を書く。

> 売れたチケットの枚数は、最初の在庫数を超えない。

これが **不変条件**（invariant）。初期状態で成り立ち、どの操作をしても成り立ち続ける性質。

ケースを書く方式は「思いついた場面の数」が上限になる。ルールを書く方式は、**守るべき性質を1つ宣言すれば、あとは機械が反例を探す**。人間の仕事は「何が正しいか」を決めることで、「どんな入力で試すか」ではなくなる。

## 3. Quint で書くとどうなるか

[hello-quint](https://github.com/nishimotz/hello-quint) に同じ題材の Quint 版がある。ルールは1行。

```
val noOversell = sold <= INITIAL_STOCK
```

```
$ quint run ticket.qnt --invariant=noOversell

[State 3] { phase: Map("alice" -> Checked, "bob" -> Checked, "carol" -> Checked), sold: 0, stock: 2 }
[State 4] { phase: Map("alice" -> Bought,  "bob" -> Checked, "carol" -> Checked), sold: 1, stock: 1 }
[State 5] { phase: Map("alice" -> Bought,  "bob" -> Bought,  "carol" -> Checked), sold: 2, stock: 0 }
[State 6] { phase: Map("alice" -> Bought,  "bob" -> Bought,  "carol" -> Bought),  sold: 3, stock: -1 }

[violation] Found an issue (19ms at 1000 traces/second).
error: Invariant violated
```

テストケースは1つも書いていない。誰がどの順番で操作するかは `quint run` が決める。落ちたときは**破られたルールと、そこまで至る手順**が出る。

さらに `quint verify --backend=tlc` は、この**3人・在庫2というモデルの中で**到達可能な状態を全部調べる（29 状態、0 left on queue）。ランダムではなく網羅。

| | pytest | Quint |
|---|---|---|
| 人間が書くもの | ケース（入力と期待値） | ルール（不変条件） |
| ケースの生成 | 人間 | 機械 |
| 失敗したとき | テスト名と assert | 破ったルールと手順 |
| 通ったときの意味 | 書いた範囲で正しい | `verify` ならこのモデルの全状態で正しい |

**pytest が悪いのではない。ケースを書く方式である限り、書いた人の想像力が上限になる**という話。

## 4. 同じことを Lean でやると何が変わるか

ここからが本題。Quint で「ルールを書けば機械がやってくれる」なら、Lean では何が起きるか。

### 4-1. 状態を型にする

```lean
structure St where
  stock   : Int   -- 在庫
  sold    : Int   -- 売れた枚数
  checked : Nat   -- 確認済み・未購入の人数
```

**`stock` を `Int` にするのが要点。** `Nat` にすると負にならず、売り越しというバグそのものが型で表現できなくなる。「バグを型で防ぐ」のではなく「バグを型で書けるようにする」段階が要る。

### 4-2. 遷移を関係として書く

Quint の `action purchase` に対応するのは、Lean では `inductive` のコンストラクタ。

```lean
inductive StepFixed : St → St → Prop where
  | check : ∀ (a b : Int) (c : Nat), StepFixed ⟨a, b, c⟩ ⟨a, b, c + 1⟩
  | purchase : ∀ (a b : Int) (c : Nat), 1 ≤ c → 0 < a →
      StepFixed ⟨a, b, c⟩ ⟨a - 1, b + 1, c - 1⟩
  | soldOut : ∀ (a b : Int) (c : Nat), 1 ≤ c → a ≤ 0 →
      StepFixed ⟨a, b, c⟩ ⟨a, b, c - 1⟩
```

`0 < a` が「確定時に在庫を再確認する」に対応する。バグ版はこれが無い。

`∀ (a b : Int) (c : Nat)` と明示的に書くのは、`cases` で名前を拾うため。`s : St` を暗黙にすると `cases` で束縛できない（実測で確認した Lean 4.36.0 の挙動）。

### 4-3. 到達可能性も帰納型で書く

```lean
inductive ReachFixed : St → Prop where
  | init : ReachFixed init
  | step (s t : St) : ReachFixed s → StepFixed s t → ReachFixed t
```

標準ライブラリの `Relation.ReflTransGen` は Lean 4.36.0 には無い（`#check` で確認済み）。自前の帰納型で足りる。

### 4-4. ここが山場 — ルールをそのまま渡すと詰まる

`NoOversell` をそのまま帰納法に載せようとする。

```lean
def NoOversell (s : St) : Prop := s.sold ≤ 2
```

**通らない。** `sold ≤ 2` から1手で `sold ≤ 2` を出すには、在庫との関係が要る。`purchase` は `sold` を1増やし `stock` を1減らすので、`sold` 単独では何も言えない。

だから **不変条件を強化する**。

```lean
def Inv (s : St) : Prop := 0 ≤ s.stock ∧ s.sold + s.stock = 2
```

`sold + stock = 2` を連言で持つ。これで `purchase` の1手が保存される。最後に `Inv` から `NoOversell` を出す（`omega`）。

```lean
theorem fixed_no_oversell (s : St) (hr : ReachFixed s) : NoOversell s := by
  have h : Inv s := by
    induction hr with
    | init => exact inv_init
    | step s' t hr' hst ih => exact inv_step s' t ih hst
  obtain ⟨h1, h2⟩ := h
  simp only [NoOversell]
  omega
```

> **Quint はルールをそのまま渡せば機械が全状態を調べる。Lean はルールを帰納的な形に書き直す仕事が人間に残る。その代わり、人数も在庫数も固定せずに証明が通る。**

`fixed_no_oversell` の `a`/`b` は任意の `Int`、`c` は任意の `Nat`。3人・2枚に縛られていない。TLC の「29状態」はこの具体モデルに閉じているが、Lean の証明は閉じていない。

## 5. どちらを使うか

| 状況 | 向いている道具 |
|---|---|
| まず反例を1つ見たい / 仕様を書き始めたい | Quint。`quint run` が pytest の代わり |
| 設計を網羅的に確かめたい（小さいモデルで） | Quint。`quint verify` が状態を尽くす |
| 人数・在庫数に依存しない保証を書きたい | Lean。帰納法で一般化できる |
| 実装が仕様どおりか確かめたい | Quint の `--mbt`（Lean 単体では閉じない） |
| アルゴリズムの性質を定理として残したい | Lean |

**Python 利用者には Quint を入口に薦める。** `quint run` の UX が pytest と同型で、書くものが「ケース」から「ルール」に変わるだけ。Lean はその次で、「同じルールが人数に依存せず成り立つ」を見せるときに出す。

## 6. 演習

[Exercises/07_state_invariant](../Exercises/07_state_invariant/) に7問ある。`Exercise.lean` の `sorry` を埋めてから `Solution.lean` と比べる。

```bash
lake env lean Exercises/07_state_invariant/Solution.lean
```

| 問 | 内容 | 難所 |
|---|---|---|
| 7-1 | バグのある遷移を書く | 束縛子の書き方 |
| 7-2 | 反例を6手で構成する | `ReachBuggy.step` の入れ子 |
| 7-3 | 直した遷移を書く | `0 < a` の追加 |
| 7-4 | `Inv` を書いて4つの補題を示す | **強化を思いつくか** |
| 7-5 | `inv_step` | `obtain` してから `cases` |
| 7-6 | 主定理 | `induction hr` |
| 7-7 | 具体値で確認 | `simp [NoOversell]` |

7-4 で手が止まるのが正常。**そこがこの教材の山場**で、Quint では起きない作業が Lean では必須になる、という差そのもの。

## 7. 正直に書く弱点

- **モデルベーステストは Lean 単体では閉じない。** Quint の `--mbt` は「ありうる手順を1000本生成して実装に解かせる」ところまで面倒を見る。Lean で同じことをやるなら、抽出（`#eval` で値を出す）か、別言語の実装と突き合わせる層を自分で書く。
- **`Inv` の強化は自動化されていない。** Quint では `noOversell` をそのまま渡せば済む。Lean では「証明が通る形」を人間が探す。ここが詰まると先に進めない。
- **Lean の証明は仕様の正しさを保証しない。** 「この遷移系で `NoOversell` が成り立つ」ことしか言わない。遷移系が現実のシステムを正しくモデル化しているかは別問題。`stock : Int` にしたのも、`checked` を人数に抽象化したのも、人間の判断。

## 8. 出典

- Zenn「【TLA+】AIにテストケースを書かせるな。ルールを書け」（karamage, 2026-11）
  https://zenn.dev/karamage/articles/73027ee36796dc
- Quint 版の実装: https://github.com/nishimotz/hello-quint
- Quint 公式: https://quint.sh/
- Reliable Software in the LLM Era: https://quint.sh/posts/llm_era
- Model-based Testing: https://quint.sh/docs/model-based-testing
- Leslie Lamport, "Who Builds a House without Drawing Blueprints?"（TLA+ の動機）
- How Amazon Web Services Uses Formal Methods: https://dl.acm.org/doi/10.1145/2699417
