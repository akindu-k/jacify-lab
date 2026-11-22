import json;
import from jsvalue { stringify, is_undefined, json_parse }

def oracle(section: str) -> list[any] {
    with open("testdata/js_oracle.json") as f {
        data: dict[str, any] = json_parse(f.read());
        return data[section];
    }
}

test "setProperty builds the same structure as dot-prop" {
    for row in oracle("parsePath") {
        target: dict[str, any] = {};
        got = "";
        try {
            set_property(target, row[0] + ".x", 1);
            got = stringify(target);
        } except ValueError as e {
            got = "ERR:" + str(e);
        }
        assert got == row[1], f"setProperty({row[0]!r}) gave {got!r}, want {row[1]!r}";
    }
}

test "invalid paths raise dot-prop's messages" {
    for row in oracle("parsePathErr") {
        got = "ok";
        try {
            set_property({}, row[0], 1);
        } except ValueError as e {
            got = "ERR:" + str(e);
        }
        assert got == row[1], f"setProperty({row[0]!r}) gave {got!r}, want {row[1]!r}";
    }
}

test "getProperty reads through objects, arrays and strings as dot-prop does" {
    doc: dict[str, any] = {"a": {"b": [10, {"c": "x"}], "s": "hey"}, "n": None};
    for row in oracle("getProperty") {
        got = get_property(doc, row[0]);
        want: any = row[1];
        if isinstance(want, dict) and "u" in want {
            assert is_undefined(got), f"getProperty({row[0]!r}) gave {got!r}, want undefined";
        } else {
            assert got == want, f"getProperty({row[0]!r}) gave {got!r}, want {want!r}";
        }
    }
}
