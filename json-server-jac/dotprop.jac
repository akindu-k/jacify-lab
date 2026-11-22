import from jsvalue { UNDEFINED, is_undefined, js_number_text }

glob DISALLOWED_KEYS: list[str] = ["__proto__", "prototype", "constructor"];

glob MAX_ARRAY_INDEX: int = 1000000;

def should_coerce_to_number(segment: str) -> bool;

def push_segment(segment: str, parts: list[any]) -> bool;

def parse_path(path: str) -> list[any];

def js_get(container: any, key: any) -> any;

def js_set(container: any, key: any, value: any);

def get_property(target: any, path: str) -> any;

def get_property_parts(target: any, keys: list[any]) -> any;

def set_property(target: any, path: str, value: any);
