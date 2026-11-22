# 仕様を実行する — Lean を Test Oracle にする

第 3 部。前編（[README](../README.md)）で「証明＝盤面を見て手を選ぶゲーム」を、第 2 部（[formal-rules](formal-rules.md)）で「ルールを書け、ケースを書くな」を扱った。ここでは仕様を **実行できる関数** にして、本番コードの正解判定器（Test Oracle）にする。

- 所要: 90〜120 分（演習 [08_executable_spec](../Exercises/08_executable_spec/) を含む）
- 前提: 前編の `constructor` / `intro` / `exact`、第 2 部の不変条件が読めること
- 追加で必要: Python 3.12 と [uv](https://docs.astral.sh/uv/)

## 1. テストの「緑」は誰が決めるか

テスト駆動開発の約束は単純だ。例を 1 つ書き、赤を見て、緑にする。Kent Beck の *Test-Driven Development: By Example*（2002）は、この繰り返しだけで設計が進むことを Money の例で示した。

- `$5 × 2 = $10`
- `$5 + $5 = $10`
- `$5 + 10 CHF = $10`（2 CHF = 1 USD）

ここで **緑の意味** を疑う。緑は「自分が書いた期待値と一致した」だけを意味する。期待値も実装も同じ人が書いたなら、両方が同じ誤解を共有していても緑になる。第 2 部で見た自作自演の満点と同じ構造。

Beck 自身もこの限界を知っていて、後の *Test Desiderata*（2019、[testdesiderata.com](https://testdesiderata.com/)）でテストの性質を 12 項目に分けた。`Predictive`（通れば本番に出せる）、`Structure-insensitive`（実装を変えても結果が変わらない）は、まさに「誰が正解を決めたか」に依存する性質だ。

## 2. 正解を外に出す

そこで期待値を自分で書くのをやめ、**Lean で書いた仕様に決めさせる**。仕様は実行可能な関数にして、JSON Lines で会話できる単体バイナリにする。

```
Python 実装 ──┐
              ├─ 同じ入力 → 出力を比較
Lean 仕様 ────┘   （差分テスト）
```

この構成の利点は、仕様と実装が別の言語・別の人間（あるいは別の AI）で書けること。同じ間違いを共有しにくい。

## 3. 最初の落とし穴: 全域関数 vs 例外

Beck の Money 例を Lean に移すと、本には書かれていない問題が出る。

```lean
def rate : Currency → Currency → Option Int
```

未登録の為替レートをどう表すか。ここで `some 0` を返すと何が起きるか。

```lean
#eval (5 : Int) / 0   -- 0
```

**Lean の `Int` 除算はゼロ除算で 0 を返す。** 例外を投げない。だから未登録レートが静かに 0 円になる。Python なら `ZeroDivisionError` で落ちる。

つまり差分テストで最初に検出されるのは「バグ」ではなく、**仕様側の全域性の設計漏れ**。`Option Int` のまま割り算すると Oracle が嘘をつく。`Except` で理由付きの失敗を返す形にしないと、テストは通ってしまう。

もう 1 つ、除算の向きも確認しておく。Lean の `Int` 除算は **floor**（負の数では小さい方向へ丸める）で、Python の `//` と同じ。

```lean
#eval (-7 : Int) / 2   -- -4（Python の -7 // 2 も -4）
```

ここが一致しているから、この章の差分テストは成立している。C や Java の `/` は 0 方向への切り捨てなので、同じ仕様を移植すると負数の明細で 1 円ずれる。言語を替えると「一致していた前提」が消える、という良い例になっている。

これは Beck の本が扱っていない論点だ（Java の `int` 除算も同じ穴を持つが、Money の例では触れない）。借りた枠組みを別の言語で実装すると、借りた先が見落としていた問題が現れる。教材としてはここが一番おいしい。

## 4. 2 つ目の落とし穴: 切り捨ての位置

価格計算には割引と税が入る。ここで「明細ごとに割引してから足す」か「合計してから 1 回割引く」かで結果が変わる。

```
gold（10%）、999 円 × 1 と 1 円 × 1
  明細ごと: 899 + 0 = 899 → 税込 989
  合計して1回: 1000 - 100 = 900 → 税込 990
```

どちらも「10% 引き」の実装として読みやすい。仕様を書いていないと、この 1 円は誰にも気づかれない。

ただし差が出るのは **割引があって、かつ切り捨てが起きる入力** に限る。`1000 円 × 1` のような割り切れる明細では一致するし、返金（負の単価）だけの明細でも一致する。演習の反例は非負の明細で作ってある。「常にずれる」と一般化しないこと。Lean 側で `total` と `totalPerLine` の両方を定義し、`≠` を定理にすれば、差が **割引がある時だけ** 出ることが機械で確定する。

## 5. 差分テストを Desiderata で採点する

Beck の 12 項目で、ふつうのユニットテストと Lean Oracle 差分テストを比べる。

| 性質 | ユニットテスト | Lean Oracle 差分 |
|---|---|---|
| Isolated | ○ | ○ |
| Deterministic | ○ | ○（Oracle は純粋関数） |
| Fast | ◎ | △（プロセス間通信。常駐化で緩和） |
| Writable | ◎ | △（仕様を Lean で書くコスト） |
| Readable | ◎ | △（失敗がどちら側か曖昧） |
| Behavioral | ◎ | ◎ |
| Structure-insensitive | △（実装に密着しがち） | ◎（JSON 契約だけ見る） |
| Specific | ◎ | △（差分の原因追跡が要る） |
| Predictive | △（自作自演になり得る） | ◎（仕様が独立） |

**上がるのは Predictive と Structure-insensitive。下がるのは Fast / Writable / Specific。** この交換が割に合うのは、バグのコストが高い純粋ロジック（金額計算・認可・状態遷移）だけ。UI や I/O のグルーコードに入れると、コストだけ払うことになる。

## 6. 限界: 対応は証明されない

Lean 仕様と Python 実装が対応していることは、どこにも証明されていない。差分テストは「一致しない入力が見つからなかった」と言えるだけ。4 層で補う。

1. **JSON 契約の固定**: 入出力の形をスキーマで決める。エラーコードも 1 対 1 に対応させる
2. **差分テスト**: Hypothesis で入力を振る（500 例では足りない領域は増やす）
3. **カバレッジ**: Python 側の全分岐に到達しているか確認する（`uv run pytest --cov=billing --cov-branch`。この教材では 100%）
4. **Mutation Test**: 実装をわざと壊し、Oracle が検出できるか測る。検出できない変異は「テストの穴」

4 番目が効く。`total` を `totalPerLine` に差し替えて差分テストが落ちることを、この章の演習に入れてある。

## 7. 動かす

```bash
# Lean 側
lake build billing_oracle
printf '{"op":"total","rank":"gold","lines":[[4000,3]]}\n' | ./.lake/build/bin/billing_oracle
# {"ok":true,"taxed":11880,"total":10800}

# Python 側（差分テスト）
uv sync
uv run pytest -v
uv run pytest --cov=billing --cov-branch    # 100%
```

`tests/test_differential.py` が Lean Oracle をセッション fixture で 1 回だけ起動し、Hypothesis の入力を流し込む。`tests/test_unit.py` は同じ題材の普通のユニットテストで、こちらは `per_line_total` との差を固定値で押さえている。

実装をわざと壊して Oracle が検出するか測る:

```bash
uv run python tools/mutation_check.py
# 検出: 合計割引 → 明細割引
# 検出: 切り捨て → 四捨五入
# 検出: 税率 10 → 8
# 検出: 税の切り捨て位置
# 4/4 検出
```

## 出典

- Kent Beck, *Test-Driven Development: By Example* (Addison-Wesley, 2002) — Money 例と Red-Green-Refactor
- Kent Beck, *Test Desiderata* (2019) — https://testdesiderata.com/
- 「実行可能仕様を Oracle にして差分テストする」という構成は、kazunori279 氏の Lean 4 + Python Differential Testing 資料（https://kazunori279.github.io/lean4-tictactoe-test/slides_ja.html）を参考にした。題材（Money 例と価格計算）・Lean 仕様・Python 実装・検証は本教材側で独自に用意し、`lake build` と `uv run pytest` で動作を確認している。

なお「Specification by Example」は Beck ではなく Gojko Adzic の著作。混同しないよう注意。
