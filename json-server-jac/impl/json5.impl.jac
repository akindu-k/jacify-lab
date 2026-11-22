import math;
import unicodedata;

impl Json5Parser.peek(offset: int = 0) -> str {
    i = self.pos + offset;
    return self.text[i] if i < len(self.text) else "";
}

impl Json5Parser.advance -> str {
    c = self.peek();
    if c == "" {
        return c;
    }
    self.pos += 1;
    if c == "\n" {
        self.line += 1;
        self.column = 0;
    } else {
        self.column += 1;
    }
    return c;
}

impl Json5Parser.format_char(c: str) -> str {
    if c in JSON5_ESCAPES {
        return JSON5_ESCAPES[c];
    }
    if c < " " {
        return "\\x" + format(ord(c), "02x");
    }
    return c;
}

impl Json5Parser.fail_at_current {
    c = self.peek();
    if c == "" {
        raise Json5Error(f"JSON5: invalid end of input at {self.line}:{self.column + 1}");
    }
    self.advance();
    raise Json5Error(
        f"JSON5: invalid character '{self.format_char(c)}' at {self.line}:{self.column}"
    );
}

impl Json5Parser.is_space(c: str) -> bool {
    if c == "" {
        return False;
    }
    if c in "\t\v\f  ﻿\n\r  " {
        return True;
    }
    return unicodedata.category(c) == "Zs";
}

impl Json5Parser.skip_space {
    forever {
        c = self.peek();
        if self.is_space(c) {
            self.advance();
        } elif c == "/" and self.peek(1) == "/" {
            while self.peek() != "" and self.peek() not in "\n\r  " {
                self.advance();
            }
        } elif c == "/" and self.peek(1) == "*" {
            self.advance();
            self.advance();
            forever {
                if self.peek() == "" {
                    self.fail_at_current();
                }
                if self.peek() == "*" and self.peek(1) == "/" {
                    self.advance();
                    self.advance();
                    break;
                }
                self.advance();
            }
        } elif c == "/" {
            self.advance();
            self.fail_at_current();
        } else {
            return;
        }
    }
}

impl Json5Parser.parse_document -> any {
    self.skip_space();
    value = self.parse_value();
    self.skip_space();
    if self.peek() != "" {
        self.fail_at_current();
    }
    return value;
}

impl Json5Parser.parse_value -> any {
    self.skip_space();
    c = self.peek();
    if c == "{" {
        return self.parse_object();
    }
    if c == "[" {
        return self.parse_array();
    }
    if c == '"' or c == "'" {
        return self.parse_string();
    }
    if c == "n" {
        return self.parse_word("null", None);
    }
    if c == "t" {
        return self.parse_word("true", True);
    }
    if c == "f" {
        return self.parse_word("false", False);
    }
    if c != "" and c in "+-.0123456789IN" {
        return self.parse_number();
    }
    self.fail_at_current();
    return None;
}

impl Json5Parser.parse_word(word: str, value: any) -> any {
    for expected in word {
        if self.peek() != expected {
            self.fail_at_current();
        }
        self.advance();
    }
    return value;
}

impl Json5Parser.parse_object -> dict[str, any] {
    self.advance();
    out: dict[str, any] = {};
    self.skip_space();
    if self.peek() == "}" {
        self.advance();
        return out;
    }
    forever {
        self.skip_space();
        if self.peek() == "}" {
            self.advance();
            return out;
        }
        key = self.parse_key();
        self.skip_space();
        if self.peek() != ":" {
            self.fail_at_current();
        }
        self.advance();
        out[key] = self.parse_value();
        self.skip_space();
        c = self.peek();
        if c == "," {
            self.advance();
        } elif c == "}" {
            self.advance();
            return out;
        } else {
            self.fail_at_current();
        }
    }
}

impl Json5Parser.parse_array -> list[any] {
    self.advance();
    out: list[any] = [];
    forever {
        self.skip_space();
        if self.peek() == "]" {
            self.advance();
            return out;
        }
        out.append(self.parse_value());
        self.skip_space();
        c = self.peek();
        if c == "," {
            self.advance();
        } elif c == "]" {
            self.advance();
            return out;
        } else {
            self.fail_at_current();
        }
    }
}

impl Json5Parser.parse_key -> str {
    c = self.peek();
    if c == '"' or c == "'" {
        return self.parse_string();
    }
    return self.parse_identifier();
}

impl Json5Parser.parse_identifier -> str {
    out = "";
    forever {
        c = self.peek();
        if c == "\\" {
            self.advance();
            if self.peek() != "u" {
                self.fail_at_current();
            }
            self.advance();
            digits = "";
            for _ in range(4) {
                d = self.peek();
                if d == "" or d not in "0123456789abcdefABCDEF" {
                    self.fail_at_current();
                }
                digits += self.advance();
            }
            ch = chr(int(digits, 16));
            if (out == "" and not is_id_start(ch)) or (out != "" and not is_id_continue(ch)) {
                raise Json5Error(
                    f"JSON5: invalid identifier character at {self.line}:{self.column - 5}"
                );
            }
            out += ch;
            continue;
        }
        if out == "" {
            if not is_id_start(c) {
                self.fail_at_current();
            }
        } elif not is_id_continue(c) {
            return out;
        }
        out += self.advance();
    }
}

