# FizzBuzz で見る「テスト」と「証明ゲーム」

このページは、`hello-lean-proof` の演習を始める前後に読む補助読み物。
なじみのある **FizzBuzz** を題材に、「普通のテスト」と「Lean 4 の証明（探索ゲーム）」がどう違うかを体感する。

---

## 1. まず FizzBuzz 関数を書く（`def`）

Lean 4 はプログラミング言語でもあるので、普通の関数は `def` で書く。

```lean
def fizzbuzz (n : Nat) : String :=
  if n % 15 == 0 then "FizzBuzz"
  else if n % 3 == 0 then "Fizz"
  else if n % 5 == 0 then "Buzz"
  else toString n
```

Python のテストなら `assert fizzbuzz(15) == "FizzBuzz"` のように具体的な数字をいくつか試す。
しかしテストでは「たまたま試した数」で正しいことしか分からない。

---

## 2. すべての自然数で勝てる盤面を作る（`theorem`）

Lean では、特定の 1 個ではなく **「15 で割り切れるどんな自然数 `n` でも、必ず `"FizzBuzz"` になる」** という盤面をセットする。

```lean
theorem fizzbuzz_15
    (n : Nat) (h : n % 15 = 0) :
    fizzbuzz n = "FizzBuzz" := by
  simp [fizzbuzz, h]
```

このときの盤面（Infoview）の変化はこうなる：

1. **初期盤面**:
   - 持ち駒（仮定）: `n : Nat`（任意の自然数）、`h : n % 15 = 0`
   - ゴール: `⊢ fizzbuzz n = "FizzBuzz"`
2. **1 手打つ（`simp [fizzbuzz, h]`）**:
   - `fizzbuzz` の定義を展開し、`h` で `n % 15` を `0` に置き換える。続いて `0 % 15 == 0` が計算で確定し、`if` の分岐が畳まれる
     （`h` を `if` に直接当てるのではなく、**書き換え → 計算**の順に進む）
   - ゴールが消えて **`No goals`（勝利）** になる

> **インデントの補足**: `theorem` や `def` のヘッダが長いときは途中で改行してよい。折り返した行は必ずインデントする（0 列目に戻すと別の定義とみなされてエラーになる）。`by` ブロック内の tactic は同じ列（2 スペース）に揃え、ヘッダの折り返しは区別しやすいよう 4 スペースにするのが定番。

---

## 3. 持ち駒が足りないときは `omega` で作る

では「5 の倍数かつ 15 の倍数でないときは `"Buzz"` になる」はどうだろうか。

```lean
theorem fizzbuzz_5
    (n : Nat) (h5 : n % 5 = 0) (h15 : n % 15 ≠ 0) :
    fizzbuzz n = "Buzz" := by
  have h3 : n % 3 ≠ 0 := by omega
  simp [fizzbuzz, h3, h5, h15]
```

`fizzbuzz` は 2 番目の分岐で `n % 3 == 0` をチェックする。
初期盤面には `h5` と `h15` しか無いので、まず `omega`（線形算術の自動探索）で **`h3 : n % 3 ≠ 0` という新しい持ち駒** を作る。
そのうえで `simp [fizzbuzz, h3, h5, h15]` を打つと、`No goals` に到達する。

> **ここで効く条件**: `omega` は剰余を一般には解かない。
> ここで通るのは、`n % 5 = 0` と `n % 15 ≠ 0` の 2 本が「`n / 5`」「`n / 15` の線形不等式」として揃っているから。
> 逆に「`n % 15 = 0` なら `n % 3 = 0`」を `omega` 単独で出すのは通らない（除算の非線形性）。
> 「omega は剰余ならなんでも解く」と覚えないこと。

もし `n % 15 = 0` から `n % 3 = 0` を出したい場合は、剰余の入れ子に書き換えると通る（4.36.0 で実測）。

```lean
theorem m3_of_m15
    (n : Nat) (h : n % 15 = 0) :
    n % 3 = 0 := by
  have h' : n % 3 = n % 15 % 3 := by omega
  omega
```

「いま足りない持ち駒を 1 つ作って、次の手でゴールを閉じる」という感覚が、まさに探索ゲームそのもの。

---

## 4. バグを書くと「絶対に勝てないゲーム」になる

もし、よくあるバグとして `n % 3 == 0` を先に判定してしまったとする。

```lean
-- バグ版：3 の倍数を先に判定している
def buggy_fizzbuzz (n : Nat) : String :=
  if n % 3 == 0 then "Fizz"
  else if n % 15 == 0 then "FizzBuzz"
  else if n % 5 == 0 then "Buzz"
  else toString n

theorem buggy_15
    (n : Nat) (h : n % 15 = 0) :
    buggy_fizzbuzz n = "FizzBuzz" := by
  have h3 : n % 3 = 0 := by omega
  simp [buggy_fizzbuzz, h3]
```

これを Lean（4.36.0）で実行すると、以下のエラーが出てクリアできない。

```text
error: unsolved goals
n : Nat
h : n % 15 = 0
h3 : n % 3 = 0
⊢ False
```

`simp` が `"Fizz" = "FizzBuzz"` を比較して **`⊢ False`（絶対に勝てない盤面）** に変わってしまうため、どんな手を打っても `No goals` にできない。

- **テスト**: たまたま `15` をテストケースに入れ忘れると通ってしまう
- **証明ゲーム**: バグがあるとルール上そもそもクリアできない

「バグのないコードを書いたときだけ `No goals` で勝てる」。これが本リポジトリで証明を探索ゲームとして学ぶ一番の理由であり、AI 時代の検証の考え方にも繋がる。
