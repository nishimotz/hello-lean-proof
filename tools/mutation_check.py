"""Mutation Test: 実装をわざと壊し、Lean Oracle との差分テストが検出するか測る。

    uv run python tools/mutation_check.py

各変異について実装を書き換え、pytest を走らせ、
「落ちた＝検出できた」を数える。検出できない変異はテストの穴。

実装ファイルは直接書き換えない。作業コピー `billing/_mutant.py` を作り、
`PYTHONPATH` を差し替えてそちらを import させる。Ctrl-C や並走でも
手元の `service.py` は壊れない。
"""

import subprocess
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGET = ROOT / "billing" / "service.py"
MUTANT = ROOT / "billing" / "_mutant_service.py"

MUTATIONS = [
    ("合計割引 → 明細割引", "return s - s * pct // 100",
     "return sum(_l.unit * _l.qty - (_l.unit * _l.qty) * pct // 100 for _l in lines)"),
    ("切り捨て → 四捨五入", "return s - s * pct // 100", "return s - round(s * pct / 100)"),
    ("税率 10 → 8", "return t + t * 10 // 100", "return t + t * 8 // 100"),
    ("税の切り捨て位置", "return t + t * 10 // 100", "return round(t * 1.1)"),
]


CONFTEST = ROOT / "tests" / "_mutant_conftest.py"


def _write_mutant(source: str) -> None:
    """変異版の service を `billing` パッケージ内に置き、差し替え用 conftest を作る。"""
    MUTANT.write_text(source)
    # tests より先に import される場所で billing.service を差し替える
    CONFTEST.write_text(
        "import billing, billing._mutant_service as m\n"
        "billing.service = m\n"
        "billing.total = m.total\n"
        "billing.with_tax = m.with_tax\n"
        "billing.per_line_total = m.per_line_total\n"
    )


def _cleanup() -> None:
    for p in (MUTANT, CONFTEST):
        if p.exists():
            p.unlink()


def run() -> int:
    original = TARGET.read_text()
    undetected = []
    try:
        for name, old, new in MUTATIONS:
            if old not in original:
                print(f"skip: {name}（置換対象が見つからない）")
                continue
            _write_mutant(original.replace(old, new, 1))
            proc = subprocess.run(
                ["uv", "run", "pytest", "tests/test_differential.py", "-q",
                 "-p", "_mutant_conftest"],
                cwd=ROOT, capture_output=True, text=True,
                env={**__import__("os").environ, "PYTHONPATH": str(ROOT / "tests")},
            )
            detected = proc.returncode != 0
            print(f"{'検出' if detected else '見逃し'}: {name}")
            if not detected:
                undetected.append(name)
    finally:
        _cleanup()
    print(f"\n{len(MUTATIONS) - len(undetected)}/{len(MUTATIONS)} 検出")
    return 0 if not undetected else 1


if __name__ == "__main__":
    sys.exit(run())
