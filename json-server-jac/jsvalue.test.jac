import json;
import math;

def oracle(section: str) -> list[any] {
    with open("testdata/js_oracle.json") as f {
        data: dict[str, any] = json_parse(f.read());
        return data[section];
    }
}

def number_or_text(v: any) -> any {
    if v == "NaN" {
        return math.nan;
    }
    if v == "Infinity" {
        return math.inf;
    }
    if v == "-Infinity" {
        return -math.inf;
    }
    return v;
}

def same_number(a: float, b: any) -> bool {
    want = number_or_text(b);
    if isinstance(want, float) and math.isnan(want) {
        return math.isnan(a);
    }
    return a == float(want);
}

test "String() of every value kind matches JavaScript" {
    for row in oracle("toString") {
        assert js_to_string(row[0])
            == row[1], f"String({row[0]!r}) gave {js_to_string(row[0])!r}, want {row[1]!r}";
    }
}

test "Number() of every value kind matches JavaScript" {
    for row in oracle("toNumber") {
        got = js_to_number(row[0]);
        assert same_number(got, row[1]), f"Number({row[0]!r}) gave {got}, want {row[1]}";
    }
}

test "===, <, <=, >, >= across mixed types match JavaScript" {
    for row in oracle("compare") {
        (a, b) = (row[0], row[1]);
        assert js_strict_equals(a, b) == row[2], f"{a!r} === {b!r}";
        assert js_lt(a, b) == row[3], f"{a!r} < {b!r}";
        assert js_lte(a, b) == row[4], f"{a!r} <= {b!r}";
        assert js_gt(a, b) == row[5], f"{a!r} > {b!r}";
        assert js_gte(a, b) == row[6], f"{a!r} >= {b!r}";
    }
}

test "parseInt(s, 10) matches JavaScript" {
    for row in oracle("parseInt") {
        got = js_parse_int(row[0]);
        assert same_number(got, row[1]), f"parseInt({row[0]!r}) gave {got}, want {row[1]}";
    }
}

test "Number#toString matches JavaScript" {
    for row in oracle("numberText") {
        assert js_number_text(row[0])
            == row[1], f"String({row[0]!r}) gave {js_number_text(row[0])!r}, want {row[1]!r}";
    }
}

test "JSON.stringify with key order and indentation matches JavaScript" {
    for row in oracle("stringify") {
        got = stringify(row[0], row[1]);
        assert got == row[2], f"stringify gave {got!r}, want {row[2]!r}";
    }
}

test "localeCompare sign matches ICU root collation" {
    for row in oracle("locale") {
        got = locale_compare(row[0], row[1]);
        assert got == row[2], f"{row[0]!r}.localeCompare({row[1]!r}) gave {got}, want {row[2]}";
    }
}
