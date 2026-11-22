#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; LAB="$(dirname "$HERE")"
W="$HERE/work/hb"; rm -rf "$W"; mkdir -p "$W"; echo '{"profile": {"a": 1}}' > "$W/db.json"
cd "$W"
neojac node --experimental-strip-types "$LAB/port-plain/src/bin.ts" db.json -p 4971 > o.log 2>&1 & P1=$!
"$LAB/json-server-jac/dist/json-server-jac" db.json -p 4972 > p.log 2>&1 & P2=$!
cat > hello.jac <<'JAC'
import http.server;
import threading;
import sys;
import from http.server { ThreadingHTTPServer }

class H(http.server.BaseHTTPRequestHandler) {
    has protocol_version: str = "HTTP/1.1";

    def do_GET {
        self.send_response_only(200);
        self.send_header("Content-Length", "2");
        self.end_headers();
        self.wfile.write(b"ok");
    }

    override def log_message(format: str, *args: any) {}
}

with entry {
    ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever();
}
JAC
printf '[check.lint]\nselect = ["style"]\n' > jac.toml
neojac build hello.jac --release -o hello > /dev/null 2>&1; ./hello 4973 & P3=$!
neojac python -I -c "
import http.server, sys
class H(http.server.BaseHTTPRequestHandler):
    protocol_version='HTTP/1.1'
    def do_GET(self):
        self.send_response_only(200); self.send_header('Content-Length','2'); self.end_headers(); self.wfile.write(b'ok')
    def log_message(self,*a): pass
http.server.ThreadingHTTPServer(('127.0.0.1',4974),H).serve_forever()" & P4=$!
sleep 2.5
cat > client.py <<'PY'
import http.client, time, sys
port = int(sys.argv[1]); path = sys.argv[2]
for mode in ("keep-alive", "new connection each"):
    n = 500; t = time.perf_counter()
    c = http.client.HTTPConnection("127.0.0.1", port)
    for i in range(n):
        if mode != "keep-alive":
            c = http.client.HTTPConnection("127.0.0.1", port)
        c.request("GET", path); c.getresponse().read()
        if mode != "keep-alive": c.close()
    print(f"  {mode:20s} {(time.perf_counter()-t)/n*1000:.2f} ms/request")
PY
for spec in "4971 /profile original-json-server(node)" "4972 /profile json-server-jac(neojac)" "4973 / bare-http.server(neojac-native)" "4974 / bare-http.server(CPython-3.15)"; do set -- $spec; echo "$3"; neojac python -I client.py $1 $2; done
kill $P1 $P2 $P3 $P4 2>/dev/null; wait 2>/dev/null
