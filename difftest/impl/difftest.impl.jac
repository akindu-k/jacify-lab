impl Side.send(method: str, path: str, headers: dict[str, str], body: bytes | None) -> Reply {
    conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=10.0);
    conn.putrequest(method, path, skip_accept_encoding=True);
    for (k, v) in headers.items() {
        conn.putheader(k, v);
    }
    if body is not None {
        conn.putheader("Content-Length", str(len(body)));
    }
    conn.endheaders();
    if body is not None {
        conn.send(body);
    }
    resp: HTTPResponse = conn.getresponse();
    raw = resp.read();
    hs: list[tuple[str, str]] = [(k.lower(), v) for (k, v) in resp.getheaders()];
    conn.close();
    text = raw.decode("utf-8", "replace");
    reply = Reply(status=resp.status, headers=hs, body=text);
    if resp.status == 201 {
        try {
            made: dict[str, any] = json.loads(text);
            self.created.append(str(made["id"]));
        } except Exception {}
    }
    return reply;
}

impl Side.fill(text: str) -> str {
    out = text;
    for (i, id) in enumerate(self.created) {
        out = out.replace("{{created:" + str(i) + "}}", id);
    }
    return out;
}

impl Side.mask(text: str) -> str {
    out = text;
    for (i, id) in enumerate(self.created) {
        out = out.replace(id, "<ID:" + str(i) + ">");
    }
    return RANDOM_ID.sub(r'\g<1>"<RID>"', out);
}

impl header_view(r: Reply) -> list[tuple[str, str]] {
    return [(k, v) for (k, v) in r.headers if k not in IGNORED];
}

impl compare(index: int, spec: dict[str, any], a: Reply, b: Reply, sa: Side, sb: Side) -> list[str] {
    problems: list[str] = [];
    label = f"#{index} {spec['method']} {spec['path']}";
    if a.status != b.status {
        problems.append(f"{label}: status {a.status} (original) vs {b.status} (port)");
    }
    ha = header_view(a);
    hb = header_view(b);
    if [(k, sa.mask(v)) for (k, v) in ha] != [(k, sb.mask(v)) for (k, v) in hb] {
        problems.append(f"{label}: headers\n    original: {ha}\n    port:     {hb}");
    }
    la = [v for (k, v) in a.headers if k == "content-length"];
    lb = [v for (k, v) in b.headers if k == "content-length"];
    if la and lb and la != lb and sa.mask(a.body) == a.body and sb.mask(b.body) == b.body {
        problems.append(f"{label}: content-length {la} vs {lb}");
    }
    if sa.mask(a.body) != sb.mask(b.body) {
        problems.append(f"{label}: body\n    original: {a.body[:600]!r}\n    port:     {b.body[:600]!r}");
    }
    return problems;
}

impl run(scenario_path: str, port_a: int, port_b: int) -> int {
    with open(scenario_path, encoding="utf-8") as f {
        scenario: dict[str, any] = json.loads(f.read());
    }
    sa = Side(port=port_a);
    sb = Side(port=port_b);
    problems: list[str] = [];
    count = 0;
    for (i, spec) in enumerate(scenario["requests"]) {
        headers: dict[str, str] = spec.get("headers", {});
        raw_body: any = spec.get("body", None);
        body_a: bytes | None = None;
        body_b: bytes | None = None;
        if raw_body is not None {
            text = raw_body if isinstance(raw_body, str) else json.dumps(raw_body);
            if "repeat" in spec {
                text = text * int(spec["repeat"]);
            }
            body_a = sa.fill(text).encode("utf-8");
            body_b = sb.fill(text).encode("utf-8");
        }
        a = sa.send(spec["method"], sa.fill(spec["path"]), headers, body_a);
        b = sb.send(spec["method"], sb.fill(spec["path"]), headers, body_b);
        count += 1;
        problems.extend(compare(i, spec, a, b, sa, sb));
    }
    for p in problems {
        print("MISMATCH " + p);
    }
    print(f"{scenario_path}: {count} requests, {count - len(set([p.split(':')[0] for p in problems]))} identical, {len(set([p.split(':')[0] for p in problems]))} differ");
    with open(scenario_path + ".ids", "w") as out {
        out.write(json.dumps({"original": sa.created, "port": sb.created}));
    }
    return 0 if not problems else 1;
}