impl Json5Parser.parse_string -> str {
    quote = self.advance();
    out: list[str] = [];
    forever {
        c = self.peek();
        if c == "" {
            self.fail_at_current();
        }
        if c == quote {
            self.advance();
            return "".join(out);
        }
        if c == "\n" or c == "\r" {
            self.fail_at_current();
        }
        if c != "\\" {
            out.append(self.advance());
            continue;
        }
        self.advance();
        e = self.peek();
        if e == "" {
            self.fail_at_current();
        }
        simple = {
            "b": "\b",
            "f": "\f",
            "n": "\n",
            "r": "\r",
            "t": "\t",
            "v": "\v",
            "'": "'",
            '"': '"',
            "\\": "\\",
        };
        if e in simple {
            self.advance();
            out.append(simple[e]);
        } elif e == "0" {
            self.advance();
            if self.peek() != "" and self.peek() in "0123456789" {
                self.fail_at_current();
            }
            out.append("\x00");
        } elif e == "x" or e == "u" {
            self.advance();
            count = 2 if e == "x" else 4;
            digits = "";
            for _ in range(count) {
                d = self.peek();
                if d == "" or d not in "0123456789abcdefABCDEF" {
                    self.fail_at_current();
                }
                digits += self.advance();
            }
            out.append(chr(int(digits, 16)));
        } elif e == "\n" or e == " " or e == " " {
            self.advance();
        } elif e == "\r" {
            self.advance();
            if self.peek() == "\n" {
                self.advance();
            }
        } elif e in "123456789" {
            self.fail_at_current();
        } else {
            out.append(self.advance());
        }
    }
}

impl Json5Parser.parse_number -> any {
    sign = 1;
    c = self.peek();
    if c == "+" or c == "-" {
        if c == "-" {
            sign = -1;
        }
        self.advance();
        c = self.peek();
    }
    if c == "I" {
        self.parse_word("Infinity", None);
        return math.inf * float(sign);
    }
    if c == "N" {
        self.parse_word("NaN", None);
        return math.nan;
    }
    if c == "0" and self.peek(1) != "" and self.peek(1) in "xX" {
        self.advance();
        self.advance();
        digits = "";
        while self.peek() != "" and self.peek() in "0123456789abcdefABCDEF" {
            digits += self.advance();
        }
        if digits == "" {
            self.fail_at_current();
        }
        total = 0.0;
        for d in digits {
            total = total * 16.0 + float(int(d, 16));
        }
        if total < 9007199254740992.0 {
            return sign * int(total);
        }
        return total * float(sign);
    }
    text = "";
    is_float = False;
    if self.peek() == "0" {
        text += self.advance();
        if self.peek() != "" and self.peek() in "0123456789" {
            self.fail_at_current();
        }
    } else {
        while self.peek() != "" and self.peek() in "0123456789" {
            text += self.advance();
        }
    }
    if self.peek() == "." {
        is_float = True;
        text += self.advance();
        while self.peek() != "" and self.peek() in "0123456789" {
            text += self.advance();
        }
    }
    if text == "" or text == "." {
        self.fail_at_current();
    }
    if self.peek() != "" and self.peek() in "eE" {
        is_float = True;
        text += self.advance();
        if self.peek() != "" and self.peek() in "+-" {
            text += self.advance();
        }
        exp_start = len(text);
        while self.peek() != "" and self.peek() in "0123456789" {
            text += self.advance();
        }
        if len(text) == exp_start {
            self.fail_at_current();
        }
    }
    if text.startswith(".") {
        text = "0" + text;
    }
    if text.endswith(".") {
        text = text + "0";
    }
    if not is_float and len(text) < 16 {
        return sign * int(text);
    }
    value = float(text) * float(sign);
    if not is_float and abs(value) < 9007199254740992.0 {
        return sign * int(text);
    }
    return value;
}

impl is_id_start(c: str) -> bool {
    if c == "" {
        return False;
    }
    return c == "$" or c == "_" or c.isidentifier();
}

impl is_id_continue(c: str) -> bool {
    if c == "" {
        return False;
    }
    return c == "$" or c == "‌" or c == "‍" or ("a" + c).isidentifier();
}

impl json5_parse(text: str) -> any {
    return Json5Parser(text=text).parse_document();
}

impl json5_quote(value: str) -> str {
    single = 0;
    double = 0;
    out: list[str] = [];
    for (i, c) in enumerate(value) {
        if c == "'" {
            single += 1;
            out.append(c);
            continue;
        }
        if c == '"' {
            double += 1;
            out.append(c);
            continue;
        }
        if c == "\x00" and i + 1 < len(value) and value[i + 1] in "0123456789" {
            out.append("\\x00");
            continue;
        }
        if c in JSON5_ESCAPES {
            out.append(JSON5_ESCAPES[c]);
            continue;
        }
        if c < " " {
            out.append("\\x" + format(ord(c), "02x"));
            continue;
        }
        out.append(c);
    }
    quote = "'" if single <= double else '"';
    body = "".join(out).replace(quote, JSON5_ESCAPES[quote]);
    return quote + body + quote;
}

impl json5_key(key: str) -> str {
    if key == "" or not is_id_start(key[0]) {
        return json5_quote(key);
    }
    for c in key[1:] {
        if not is_id_continue(c) {
            return json5_quote(key);
        }
    }
    return key;
}

impl json5_stringify(value: any) -> str {
    if is_undefined(value) {
        return "";
    }
    if value is None {
        return "null";
    }
    if isinstance(value, bool) {
        return "true" if value else "false";
    }
    if isinstance(value, str) {
        return json5_quote(value);
    }
    if (isinstance(value, int) or isinstance(value, float)) {
        return js_number_text(value);
    }
    if isinstance(value, list) {
        return "["
            + ",".join([("null" if is_undefined(x) else json5_stringify(x)) for x in value])
            + "]";
    }
    if isinstance(value, dict) {
        parts: list[str] = [];
        for k in js_keys(value) {
            if not is_undefined(value[k]) {
                parts.append(json5_key(k) + ":" + json5_stringify(value[k]));
            }
        }
        return "{" + ",".join(parts) + "}";
    }
    return "";
}
