impl V8JsonParser.peek -> str {
    return self.text[self.pos] if self.pos < len(self.text) else "";
}

impl V8JsonParser.skip_space {
    while self.pos < len(self.text) and self.text[self.pos] in " \t\n\r" {
        self.pos += 1;
    }
}

impl V8JsonParser.where(at: int) -> str {
    units = at + len([c for c in self.text[:at] if ord(c) > 65535]);
    line = self.text.count("\n", 0, at) + 1;
    last = self.text.rfind("\n", 0, at);
    column = units + 1;
    if last >= 0 {
        column = units - (last + len([c for c in self.text[:last] if ord(c) > 65535]));
    }
    return f" in JSON at position {units} (line {line} column {column})";
}

impl V8JsonParser.fail(template: str, at: int) {
    suffix = self.where(at);
    if template.endswith("after JSON") {
        suffix = suffix.replace(" in JSON", "", 1);
    }
    raise JsSyntaxError(template + suffix);
}

impl V8JsonParser.unexpected(at: int) {
    if at >= len(self.text) {
        raise JsSyntaxError("Unexpected end of JSON input");
    }
    c = self.text[at];
    if c == "-" or (c >= "0" and c <= "9") {
        self.fail("Unexpected number", at);
    }
    if c == '"' {
        self.fail("Unexpected string", at);
    }
    if self.text in ["[object Object]", "undefined", "Infinity", "NaN"] {
        raise JsSyntaxError(f'"{self.text}" is not valid JSON');
    }
    n = len(self.text);
    if n < 21 {
        raise JsSyntaxError(f"Unexpected token '{c}', \"{self.text}\" is not valid JSON");
    }
    if at < 10 {
        raise JsSyntaxError(
            f"Unexpected token '{c}', \"{self.text[:at + 10]}\"... is not valid JSON"
        );
    }
    if at < n - 10 {
        raise JsSyntaxError(
            f"Unexpected token '{c}', ...\"{self.text[at - 10:at + 10]}\"... is not valid JSON"
        );
    }
    raise JsSyntaxError(f"Unexpected token '{c}', ...\"{self.text[at - 10:]}\" is not valid JSON");
}

impl V8JsonParser.parse -> any {
    self.skip_space();
    result = self.value();
    self.skip_space();
    if self.pos < len(self.text) {
        self.fail("Unexpected non-whitespace character after JSON", self.pos);
    }
    return result;
}

impl V8JsonParser.value -> any {
    self.skip_space();
    c = self.peek();
    if c == "{" {
        return self.object_value();
    }
    if c == "[" {
        return self.array_value();
    }
    if c == '"' {
        return self.string_value();
    }
    if c == "-" or (c >= "0" and c <= "9" and c != "") {
        return self.number_value();
    }
    if c == "t" {
        return self.literal("true", True);
    }
    if c == "f" {
        return self.literal("false", False);
    }
    if c == "n" {
        return self.literal("null", None);
    }
    self.unexpected(self.pos);
    return None;
}

impl V8JsonParser.literal(word: str, result: any) -> any {
    for expected in word {
        if self.peek() != expected {
            self.unexpected(self.pos);
        }
        self.pos += 1;
    }
    return result;
}

impl V8JsonParser.object_value -> dict[str, any] {
    self.pos += 1;
    out: dict[str, any] = {};
    self.skip_space();
    if self.peek() == "}" {
        self.pos += 1;
        return out;
    }
    if self.peek() != '"' {
        self.fail("Expected property name or '}'", self.pos);
    }
    forever {
        key = self.string_value();
        self.skip_space();
        if self.peek() != ":" {
            self.fail("Expected ':' after property name", self.pos);
        }
        self.pos += 1;
        out[key] = self.value();
        self.skip_space();
        c = self.peek();
        if c == "}" {
            self.pos += 1;
            return out;
        }
        if c != "," {
            self.fail("Expected ',' or '}' after property value", self.pos);
        }
        self.pos += 1;
        self.skip_space();
        if self.peek() != '"' {
            self.fail("Expected double-quoted property name", self.pos);
        }
    }
}

