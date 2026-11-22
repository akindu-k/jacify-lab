impl decode_uri_component(text: str, keep: str = "") -> str {
    if "%" not in text {
        return text;
    }
    out: list[str] = [];
    i = 0;
    n = len(text);
    hexdigits = "0123456789abcdefABCDEF";
    while i < n {
        if text[i] != "%" {
            out.append(text[i]);
            i += 1;
            continue;
        }
        start = i;
        chunk = bytearray();
        while i < n and text[i] == "%" {
            pair = text[i + 1:i + 3];
            if len(pair) < 2 or pair[0] not in hexdigits or pair[1] not in hexdigits {
                raise URIError("URI malformed");
            }
            chunk.append(int(pair, 16));
            i += 3;
        }
        try {
            decoded = bytes(chunk).decode("utf-8");
        } except UnicodeDecodeError {
            raise URIError("URI malformed");
        }
        if keep == "" {
            out.append(decoded);
            continue;
        }
        pos = start;
        for ch in decoded {
            width = len(ch.encode("utf-8"));
            raw = text[pos:pos + 3 * width];
            out.append(raw if ch in keep else ch);
            pos += 3 * width;
        }
    }
    return "".join(out);
}

impl decode_uri(text: str) -> str {
    return decode_uri_component(text, URI_RESERVED);
}

impl etag_of(body: bytes) -> str {
    if len(body) == 0 {
        return 'W/"0-2jmj7l5rSw0yVb/vlWAYkK/YBwk"';
    }
    digest = base64.b64encode(hashlib.sha1(body).digest()).decode("ascii")[:27];
    return 'W/"' + format(len(body), "x") + "-" + digest + '"';
}

impl http_date(t: float) -> str {
    return email.utils.formatdate(float(int(t)), usegmt=True);
}

impl content_type_of(name: str) -> str {
    kind = mime_lookup(name);
    if kind == "text/html" {
        return "text/html;charset=utf-8";
    }
    return kind;
}

impl to_assume(uri: str, extensions: list[str]) -> list[str] {
    base = uri[:-1] if uri.endswith("/") else uri;
    index = base + "/index";
    out: list[str] = [];
    for e in extensions {
        x = "." + e if e != "" else "";
        if base != "" {
            out.append(base + x);
        }
        out.append(index + x);
    }
    return out;
}

impl walk_files(top: str) -> dict[str, StaticFile] {
    found: dict[str, StaticFile] = {};
    if not os.path.isdir(top) {
        return found;
    }
    for (folder, dirs, files) in os.walk(top) {
        for name in files {
            full = os.path.join(folder, name);
            rel = os.path.relpath(full, top).replace(os.sep, "/");
            hidden = rel.startswith(".") or "/." in rel;
            if hidden and ".well-known/" not in rel {
                continue;
            }
            st = os.stat(full);
            found["/" + rel] = StaticFile(
                path=full, name="/" + rel, size=st.st_size, mtime=st.st_mtime
            );
        }
    }
    return found;
}

impl serve_static(
    req: Request, f: StaticFile, headers: list[tuple[str, str]], production: bool
) -> Response {
    encoding = "";
    base_name = f.name;
    if f.name.endswith(".gz") {
        encoding = "gzip";
        base_name = f.name[:-3];
    } elif f.name.endswith(".br") {
        encoding = "br";
        base_name = f.name[:-3];
    }
    out = list(headers);
    status = 200;
    start = 0;
    end = f.size - 1;
    length = f.size;
    rng = req.headers.get("range", "");
    if rng != "" {
        status = 206;
        bounds = rng.replace("bytes=", "", 1).split("-");
        hi = js_parse_int(bounds[1]) if len(bounds) > 1 else float("nan");
        lo = js_parse_int(bounds[0]);
        end = int(hi) if hi == hi and hi != 0.0 else f.size - 1;
        start = int(lo) if lo == lo and lo != 0.0 else 0;
        if end >= f.size {
            end = f.size - 1;
        }
        if start >= f.size {
            out.append(("Content-Range", f"bytes */{f.size}"));
            return Response(status=416, headers=out, body=b"");
        }
        length = end - start + 1;
    }
    out.append(("Content-Length", str(length)));
    out.append(("Content-Type", content_type_of(base_name)));
    out.append(("Last-Modified", http_date(f.mtime)));
    if encoding != "" {
        out.append(("Content-Encoding", encoding));
    }
    if not production {
        out.append(("Cache-Control", "no-store"));
    }
    if status == 206 {
        out.append(("Content-Range", f"bytes {start}-{end}/{f.size}"));
        out.append(("Accept-Ranges", "bytes"));
    }
    if req.method == "HEAD" {
        return Response(status=status, headers=out, send_length=False);
    }
    return Response(
        status=status,
        headers=out,
        send_length=False,
        file_path=f.path,
        file_start=start,
        file_end=end,
    );
}

