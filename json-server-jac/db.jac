import os;
import from jsvalue { is_undefined, is_number, js_number_text, js_truthy, stringify }
import from jsonparse { parse_json }
import from json5 { json5_parse, json5_stringify }
import from store { JsTypeError, random_id, load, snapshot }

glob DEFAULT_SCHEMA_PATH: str = "./node_modules/json-server/schema.json";

obj UnsupportedData(Exception) {}

obj DataFile {
    has path: str,
        is_json5: bool = False;

    def read -> any;

    def write(data: dict[str, any]);
}

obj Database {
    has file: DataFile,
        writing: bool = False,
        last_write: tuple[float, int] = (0.0, -1);

    def read -> any;

    def write;
}

def describe_primitive(v: any) -> str;

def normalize(data: any) -> any;

def with_schema(data: dict[str, any]) -> dict[str, any];
