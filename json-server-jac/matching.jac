import from jsvalue {
    UNDEFINED,
    is_undefined,
    js_strict_equals,
    js_lt,
    js_lte,
    js_gt,
    js_gte,
    js_to_string,
    js_keys,
}
import from query { WHERE_OPERATORS }

obj Page {
    has first: int,
        prev: int | None,
        next: int | None,
        last: int,
        pages: int,
        items: int,
        data: list[any];
}

def entries(value: any) -> list[tuple[str, any]];

def known_operators(value: any) -> list[str];

def field_of(target: any, key: str) -> any;

def matches_where(target: any, where: any) -> bool;

def paginate(items: list[any], page: float, per_page: float) -> Page;

def page_json(p: Page) -> dict[str, any];
