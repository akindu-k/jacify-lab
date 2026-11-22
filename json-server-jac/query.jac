import re;
import from jsvalue { js_to_number, js_trim, js_number_text }
import from dotprop { set_property }

glob WHERE_OPERATORS: list[str] = [
    "lt",
    "lte",
    "gt",
    "gte",
    "eq",
    "ne",
    "in",
    "contains",
    "startsWith",
    "endsWith",
];

glob RESERVED_QUERY_KEYS: set[str] = {"_sort", "_page", "_per_page", "_embed", "_where"};

glob LEGACY_OPERATOR: re.Pattern = re.compile(r"([^\n\r  ]*)_([a-z]+)\Z");

obj KeyOp {
    has path: str,
        op: str | None;
}

def percent_decode(text: str) -> str;

def search_params(query: str) -> list[tuple[str, str]];

def query_object(query: str) -> dict[str, any];

def is_where_operator(word: str) -> bool;

def split_key(key: str) -> KeyOp;

def coerce_value(value: str) -> any;

def parse_where_pairs(pairs: list[tuple[str, str]]) -> dict[str, any];

def parse_where(query: str) -> dict[str, any];
