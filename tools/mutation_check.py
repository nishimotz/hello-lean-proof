"""Mutation Test: 実装をわざと壊し、Lean Oracle との差分テストが検出するか測る。

    uv run python tools/mutation_check.py

各変異について billing/service.py を書き換え、pytest を走らせ、
「落ちた＝検出できた」を数える。検出できない変異はテストの穴。
"""

import subprocess
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGET = ROOT / "billing" / "service.py"

MUTATIONS = [
    ("合計割引 → 明細割引", "return s - s * pct // 100",
     "return sum(_l.unit * _l.qty - (_l.unit * _l.qty) * pct // 100 for _l in lines)"),
    ("切り捨て → 四捨五入", "return s - s * pct // 100", "return s - round(s * pct / 100)"),
    ("税率 10 → 8", "return t + t * 10 // 100", "return t + t * 8 // 100"),
    ("税の切り捨て位置", "return t + t * 10 // 100", "return round(t * 1.1)"),
]


def run() -> int:
    original = TARGET.read_text()
    undetected = []
    try:
        for name, old, new in MUTATIONS:
            if old not in original:
                print(f"skip: {name}（置換対象が見つからない）")
                continue
            TARGET.write_text(original.replace(old, new, 1))
            proc = subprocess.run(
                ["uv", "run", "pytest", "tests/test_differential.py", "-q"],
                cwd=ROOT, capture_output=True, text=True,
            )
            detected = proc.returncode != 0
            print(f"{'検出' if detected else '見逃し'}: {name}")
            if not detected:
                undetected.append(name)
    finally:
        TARGET.write_text(original)
    print(f"\n{len(MUTATIONS) - len(undetected)}/{len(MUTATIONS)} 検出")
    return 0 if not undetected else 1


if __name__ == "__main__":
    sys.exit(run())
