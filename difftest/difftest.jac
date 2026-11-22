import json;
import re;
import sys;
import http.client;
import from http.client { HTTPResponse }

glob IGNORED: set[str] = {"date", "connection", "keep-alive", "x-powered-by", "transfer-encoding", "content-length"};

glob RANDOM_ID: re.Pattern = re.compile(r'("id"\s*:\s*)"[A-Za-z0-9_-]{11}"');

obj Reply {
    has status: int,
        headers: list[tuple[str, str]],
        body: str;
}

obj Side {
    has port: int,
        created: list[str] = [];

    def send(method: str, path: str, headers: dict[str, str], body: bytes | None) -> Reply;

    def fill(text: str) -> str;

    def mask(text: str) -> str;
}

def header_view(r: Reply) -> list[tuple[str, str]];

def compare(index: int, spec: dict[str, any], a: Reply, b: Reply, sa: Side, sb: Side) -> list[str];

def run(scenario_path: str, port_a: int, port_b: int) -> int;

with entry:__main__ {
    sys.exit(run(sys.argv[1], int(sys.argv[2]), int(sys.argv[3])));
}
