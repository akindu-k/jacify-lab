impl is_undefined(v: any) -> bool {
    return isinstance(v, JsUndefined);
}

impl is_number(v: any) -> bool {
    return (isinstance(v, int) or isinstance(v, float)) and not isinstance(v, bool);
}

impl is_object(v: any) -> bool {
    return isinstance(v, dict);
}

impl is_array(v: any) -> bool {
    return isinstance(v, list);
}

impl js_number_text(n: any) -> str {
    if isinstance(n, int) {
        if abs(n) < 9007199254740992 {
            return str(n);
        }
        return js_number_text(float(n));
    }
    x: float = n;
    if math.isnan(x) {
        return "NaN";
    }
    if math.isinf(x) {
        return "Infinity" if x > 0.0 else "-Infinity";
    }
    if x == 0.0 {
        return "0";
    }
    sign = "-" if x < 0.0 else "";
    text = repr(abs(x));
    mantissa = text;
    exponent = 0;
    if "e" in text {
        parts = text.split("e");
        mantissa = parts[0];
        exponent = int(parts[1]);
    }
    digits = mantissa;
    point = len(mantissa) + exponent;
    if "." in mantissa {
        halves = mantissa.split(".");
        digits = halves[0] + halves[1];
        point = len(halves[0]) + exponent;
    }
    while len(digits) > 1 and digits.startswith("0") {
        digits = digits[1:];
        point -= 1;
    }
    digits = digits.rstrip("0");
    if digits == "" {
        return "0";
    }
    k = len(digits);
    if k <= point and point <= 21 {
        return sign + digits + "0" * (point - k);
    }
    if 0 < point and point <= 21 {
        return sign + digits[:point] + "." + digits[point:];
    }
    if -6 < point and point <= 0 {
        return sign + "0." + "0" * (-point) + digits;
    }
    e = point - 1;
    esign = "+" if e >= 0 else "-";
    if k == 1 {
        return sign + digits + "e" + esign + str(abs(e));
    }
    return sign + digits[0] + "." + digits[1:] + "e" + esign + str(abs(e));
}

impl js_to_string(v: any) -> str {
    if is_undefined(v) {
        return "undefined";
    }
    if v is None {
        return "null";
    }
    if isinstance(v, bool) {
        return "true" if v else "false";
    }
    if is_number(v) {
        return js_number_text(v);
    }
    if isinstance(v, str) {
        return v;
    }
    if isinstance(v, list) {
        parts: list[str] = [];
        for x in v {
            parts.append("" if x is None or is_undefined(x) else js_to_string(x));
        }
        return ",".join(parts);
    }
    return "[object Object]";
}

impl js_to_number(v: any) -> float {
    if is_undefined(v) {
        return math.nan;
    }
    if v is None {
        return 0.0;
    }
    if isinstance(v, bool) {
        return 1.0 if v else 0.0;
    }
    if is_number(v) {
        return float(v);
    }
    if isinstance(v, str) {
        t = js_trim(v);
        if t == "" {
            return 0.0;
        }
        if RADIX_LITERAL.match(t) is not None {
            base = 16;
            marker = t[1].lower();
            if marker == "o" {
                base = 8;
            } elif marker == "b" {
                base = 2;
            }
            total = 0.0;
            for ch in t[2:] {
                total = total * float(base) + float(int(ch, 16));
            }
            return total;
        }
        if DECIMAL_LITERAL.match(t) is not None {
            if "Infinity" in t {
                return -math.inf if t.startswith("-") else math.inf;
            }
            return float(t);
        }
        return math.nan;
    }
    if isinstance(v, list) {
        return js_to_number(js_to_string(v));
    }
    return math.nan;
}

impl js_truthy(v: any) -> bool {
    if is_undefined(v) or v is None {
        return False;
    }
    if isinstance(v, bool) {
        return v;
    }
    if is_number(v) {
        x = float(v);
        return not (x == 0.0 or math.isnan(x));
    }
    if isinstance(v, str) {
        return len(v) > 0;
    }
    return True;
}

