import from jsvalue { js_number_text, js_keys, is_undefined }

glob JSON5_ESCAPES: dict[str, str] = {
    "'": "\\'",
    '"': '\\"',
    "\\": "\\\\",
    "\b": "\\b",
    "\f": "\\f",
    "\n": "\\n",
    "\r": "\\r",
    "\t": "\\t",
    "\v": "\\v",
    "\x00": "\\0",
    " ": "\\u2028",
    " ": "\\u2029",
};

obj Json5Error(Exception) {}

obj Json5Parser {
    has text: str,
        pos: int = 0,
        line: int = 1,
        column: int = 0;

    def peek(offset: int = 0) -> str;

    def advance -> str;

    def fail_at_current;

    def format_char(c: str) -> str;

    def skip_space;

    def is_space(c: str) -> bool;

    def parse_document -> any;

    def parse_value -> any;

    def parse_object -> dict[str, any];

    def parse_array -> list[any];

    def parse_key -> str;

    def parse_identifier -> str;

    def parse_string -> str;

    def parse_number -> any;

    def parse_word(word: str, value: any) -> any;
}

def is_id_start(c: str) -> bool;

def is_id_continue(c: str) -> bool;

def json5_parse(text: str) -> any;

def json5_quote(value: str) -> str;

def json5_key(key: str) -> str;

def json5_stringify(value: any) -> str;