impl json_response(
    status: int, data: any, headers: list[tuple[str, str]], method: str
) -> Response {
    out = list(headers);
    out.append(("Content-Type", "application/json"));
    body = b"";
    if isinstance(data, str) {
        body = data.encode("utf-8");
    } elif data is not None {
        body = stringify(data, 2).encode("utf-8");
    }
    if method == "HEAD" {
        return Response(status=status, headers=out, send_length=False);
    }
    if data is None {
        return Response(status=status, headers=out, send_length=False);
    }
    return Response(status=status, headers=out, body=body);
}

impl text_error(
    status: int, message: str, headers: list[tuple[str, str]], production: bool, method: str
) -> Response {
    out = list(headers);
    out.append(("Content-Type", "text/plain; charset=utf-8"));
    out.append(("X-Content-Type-Options", "nosniff"));
    text = "Internal Server Error" if production and status == 500 else message;
    return Response(
        status=status,
        headers=out,
        body=b"" if method == "HEAD" else escape_html(text).encode("utf-8"),
        send_length=False,
    );
}

impl send_status(status: int, text: str, headers: list[tuple[str, str]], method: str) -> Response {
    out = list(headers);
    body = text.encode("utf-8");
    out.append(("Content-Type", "text/plain; charset=utf-8"));
    out.append(("etag", etag_of(body)));
    if method == "HEAD" {
        return Response(status=status, headers=out, send_length=False);
    }
    return Response(status=status, headers=out, body=body);
}

impl is_fresh(req: Request, etag: str) -> bool {
    none_match = req.headers.get("if-none-match", "");
    modified_since = req.headers.get("if-modified-since", "");
    if none_match == "" and modified_since == "" {
        return False;
    }
    if "no-cache" in req.headers.get("cache-control", "") {
        return False;
    }
    if none_match != "" and none_match != "*" {
        stale = True;
        for token in none_match.split(",") {
            m = token.strip();
            if m == etag or m == "W/" + etag or "W/" + m == etag {
                stale = False;
                break;
            }
        }
        if stale {
            return False;
        }
    }
    if modified_since != "" {
        return False;
    }
    return True;
}

impl list_query(url: str) -> ListQuery {
    pieces = url.split("?");
    query = pieces[1] if len(pieces) > 1 else "";
    params = search_params(query);
    filters = [(k, v) for (k, v) in params if k not in RESERVED_QUERY_KEYS];
    where: any = parse_where_pairs(filters);
    first: dict[str, str] = {};
    for (k, v) in params {
        if k not in first {
            first[k] = v;
        }
    }
    if "_where" in first {
        try {
            parsed = parse_json(first["_where"]);
            if isinstance(parsed, dict) or isinstance(parsed, list) {
                where = parsed;
            }
        } except JsSyntaxError {}
    }
    page: float | None = None;
    per_page: float | None = None;
    if "_page" in first {
        p = js_parse_int(first["_page"]);
        page = None if p != p else p;
    }
    if "_per_page" in first {
        p = js_parse_int(first["_per_page"]);
        per_page = None if p != p else p;
    }
    q = url.find("?");
    raw_query = url[q + 1:] if q >= 0 else "";
    embeds: any = query_object(raw_query).get("_embed", None);
    return ListQuery(
        where=where, sort=first.get("_sort", None), page=page, per_page=per_page, embed=embeds
    );
}

impl App.postinit {
    if self.production {
        for top in self.static_roots {
            self.listing[top] = walk_files(top);
        }
    }
}

impl App.static_lookup(top: str, pathname: str) -> StaticFile | None {
    path = pathname;
    if "%" in path {
        try {
            path = decode_uri(path);
        } except URIError {}
    }
    candidates = to_assume(path, ["", "html", "htm"]);
    if self.production {
        files = self.listing.get(top, {});
        for name in candidates {
            if name in files {
                return files[name];
            }
        }
        return None;
    }
    prefix = top.rstrip(os.sep) + os.sep;
    for name in candidates {
        full = os.path.normpath(prefix + name);
        if full.startswith(prefix) and os.path.exists(full) {
            if os.path.isdir(full) {
                continue;
            }
            st = os.stat(full);
            return StaticFile(path=full, name=name, size=st.st_size, mtime=st.st_mtime);
        }
    }
    return None;
}

impl App.handle(req: Request) -> Response {
    with self.lock {
        return self.dispatch(req);
    }
}

