# Windows（PowerShell）でのセットアップ

このページは Windows の **PowerShell** から始める人向け。
WSL の中なら macOS / Linux と同じ手順がそのまま使えるので、[README](../README.md) のクイックスタートを見てほしい。

> **注意**: このページの手順は **実機の Windows で `lake build` を通した検証をしていない**。
> elan の PowerShell インストーラの存在とオプション、配布アーキテクチャまでは一次情報で確認した。
> 詰まった箇所は Issue で知らせてほしい。

---

## 1. elan を入れる

PowerShell を開いて、2 行。

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/leanprover/elan/master/elan-init.ps1 -OutFile elan-init.ps1
./elan-init.ps1 -NoPrompt -DefaultToolchain leanprover/lean4:v4.36.0
```

- `-NoPrompt` は対話メニューを出さない指定
- `-DefaultToolchain` を省くと最新の stable が入る。**このリポジトリは `lean-toolchain` で 4.36.0 に固定している**ので、合わせておくと最初から噛み合う
- PATH は自動で通る（`-NoModifyPath` を付けない限り）。`%USERPROFILE%\.elan\bin` が追加される

### 実行ポリシーで止まったら

```
... cannot be loaded because running scripts is disabled on this system.
```

と出たら、その PowerShell セッションだけポリシーを緩める。

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

`-Scope Process` なので、そのウィンドウを閉じれば元に戻る。システム全体は変えない。

### 確認

```powershell
elan --version
lean --version
```

`Lean (version 4.36.0, ...)` が出れば成功。

---

## 2. リポジトリを取得してビルド

```powershell
git clone https://github.com/nishimotz/hello-lean-proof.git
cd hello-lean-proof
lake build
```

`Build completed successfully (22 jobs)` が出れば完成。

**`elan default` は打たなくてよい。** リポジトリ直下の `lean-toolchain` を見て、Lake が必要なツールチェーン（4.36.0）を自動で落としてくる。

---

## 3. VS Code

拡張 **Lean 4**（`leanprover.lean4`）を入れる。Windows でも同じ拡張。

`lakefile.toml` のあるフォルダ（`hello-lean-proof` 直下）を開くこと。親フォルダを開くと Infoview が出ない。

---

## 4. Windows で詰まりやすい点

| 症状 | 原因と対処 |
|---|---|
| スクリプトが実行できない | 実行ポリシー。`Set-ExecutionPolicy -Scope Process Bypass` |
| `lake` が見つからない | PATH 未反映。PowerShell を開き直す。それでも駄目なら `%USERPROFILE%\.elan\bin` を確認 |
| ビルドが途中で失敗する | パスが深いと失敗することがある。`C:\dev\hello-lean-proof` のような浅い場所に置く |
| ビルドが異常に遅い | **Windows ARM は x64 エミュレーション**。ネイティブの Windows ARM 版 elan は配布されていない |
| 文字化けする | PowerShell の既定エンコーディング。`chcp 65001` か、Windows Terminal + UTF-8 設定を使う |
| パス区切りが `/` でよいか不安 | Lean 側のコマンドは `/` でよい。Lake が吸収する。PowerShell のコマンドレットは `\` でも動く |

---

## 5. WSL という選択肢

Linux と同じ手順で動かしたいなら WSL が楽。

```bash
# WSL の中（Ubuntu など）
curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o /tmp/elan-init.sh
sh /tmp/elan-init.sh -y --default-toolchain none
export PATH="$HOME/.elan/bin:$PATH"
```

ただし WSL のファイルシステム越しに Windows 側の VS Code で開くと、Lean サーバの応答が遅くなることがある。**コードは WSL 側のホームに置き、VS Code は Remote-WSL で開く**のが安定する。

---

## 6. 未確認事項

- 実機 Windows（x64 / ARM）での `lake build` 成功は未検証
- `elan-init.ps1` の `-DefaultToolchain` に `leanprover/lean4:v4.36.0` を渡す書式は一次情報の `param` 定義から読んだもので、実機実行は未検証
- VS Code 拡張の Windows 固有の挙動は未確認

確認できた人からの報告を歓迎する。
