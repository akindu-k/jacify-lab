import http.server;
import http.client;
import threading;
import json;
import re;
import base64;
import os;

node Collection {
    has name: str;
}

node Record {
    has fields: dict[str, any];
}

edge Holds: Collection --> Record {}

class Handler(http.server.BaseHTTPRequestHandler) {
    def do_GET -> None {
        body = json.dumps({"path": self.path}).encode();
        self.send_response(200);
        self.send_header("Content-Type", "application/json");
        self.send_header("Content-Length", str(len(body)));
        self.end_headers();
        self.wfile.write(body);
    }

    override def log_message(format: str, *args: any) -> None {}
}

with entry {
    c = root ++> Collection(name="posts");
    for i in range(3) {
        c +>:Holds:+> Record(fields={"id": str(i), "n": i});
    }
    recs = [c ->:Holds:->];
    del recs[1];
    print([r.fields["id"] for r in [c ->:Holds:->]]);
    victim = [c ->:Holds:->][0];
    del victim;
    print([r.fields["id"] for r in [c ->:Holds:->]]);
    print(base64.urlsafe_b64encode(os.urandom(8)).rstrip(b"=").decode(), re.sub(r"(x|ch)$", r"\g<1>es", "box"));
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler);
    t = threading.Thread(target=srv.serve_forever, args=(0.01,));
    t.start();
    conn = http.client.HTTPConnection("127.0.0.1", srv.server_port, timeout=5.0);
    conn.request("GET", "/posts?x=1");
    print(conn.getresponse().read());
    srv.shutdown();
    t.join();
}