impl App.dispatch(req: Request) -> Response {
    method = req.method;
    q = req.url.find("?");
    pathname = req.url[:q] if q >= 0 else req.url;
    headers: list[tuple[str, str]] = [("X-Powered-By", POWERED_BY)];
    for top in self.static_roots {
        f = self.static_lookup(top, pathname);
        if f is not None {
            return serve_static(req, f, headers, self.production);
        }
    }
    headers.append(("Access-Control-Allow-Origin", "*"));
    headers.append(("Access-Control-Allow-Methods", "GET, HEAD, PUT, PATCH, POST, DELETE"));
    if "access-control-request-headers" in req.headers {
        for h in req.headers["access-control-request-headers"].split(",") {
            headers.append(("Access-Control-Allow-Headers", h.strip()));
        }
    } else {
        headers.append(("Access-Control-Allow-Headers", "content-type"));
    }
    if method == "OPTIONS" {
        headers.append(("Content-Length", "0"));
        return Response(status=204, headers=headers, send_length=False);
    }
    body: any = UNDEFINED;
    if method in ["POST", "PUT", "PATCH", "DELETE"] {
        if len(req.body) > PAYLOAD_LIMIT {
            return text_error(
                500,
                f"Payload too large. Limit: {PAYLOAD_LIMIT} bytes",
                headers,
                self.production,
                method,
            );
        }
        try {
            body = {} if len(req.body) == 0 else parse_json(req.body.decode("utf-8", "replace"));
        } except JsSyntaxError as e {
            return text_error(500, str(e), headers, self.production, method);
        }
    }
    verb = "GET" if method == "HEAD" else method;
    if verb == "GET" and pathname == "/" {
        page = render_index(snapshot()).encode("utf-8");
        tag = etag_of(page);
        out = list(headers);
        out.append(("Content-Type", "text/html; charset=utf-8"));
        out.append(("etag", tag));
        if is_fresh(req, tag) {
            return Response(
                status=304, headers=[h for h in out if h[0] != "Content-Type"], send_length=False
            );
        }
        if method == "HEAD" {
            return Response(status=200, headers=out, send_length=False);
        }
        return Response(status=200, headers=out, body=page);
    }
    one = ONE_SEGMENT.match(pathname);
    two = TWO_SEGMENTS.match(pathname);
    prefix = PREFIX_SEGMENT.match(pathname);
    action = "";
    if verb == "GET" {
        action = "find" if one is not None else ("find_by_id" if two is not None else "");
    } elif verb == "POST" {
        action = "create" if one is not None else "";
    } elif verb == "PUT" {
        action = "update" if one is not None else ("update_by_id" if two is not None else "");
    } elif verb == "PATCH" {
        action = "patch" if one is not None else ("patch_by_id" if two is not None else "");
    } elif verb == "DELETE" {
        action = "destroy" if two is not None else "";
    }
    if prefix is None {
        return text_error(404, "Not Found", headers, False, method);
    }
    try {
        data: any = UNDEFINED;
        if action != "" {
            m = one if one is not None and action in ["find", "create", "update", "patch"] else two;
            if m is None {
                return text_error(404, "Not Found", headers, False, method);
            }
            name = decode_uri_component(m.group(1));
            id = decode_uri_component(m.group(2))
                if m.lastindex is not None and m.lastindex >= 2
                else "";
            if action in ["create", "update", "patch", "update_by_id", "patch_by_id"]
                and not isinstance(body, dict)
            {
                return json_response(400, {"error": "Body must be a JSON object"}, headers, method);
            }
            if action == "find" {
                data = find(name, list_query(req.url));
            } elif action == "find_by_id" {
                q2 = req.url.find("?");
                data = find_by_id(
                    name, id, query_object(req.url[q2 + 1:] if q2 >= 0 else "").get("_embed", None)
                );
            } elif action == "create" {
                data = create(name, body);
            } elif action == "update" {
                data = update_or_patch(name, body, False);
            } elif action == "patch" {
                data = update_or_patch(name, body, True);
            } elif action == "update_by_id" {
                data = update_or_patch_by_id(name, id, body, False);
            } elif action == "patch_by_id" {
                data = update_or_patch_by_id(name, id, body, True);
            } elif action == "destroy" {
                q3 = req.url.find("?");
                data = destroy_by_id(
                    name,
                    id,
                    query_object(req.url[q3 + 1:] if q3 >= 0 else "").get("_dependent", None),
                );
            }
            if action not in ["find", "find_by_id"] and not is_undefined(data) {
                self.db.write();
            }
        } else {
            decode_uri_component(prefix.group(1));
        }
        if is_undefined(data) {
            return json_response(404, {"error": "Not Found"}, headers, method);
        }
        return json_response(201 if method == "POST" else 200, data, headers, method);
    } except URIError {
        return send_status(400, "Bad Request", headers, method);
    } except Exception as e {
        return text_error(500, str(e), headers, self.production, method);
    }
}
