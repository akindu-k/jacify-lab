import base64;
import secrets;
import from timsort { v8_sort }
import from jsvalue {
    UNDEFINED,
    is_undefined,
    is_number,
    js_truthy,
    js_strict_equals,
    js_lt,
    js_spread,
    js_keys,
    locale_compare,
}
import from inflect { singularize, pluralize }
import from dotprop { get_property, get_property_parts, parse_path }
import from matching { matches_where, paginate, page_json }

obj JsTypeError(Exception) {}

node Resource {
    has name: str;
}

node Collection(Resource) {}

node Singleton(Resource) {
    has value: any = None;
}

node Record {
    has fields: dict[str, any];
}

edge Holds: Collection --> Record {}

walker NullifyForeignKey {
    has source: str,
        target_id: str,
        key: str;

    can start with Root entry;

    can at_collection with Collection entry;
}

walker DeleteDependents {
    has source: str,
        dependents: list[str],
        key: str;

    can start with Root entry;

    can at_collection with Collection entry;
}

obj ListQuery {
    has where: any,
        sort: str | None = None,
        page: float | None = None,
        per_page: float | None = None,
        embed: any = None;
}

def random_id -> str;

def ensure_array(arg: any) -> list[any];

def resource(called: str) -> Resource | None;

def records(c: Collection) -> list[Record];

def record_by_id(c: Collection, id: str) -> Record | None;

def value_of(called: str) -> any;

def load(data: dict[str, any]);

def snapshot -> dict[str, any];

def resource_names -> list[str];

def embed(called: str, item: any, related: any) -> any;

def sort_on(items: list[any], props: list[str]) -> list[any];

def find(called: str, q: ListQuery) -> any;

def find_by_id(called: str, id: str, embeds: any) -> any;

def create(called: str, body: dict[str, any]) -> any;

def update_or_patch(called: str, body: dict[str, any], is_patch: bool) -> any;

def update_or_patch_by_id(called: str, id: str, body: dict[str, any], is_patch: bool) -> any;

def destroy_by_id(called: str, id: str, dependent: any) -> any;
