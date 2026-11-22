import json;
import math;
import from jsvalue { json_parse }

def finite_view(v: any) -> any {
    if isinstance(v, float) and math.isinf(v) {
        return "Infinity" if v > 0.0 else "-Infinity";
    }
    if isinstance(v, list) {
        return [finite_view(x) for x in v];
    }
    if isinstance(v, dict) {
        return {k: finite_view(x) for (k, x) in v.items()};
    }
    return v;
}

def oracle -> dict[str, any] {
    with open("testdata/json5_oracle.json") as f {
        return json_parse(f.read());
    }
}

test "json5_parse reads what the json5 package reads, and refuses with its messages" {
    for row in oracle()["parsed"] {
        got = "";
        try {
            value = json5_parse(row[0]);
            assert row[1] == "OK", f"{row[0]!r} should fail with {row[2]!r}";
            assert finite_view(value) == json_parse(row[2]), f"{row[0]!r} parsed to {value!r}";
        } except Json5Error as e {
            got = str(e);
            assert row[1] == "ERR", f"{row[0]!r} should parse, raised {got!r}";
            assert got == row[2], f"{row[0]!r} raised {got!r}, want {row[2]!r}";
        }
    }
}

test "json5_stringify writes what the json5 package writes" {
    for row in oracle()["strs"] {
        got = json5_stringify(row[0]);
        assert got == row[1], f"json5_stringify gave {got!r}, want {row[1]!r}";
    }
}
