impl percent_decode(text: str) -> str {
    if "%" not in text {
        return text;
    }
    raw = text.encode("utf-8");
    out = bytearray();
    i = 0;
    n = len(raw);
    hexdigits = b"0123456789abcdefABCDEF";
    while i < n {
        b = raw[i];
        if b == 37 and i + 2 < n and raw[i + 1] in hexdigits and raw[i + 2] in hexdigits {
            out.append(int(raw[i + 1:i + 3].decode("ascii"), 16));
            i += 3;
        } else {
            out.append(b);
            i += 1;
        }
    }
    return bytes(out).decode("utf-8", "replace");
}

impl search_params(query: str) -> list[tuple[str, str]] {
    pairs: list[tuple[str, str]] = [];
    for piece in query.split("&") {
        if piece == "" {
            continue;
        }
        eq = piece.find("=");
        name = piece if eq < 0 else piece[:eq];
        value = "" if eq < 0 else piece[eq + 1:];
        pairs.append((
            percent_decode(name.replace("+", " ")),
            percent_decode(value.replace("+", " ")),
        ));
    }
    return pairs;
}

impl query_object(query: str) -> dict[str, any] {
    out: dict[str, any] = {};
    count = 0;
    for (name, value) in search_params(query) {
        if count >= 1000 {
            break;
        }
        count += 1;
        if name not in out {
            out[name] = value;
        } elif isinstance(out[name], list) {
            out[name].append(value);
        } else {
            out[name] = [out[name], value];
        }
    }
    return out;
}

impl is_where_operator(word: str) -> bool {
    return word in WHERE_OPERATORS;
}

impl split_key(key: str) -> KeyOp {
    colon = key.rfind(":");
    if colon != -1 {
        path = key[:colon];
        op = key[colon + 1:];
        if op == "" {
            return KeyOp(path=key, op="eq");
        }
        return KeyOp(path=path, op=op if is_where_operator(op) else None);
    }
    m = LEGACY_OPERATOR.match(key);
    if m is not None {
        path = m.group(1);
        op = m.group(2);
        if path != "" and is_where_operator(op) {
            return KeyOp(path=path, op=op);
        }
    }
    return KeyOp(path=key, op="eq");
}

impl coerce_value(value: str) -> any {
    if value == "true" {
        return True;
    }
    if value == "false" {
        return False;
    }
    if value == "null" {
        return None;
    }
    if js_trim(value) == "" {
        return value;
    }
    num = js_to_number(value);
    if num != num or num == float("inf") or num == float("-inf") {
        return value;
    }
    if abs(num) < 9007199254740992.0 and num == int(num) {
        return int(num);
    }
    return num;
}

impl parse_where_pairs(pairs: list[tuple[str, str]]) -> dict[str, any] {
    out: dict[str, any] = {};
    for (raw_key, raw_value) in pairs {
        k = split_key(raw_key);
        if k.op is None {
            continue;
        }
        full = k.path + "." + k.op;
        if k.op == "in" {
            set_property(out, full, [coerce_value(js_trim(part)) for part in raw_value.split(",")]);
        } else {
            set_property(out, full, coerce_value(raw_value));
        }
    }
    return out;
}

impl parse_where(query: str) -> dict[str, any] {
    return parse_where_pairs(search_params(query));
}
