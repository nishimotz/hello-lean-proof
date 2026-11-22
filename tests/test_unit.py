from billing import Line, total, with_tax, per_line_total


def test_gold_12000():
    assert total("gold", [Line(4000, 3)]) == 10800


def test_tax():
    assert with_tax(10800) == 11880


def test_normal_no_discount():
    assert total("normal", [Line(999, 1), Line(1, 1)]) == 1000


def test_per_line_differs_from_total():
    """切り捨ての位置が違うので、gold では一致しない（仕様の反例）。"""
    lines = [Line(999, 1), Line(1, 1)]
    assert per_line_total("gold", lines) == 901
    assert total("gold", lines) == 900
