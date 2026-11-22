import json;
import from jsvalue { stringify }

test "parse_json accepts what JSON.parse accepts and fails with V8's messages" {
    with open("testdata/v8json_oracle.json") as f {
        rows: list[any] = json.loads(f.read());
        for row in rows {
            try {
                value = parse_json(row[0]);
                assert row[1] == "OK", f"{row[0]!r} should fail with {row[2]!r}, parsed {value!r}";
                assert stringify(value)
                    == row[2], f"{row[0]!r} parsed to {stringify(value)!r}, want {row[2]!r}";
            } except JsSyntaxError as e {
                assert row[1] == "ERR", f"{row[0]!r} should parse, raised {e}";
                assert str(e) == row[2], f"{row[0]!r} raised {str(e)!r}, want {row[2]!r}";
            }
        }
    }
}
