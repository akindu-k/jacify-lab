import os;
import re;
import base64;
import hashlib;
import threading;
import email.utils;
import from jsvalue { UNDEFINED, is_undefined, js_parse_int, stringify }
import from jsonparse { JsSyntaxError, parse_json }
import from query { RESERVED_QUERY_KEYS, search_params, query_object, parse_where_pairs }
import from store {
    ListQuery,
    find,
    find_by_id,
    create,
    update_or_patch,
    update_or_patch_by_id,
    destroy_by_id,
    snapshot,
}
import from db { Database }
import from views { render_index, escape_html }
import from mimes { mime_lookup }

glob POWERED_BY: str = "json-server-jac";

glob PAYLOAD_LIMIT: int = 102400;

glob ONE_SEGMENT: re.Pattern = re.compile(r"/([^/]+?)/?\Z", re.IGNORECASE);

glob TWO_SEGMENTS: re.Pattern = re.compile(r"/([^/]+?)/([^/]+?)/?\Z", re.IGNORECASE);

glob PREFIX_SEGMENT: re.Pattern = re.compile(r"/([^/]+?)(?=/|\Z)", re.IGNORECASE);

glob URI_RESERVED: str = ";/?:@&=+$,#";

obj URIError(Exception) {}

obj Request {
    has method: str,
        url: str,
        headers: dict[str, str] = {},
        body: bytes = b"";
}

obj Response {
    has status: int = 200,
        headers: list[tuple[str, str]] = [],
        body: bytes = b"",
        send_length: bool = True,
        file_path: str = "",
        file_start: int = 0,
        file_end: int = -1;
}

obj StaticFile {
    has path: str,
        name: str,
        size: int,
        mtime: float;
}

obj App {
    has db: Database,
        static_roots: list[str] = [],
        production: bool = False,
        listing: dict[str, dict[str, StaticFile]] = {},
        lock: threading.RLock = threading.RLock();

    def postinit;

    def handle(req: Request) -> Response;

    def dispatch(req: Request) -> Response;

    def static_lookup(top: str, pathname: str) -> StaticFile | None;
}

def decode_uri_component(text: str, keep: str = "") -> str;

def decode_uri(text: str) -> str;

def etag_of(body: bytes) -> str;

def http_date(t: float) -> str;

def content_type_of(name: str) -> str;

def to_assume(uri: str, extensions: list[str]) -> list[str];

def walk_files(top: str) -> dict[str, StaticFile];

def serve_static(
    req: Request, f: StaticFile, headers: list[tuple[str, str]], production: bool
) -> Response;

def json_response(status: int, data: any, headers: list[tuple[str, str]], method: str) -> Response;

def text_error(
    status: int, message: str, headers: list[tuple[str, str]], production: bool, method: str
) -> Response;

def send_status(status: int, text: str, headers: list[tuple[str, str]], method: str) -> Response;

def is_fresh(req: Request, etag: str) -> bool;

def list_query(url: str) -> ListQuery;
