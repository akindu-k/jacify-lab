impl Handler.read_body -> bytes {
    if "chunked" in self.headers.get("Transfer-Encoding", "").lower() {
        data = bytearray();
        forever {
            size_line = self.rfile.readline().strip().split(b";")[0];
            size = int(size_line, 16) if size_line != b"" else 0;
            if size == 0 {
                while self.rfile.readline().strip() != b"" {}
                break;
            }
            data.extend(self.rfile.read(size));
            self.rfile.readline();
        }
        return bytes(data);
    }
    raw_length = self.headers.get("Content-Length", "0");
    length = int(raw_length) if raw_length.strip().isdigit() else 0;
    return self.rfile.read(length) if length > 0 else b"";
}

impl Handler.write_chunked(body: bytes) {
    if len(body) > 0 {
        self.wfile.write(format(len(body), "x").encode("ascii") + b"\r\n" + body + b"\r\n");
    }
    self.wfile.write(b"0\r\n\r\n");
}

impl Handler.respond {
    body = self.read_body();
    headers: dict[str, str] = {};
    for (k, v) in self.headers.items() {
        headers[k.lower()] = v;
    }
    app = APP;
    if app is None {
        self.send_error(503);
        return;
    }
    parts = self.requestline.split(" ");
    target = parts[1] if len(parts) >= 3 else self.path;
    resp = app.handle(Request(method=self.command, url=target, headers=headers, body=body));
    self.send_response_only(resp.status);
    self.send_header("Date", self.date_time_string());
    for (k, v) in resp.headers {
        self.send_header(k, v);
    }
    bodiless = self.command == "HEAD" or resp.status == 204 or resp.status == 304;
    chunked = False;
    if resp.file_path == "" and not bodiless {
        if resp.send_length {
            self.send_header("Content-Length", str(len(resp.body)));
        } else {
            self.send_header("Transfer-Encoding", "chunked");
            chunked = True;
        }
    }
    self.end_headers();
    if bodiless {
        return;
    }
    if resp.file_path != "" {
        with open(resp.file_path, "rb") as f {
            f.seek(resp.file_start);
            self.wfile.write(f.read(resp.file_end - resp.file_start + 1));
        }
        return;
    }
    if chunked {
        self.write_chunked(resp.body);
        return;
    }
    self.wfile.write(resp.body);
}

impl Handler.do_GET {
    self.respond();
}

impl Handler.do_HEAD {
    self.respond();
}

impl Handler.do_POST {
    self.respond();
}

impl Handler.do_PUT {
    self.respond();
}

impl Handler.do_PATCH {
    self.respond();
}

impl Handler.do_DELETE {
    self.respond();
}

impl Handler.do_OPTIONS {
    self.respond();
}

impl DualStackServer.server_bind {
    try {
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0);
    } except Exception {}
    super.server_bind();
}

impl make_server(port: int) -> ThreadingHTTPServer {
    try {
        return DualStackServer(("::", port), Handler);
    } except OSError {
        srv = ThreadingHTTPServer(("0.0.0.0", port), Handler);
        srv.daemon_threads = True;
        return srv;
    }
}

impl Handler.log_message(format: str, *args: any) {}

impl Handler.do_ACL {
    self.respond();
}

impl Handler.do_BIND {
    self.respond();
}

impl Handler.do_CHECKOUT {
    self.respond();
}

impl Handler.do_COPY {
    self.respond();
}

impl Handler.do_LINK {
    self.respond();
}

impl Handler.do_LOCK {
    self.respond();
}

impl Handler.do_MERGE {
    self.respond();
}

impl Handler.do_MKACTIVITY {
    self.respond();
}

impl Handler.do_MKCALENDAR {
    self.respond();
}

impl Handler.do_MKCOL {
    self.respond();
}

impl Handler.do_MOVE {
    self.respond();
}

impl Handler.do_NOTIFY {
    self.respond();
}

impl Handler.do_PROPFIND {
    self.respond();
}

impl Handler.do_PROPPATCH {
    self.respond();
}

impl Handler.do_PURGE {
    self.respond();
}

impl Handler.do_QUERY {
    self.respond();
}

impl Handler.do_REBIND {
    self.respond();
}

impl Handler.do_REPORT {
    self.respond();
}

impl Handler.do_SEARCH {
    self.respond();
}

impl Handler.do_SOURCE {
    self.respond();
}

impl Handler.do_SUBSCRIBE {
    self.respond();
}

impl Handler.do_TRACE {
    self.respond();
}

impl Handler.do_UNBIND {
    self.respond();
}

impl Handler.do_UNLINK {
    self.respond();
}

impl Handler.do_UNLOCK {
    self.respond();
}

impl Handler.do_UNSUBSCRIBE {
    self.respond();
}

impl Handler.do_CONNECT {
    self.close_connection = True;
}

impl Handler.parse_request -> bool {
    ok = super.parse_request();
    if ok and self.command not in NODE_METHODS {
        self.wfile.write(b"HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n");
        self.close_connection = True;
        return False;
    }
    return ok;
}