impl js_strict_equals(a: any, b: any) -> bool {
    if is_number(a) and is_number(b) {
        return float(a) == float(b);
    }
    if isinstance(a, bool) and isinstance(b, bool) {
        return a == b;
    }
    if isinstance(a, str) and isinstance(b, str) {
        return a == b;
    }
    if a is None and b is None {
        return True;
    }
    if is_undefined(a) and is_undefined(b) {
        return True;
    }
    if isinstance(a, list) or isinstance(a, dict) {
        return a is b;
    }
    return False;
}

impl js_less_than(a: any, b: any) -> bool | None {
    pa: any = js_to_string(a) if isinstance(a, list) or isinstance(a, dict) else a;
    pb: any = js_to_string(b) if isinstance(b, list) or isinstance(b, dict) else b;
    if isinstance(pa, str) and isinstance(pb, str) {
        return utf16_less(pa, pb);
    }
    na = js_to_number(pa);
    nb = js_to_number(pb);
    if math.isnan(na) or math.isnan(nb) {
        return None;
    }
    return na < nb;
}

impl js_lt(a: any, b: any) -> bool {
    r = js_less_than(a, b);
    return r is not None and r;
}

impl js_gt(a: any, b: any) -> bool {
    r = js_less_than(b, a);
    return r is not None and r;
}

impl js_lte(a: any, b: any) -> bool {
    r = js_less_than(b, a);
    return r is not None and not r;
}

impl js_gte(a: any, b: any) -> bool {
    r = js_less_than(a, b);
    return r is not None and not r;
}

impl js_parse_int(text: str) -> float {
    s = text.lstrip(JS_SPACE);
    sign = 1.0;
    if s.startswith("-") {
        sign = -1.0;
        s = s[1:];
    } elif s.startswith("+") {
        s = s[1:];
    }
    end = 0;
    while end < len(s) and s[end] >= "0" and s[end] <= "9" {
        end += 1;
    }
    if end == 0 {
        return math.nan;
    }
    return sign * float(s[:end]);
}

impl js_trim(text: str) -> str {
    return text.strip(JS_SPACE);
}

impl utf16_less(a: str, b: str) -> bool {
    if a.isascii() and b.isascii() {
        return a < b;
    }
    return a.encode("utf-16-be", "surrogatepass") < b.encode("utf-16-be", "surrogatepass");
}

impl js_keys(d: dict[str, any]) -> list[str] {
    indexed: list[str] = [];
    named: list[str] = [];
    for k in d.keys() {
        if len(k) <= 10 and INDEX_KEY.match(k) is not None and int(k) < 4294967295 {
            indexed.append(k);
        } else {
            named.append(k);
        }
    }
    if not indexed {
        return named;
    }
    return sorted(indexed, key=lambda (k: str) -> int { int(k) }) + named;
}

impl js_spread(v: any) -> dict[str, any] {
    out: dict[str, any] = {};
    if isinstance(v, dict) {
        for k in js_keys(v) {
            out[k] = v[k];
        }
    } elif isinstance(v, list) {
        for (i, x) in enumerate(v) {
            out[str(i)] = x;
        }
    } elif isinstance(v, str) {
        for (i, ch) in enumerate(v) {
            out[str(i)] = ch;
        }
    }
    return out;
}

impl quote_json_string(s: str) -> str {
    out: list[str] = ['"'];
    for ch in s {
        c = ord(ch);
        if ch == '"' {
            out.append('\\"');
        } elif ch == "\\" {
            out.append("\\\\");
        } elif ch == "\n" {
            out.append("\\n");
        } elif ch == "\r" {
            out.append("\\r");
        } elif ch == "\t" {
            out.append("\\t");
        } elif ch == "\b" {
            out.append("\\b");
        } elif ch == "\f" {
            out.append("\\f");
        } elif c < 32 or (c >= 55296 and c <= 57343) {
            out.append("\\u" + format(c, "04x"));
        } else {
            out.append(ch);
        }
    }
    out.append('"');
    return "".join(out);
}

