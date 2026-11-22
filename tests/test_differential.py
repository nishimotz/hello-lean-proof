"""Lean 実行可能仕様との差分テスト。

通れば「Python 実装が Lean 仕様と一致する」と言える（一致しない入力が
Hypothesis に見つからなかった、という確率的な主張）。
"""

from hypothesis import given, settings, strategies as st, HealthCheck

from billing import Line, total, with_tax

rank_st = st.sampled_from(["normal", "silver", "gold"])
line_st = st.builds(Line, unit=st.integers(min_value=0, max_value=10**7),
                    qty=st.integers(min_value=0, max_value=1000))
lines_st = st.lists(line_st, max_size=12)

SETTINGS = settings(max_examples=500, deadline=None,
                    suppress_health_check=[HealthCheck.too_slow])


@SETTINGS
@given(rank=rank_st, lines=lines_st)
def test_total_matches_lean(lean_oracle, rank, lines):
    py = total(rank, lines)
    py_tax = with_tax(py)
    ln, ln_tax = lean_oracle.total(rank, [(l.unit, l.qty) for l in lines])
    assert (py, py_tax) == (ln, ln_tax)


@SETTINGS
@given(rank=rank_st, line=line_st)
def test_single_line_matches_lean(lean_oracle, rank, line):
    assert total(rank, [line]) == lean_oracle.total(rank, [(line.unit, line.qty)])[0]


@SETTINGS
@given(pair=st.tuples(
    st.integers(min_value=0, max_value=10**4),
    st.integers(min_value=0, max_value=10**4),
))
def test_currency_addition_matches_lean(lean_oracle, pair):
    """Beck の Money 例: $a + b CHF を USD に換算する（2 CHF = 1 USD）。"""
    a, b = pair
    r = lean_oracle.reduce(["add", ["one", a, "usd"], ["one", b, "chf"]], "usd")
    assert r["ok"] is True
    assert r["amount"] == a + b // 2


def test_unregistered_rate_rejected(lean_oracle):
    r = lean_oracle.reduce(["one", 100, "jpy"], "usd")
    assert r["ok"] is False
    assert r["error"] == "no_rate"
