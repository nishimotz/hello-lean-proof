"""常駐 JSON Lines Oracle を pytest のセッション fixture として起動する。"""

import json
import subprocess
import pathlib
import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
ORACLE = ROOT / ".lake" / "build" / "bin" / "billing_oracle"


class LeanOracle:
    def __init__(self, path: pathlib.Path) -> None:
        self.proc = subprocess.Popen(
            [str(path)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )

    def call(self, req: dict) -> dict:
        assert self.proc.stdin and self.proc.stdout
        self.proc.stdin.write(json.dumps(req) + "\n")
        self.proc.stdin.flush()
        line = self.proc.stdout.readline()
        if not line:
            err = self.proc.stderr.read() if self.proc.stderr else ""
            raise RuntimeError(f"oracle died: {err}")
        return json.loads(line)

    def total(self, rank: str, lines: list[tuple[int, int]]) -> tuple[int, int]:
        r = self.call({"op": "total", "rank": rank, "lines": [list(l) for l in lines]})
        assert r["ok"], r
        return r["total"], r["taxed"]

    def reduce(self, expr, to: str) -> dict:
        return self.call({"op": "reduce", "expr": expr, "to": to})

    def close(self) -> None:
        if self.proc.stdin:
            self.proc.stdin.close()
        self.proc.wait(timeout=10)


@pytest.fixture(scope="session")
def lean_oracle():
    if not ORACLE.exists():
        pytest.fail(
            "Lean Oracle のバイナリが無い。先に `lake build billing_oracle` を実行する\n"
            f"（探した場所: {ORACLE}）"
        )
    oracle = LeanOracle(ORACLE)
    try:
        yield oracle
    finally:
        oracle.close()