impl stringify(value: any, indent: int = 0) -> str {
    r = stringify_at(value, " " * indent, "");
    return r if r is not None else "";
}

impl stringify_at(value: any, gap: str, indent: str) -> str | None {
    if is_undefined(value) {
        return None;
    }
    if value is None {
        return "null";
    }
    if isinstance(value, bool) {
        return "true" if value else "false";
    }
    if is_number(value) {
        if isinstance(value, float) and (math.isnan(value) or math.isinf(value)) {
            return "null";
        }
        return js_number_text(value);
    }
    if isinstance(value, str) {
        return quote_json_string(value);
    }
    step = indent + gap;
    parts: list[str] = [];
    if isinstance(value, list) {
        if len(value) == 0 {
            return "[]";
        }
        for x in value {
            s = stringify_at(x, gap, step);
            parts.append(s if s is not None else "null");
        }
        if gap == "" {
            return "[" + ",".join(parts) + "]";
        }
        return "[\n" + step + (",\n" + step).join(parts) + "\n" + indent + "]";
    }
    if isinstance(value, dict) {
        for k in js_keys(value) {
            s = stringify_at(value[k], gap, step);
            if s is not None {
                parts.append(quote_json_string(k) + (": " if gap != "" else ":") + s);
            }
        }
        if not parts {
            return "{}";
        }
        if gap == "" {
            return "{" + ",".join(parts) + "}";
        }
        return "{\n" + step + (",\n" + step).join(parts) + "\n" + indent + "}";
    }
    return None;
}

impl collation_key(s: str) -> tuple[list[int], list[int], list[int]] {
    if s in COLLATION_CACHE {
        return COLLATION_CACHE[s];
    }
    if len(COLLATION_CACHE) > 50000 {
        COLLATION_CACHE.clear();
    }
    key = compute_collation_key(s);
    COLLATION_CACHE[s] = key;
    return key;
}

impl compute_collation_key(s: str) -> tuple[list[int], list[int], list[int]] {
    primary: list[int] = [];
    secondary: list[int] = [];
    tertiary: list[int] = [];
    dollar = COLLATION_ASCII.find("$") + 1;
    zero = COLLATION_ASCII.find("0") + 1;
    for ch in unicodedata.normalize("NFD", s) {
        if unicodedata.combining(ch) != 0 {
            secondary.append(ord(ch));
            continue;
        }
        cat = unicodedata.category(ch);
        if cat == "Cc" and ch not in "\t\n\v\f\r" {
            continue;
        }
        low = ch.lower();
        idx = COLLATION_ASCII.find(low) if len(low) == 1 else -1;
        if idx >= 0 {
            primary.append(2 * (idx + 1));
            primary.append(0);
        } elif cat == "Nd" {
            primary.append(2 * (zero + unicodedata.digit(ch)));
            primary.append(ord(ch));
        } elif cat[0] == "P" or cat[0] == "S" or cat[0] == "Z" {
            primary.append(2 * dollar - 1);
            primary.append(ord(ch));
        } else {
            primary.append(2000);
            primary.append(ord(low[0]));
        }
        secondary.append(0);
        tertiary.append(0 if ch == low else 1);
    }
    return (primary, secondary, tertiary);
}

impl locale_compare(a: str, b: str) -> int {
    if a == b {
        return 0;
    }
    ka = collation_key(a);
    kb = collation_key(b);
    if ka < kb {
        return -1;
    }
    if kb < ka {
        return 1;
    }
    return 0;
}

impl js_json_int(literal: str) -> any {
    digits = literal.lstrip("-");
    if len(digits) < 16 {
        return int(literal);
    }
    value = float(literal);
    if abs(value) < 9007199254740992.0 {
        return int(literal);
    }
    return value;
}

impl json_parse(text: str) -> any {
    return json.loads(text, parse_int=js_json_int);
}
