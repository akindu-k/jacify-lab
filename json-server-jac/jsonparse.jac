import json;
import from jsvalue { js_json_int }

obj JsSyntaxError(Exception) {}

obj V8JsonParser {
    has text: str,
        pos: int = 0;

    def peek -> str;

    def skip_space;

    def where(at: int) -> str;

    def fail(template: str, at: int);

    def unexpected(at: int);

    def parse -> any;

    def value -> any;

    def literal(word: str, result: any) -> any;

    def object_value -> dict[str, any];

    def array_value -> list[any];

    def string_value -> str;

    def number_value -> any;
}

def reject_constant(name: str) -> any;

def parse_json(text: str) -> any;
