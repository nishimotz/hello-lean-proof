"""価格計算の本番実装（Lean 仕様と差分テストで突き合わせる対象）。

仕様: Exercises/08_executable_spec/Solution.lean の `Bill.total` / `Bill.withTax`
"""

from dataclasses import dataclass

DISCOUNT_PCT = {"normal": 0, "silver": 5, "gold": 10}


@dataclass(frozen=True)
class Line:
    unit: int
    qty: int


def total(rank: str, lines: list[Line]) -> int:
    """小計に割引を1回だけ適用する。切り捨てはその1回だけ。"""
    s = sum(l.unit * l.qty for l in lines)
    pct = DISCOUNT_PCT[rank]
    return s - s * pct // 100


def per_line_total(rank: str, lines: list[Line]) -> int:
    """間違った実装: 明細ごとに割引を適用してから足す。"""
    pct = DISCOUNT_PCT[rank]
    out = 0
    for l in lines:
        s = l.unit * l.qty
        out += s - s * pct // 100
    return out


def with_tax(t: int) -> int:
    return t + t * 10 // 100
