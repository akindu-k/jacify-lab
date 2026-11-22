import http.server;
import from http.server { ThreadingHTTPServer }
import socket;
import sys;
import from app { App, Request, Response }

glob APP: App | None = None;

glob NODE_METHODS: set[str] = {
    "ACL",
    "BIND",
    "CHECKOUT",
    "CONNECT",
    "COPY",
    "DELETE",
    "GET",
    "HEAD",
    "LINK",
    "LOCK",
    "M-SEARCH",
    "MERGE",
    "MKACTIVITY",
    "MKCALENDAR",
    "MKCOL",
    "MOVE",
    "NOTIFY",
    "OPTIONS",
    "PATCH",
    "POST",
    "PROPFIND",
    "PROPPATCH",
    "PURGE",
    "PUT",
    "QUERY",
    "REBIND",
    "REPORT",
    "SEARCH",
    "SOURCE",
    "SUBSCRIBE",
    "TRACE",
    "UNBIND",
    "UNLINK",
    "UNLOCK",
    "UNSUBSCRIBE",
};

class Handler(http.server.BaseHTTPRequestHandler) {
    has protocol_version: str = "HTTP/1.1",
        disable_nagle_algorithm: bool = True;

    def read_body -> bytes;

    def respond;

    def write_chunked(body: bytes);

    def do_GET;

    def do_HEAD;

    def do_POST;

    def do_PUT;

    def do_PATCH;

    def do_DELETE;

    def do_OPTIONS;

    def do_ACL;

    def do_BIND;

    def do_CHECKOUT;

    def do_COPY;

    def do_LINK;

    def do_LOCK;

    def do_MERGE;

    def do_MKACTIVITY;

    def do_MKCALENDAR;

    def do_MKCOL;

    def do_MOVE;

    def do_NOTIFY;

    def do_PROPFIND;

    def do_PROPPATCH;

    def do_PURGE;

    def do_QUERY;

    def do_REBIND;

    def do_REPORT;

    def do_SEARCH;

    def do_SOURCE;

    def do_SUBSCRIBE;

    def do_TRACE;

    def do_UNBIND;

    def do_UNLINK;

    def do_UNLOCK;

    def do_UNSUBSCRIBE;

    def do_CONNECT;

    override def parse_request -> bool;

    override def log_message(format: str, *args: any);
}

class DualStackServer(ThreadingHTTPServer) {
    has address_family: int = 10,
        daemon_threads: bool = True;

    override def server_bind;
}

def make_server(port: int) -> ThreadingHTTPServer;
