import json;
import math;
import re;
import unicodedata;

class JsUndefined {}

glob UNDEFINED: JsUndefined = JsUndefined();

glob INDEX_KEY: re.Pattern = re.compile(r"(0|[1-9][0-9]*)\Z");

glob DECIMAL_LITERAL: re.Pattern = re.compile(
    r"[+-]?(Infinity|([0-9]+\.?[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?)\Z"
);

glob RADIX_LITERAL: re.Pattern = re.compile(r"0([xX][0-9a-fA-F]+|[oO][0-7]+|[bB][01]+)\Z");

glob JS_SPACE: str = " \t\n\v\f\r                 　﻿";

glob COLLATION_ASCII: str = "\t\n\v\f\r _-,;:!?.'\"()[]{}@*/\\&#%`^+<=>|~$0123456789abcdefghijklmnopqrstuvwxyz";

def is_undefined(v: any) -> bool;

def is_number(v: any) -> bool;

def is_object(v: any) -> bool;

def is_array(v: any) -> bool;

def js_number_text(n: any) -> str;

def js_to_string(v: any) -> str;

def js_to_number(v: any) -> float;

def js_truthy(v: any) -> bool;

def js_strict_equals(a: any, b: any) -> bool;

def js_less_than(a: any, b: any) -> bool | None;

def js_lt(a: any, b: any) -> bool;

def js_lte(a: any, b: any) -> bool;

def js_gt(a: any, b: any) -> bool;

def js_gte(a: any, b: any) -> bool;

def js_parse_int(text: str) -> float;

def js_trim(text: str) -> str;

def utf16_less(a: str, b: str) -> bool;

def js_keys(d: dict[str, any]) -> list[str];

def js_spread(v: any) -> dict[str, any];

def quote_json_string(s: str) -> str;

def stringify(value: any, indent: int = 0) -> str;

def stringify_at(value: any, gap: str, indent: str) -> str | None;

glob COLLATION_CACHE: dict[str, tuple[list[int], list[int], list[int]]] = {};

def collation_key(s: str) -> tuple[list[int], list[int], list[int]];

def compute_collation_key(s: str) -> tuple[list[int], list[int], list[int]];

def locale_compare(a: str, b: str) -> int;

def js_json_int(literal: str) -> any;

def json_parse(text: str) -> any;