impl V8JsonParser.array_value -> list[any] {
    self.pos += 1;
    out: list[any] = [];
    self.skip_space();
    if self.peek() == "]" {
        self.pos += 1;
        return out;
    }
    forever {
        out.append(self.value());
        self.skip_space();
        c = self.peek();
        if c == "]" {
            self.pos += 1;
            return out;
        }
        if c != "," {
            self.fail("Expected ',' or ']' after array element", self.pos);
        }
        self.pos += 1;
    }
}

impl V8JsonParser.string_value -> str {
    self.pos += 1;
    out: list[str] = [];
    forever {
        if self.pos >= len(self.text) {
            self.fail("Unterminated string", self.pos);
        }
        c = self.text[self.pos];
        if c == '"' {
            self.pos += 1;
            return "".join(out);
        }
        if ord(c) < 32 {
            self.fail("Bad control character in string literal", self.pos);
        }
        if c != "\\" {
            out.append(c);
            self.pos += 1;
            continue;
        }
        self.pos += 1;
        e = self.peek();
        if e == "" {
            raise JsSyntaxError("Unexpected end of JSON input");
        }
        simple = {
            '"': '"',
            "\\": "\\",
            "/": "/",
            "b": "\b",
            "f": "\f",
            "n": "\n",
            "r": "\r",
            "t": "\t",
        };
        if e in simple {
            out.append(simple[e]);
            self.pos += 1;
        } elif e == "u" {
            self.pos += 1;
            digits = "";
            for _ in range(4) {
                d = self.peek();
                if d == "" or d not in "0123456789abcdefABCDEF" {
                    self.fail("Bad Unicode escape", self.pos);
                }
                digits += d;
                self.pos += 1;
            }
            out.append(chr(int(digits, 16)));
        } else {
            self.fail("Bad escaped character", self.pos);
        }
    }
}

impl V8JsonParser.number_value -> any {
    start = self.pos;
    if self.peek() == "-" {
        self.pos += 1;
        if not (self.peek() >= "0" and self.peek() <= "9" and self.peek() != "") {
            self.fail("No number after minus sign", self.pos);
        }
    }
    if self.peek() == "0" {
        self.pos += 1;
        if self.peek() >= "0" and self.peek() <= "9" and self.peek() != "" {
            self.unexpected(self.pos);
        }
    } else {
        while self.peek() >= "0" and self.peek() <= "9" and self.peek() != "" {
            self.pos += 1;
        }
    }
    is_float = False;
    if self.peek() == "." {
        is_float = True;
        self.pos += 1;
        if not (self.peek() >= "0" and self.peek() <= "9" and self.peek() != "") {
            self.fail("Unterminated fractional number", self.pos);
        }
        while self.peek() >= "0" and self.peek() <= "9" and self.peek() != "" {
            self.pos += 1;
        }
    }
    if self.peek() == "e" or self.peek() == "E" {
        is_float = True;
        self.pos += 1;
        if self.peek() == "+" or self.peek() == "-" {
            self.pos += 1;
        }
        if not (self.peek() >= "0" and self.peek() <= "9" and self.peek() != "") {
            self.fail("Exponent part is missing a number", self.pos);
        }
        while self.peek() >= "0" and self.peek() <= "9" and self.peek() != "" {
            self.pos += 1;
        }
    }
    literal = self.text[start:self.pos];
    if is_float {
        return float(literal);
    }
    return js_json_int(literal);
}

impl reject_constant(name: str) -> any {
    raise ValueError(name);
}

impl parse_json(text: str) -> any {
    try {
        return json.loads(text, parse_int=js_json_int, parse_constant=reject_constant);
    } except ValueError {
        return V8JsonParser(text=text).parse();
    }
}
