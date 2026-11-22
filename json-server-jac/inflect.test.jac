import json;

test "singularize and pluralize match the inflection package" {
    with open("testdata/inflect_oracle.json") as f {
        rows: list[any] = json.loads(f.read());
        for row in rows {
            assert singularize(row[0])
                == row[1], f"singularize({row[0]!r}) gave {singularize(row[0])!r}, want {row[1]!r}";
            assert pluralize(row[0])
                == row[2], f"pluralize({row[0]!r}) gave {pluralize(row[0])!r}, want {row[2]!r}";
        }
    }
}
