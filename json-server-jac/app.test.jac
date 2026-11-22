import os;
import json;
import tempfile;
import from store { load }
import from db { DataFile, Database }

def fresh_app -> App {
    load({
        "posts": [{"id": "1", "title": "foo"}],
        "comments": [{"id": "1", "postId": "1"}],
        "object": {"f1": "foo"},
    });
    folder = tempfile.mkdtemp();
    with open(os.path.join(folder, "file.html"), "w") as f {
        f.write("utf-8");
    }
    return App(
        db=Database(file=DataFile(path=os.path.join(folder, "db.json"))), static_roots=[folder]
    );
}

def call(app: App, method: str, url: str, body: str = "") -> Response {
    return app.handle(Request(method=method, url=url, body=body.encode("utf-8")));
}

test "status codes match upstream app.test.ts" {
    app = fresh_app();
    cases: list[tuple[str, str, int]] = [
        ("GET", "/", 200),
        ("GET", "/file.html", 200),
        ("OPTIONS", "/posts", 204),
        ("GET", "/posts", 200),
        ("GET", "/posts?_embed=comments", 200),
        ("GET", "/posts/1", 200),
        ("GET", "/posts/-1", 404),
        ("GET", "/posts/1?_embed=comments", 200),
        ("GET", "/comments", 200),
        ("GET", "/comments?postId=1", 200),
        ("GET", "/object", 200),
        ("GET", "/object/1", 404),
        ("GET", "/not-found", 404),
        ("POST", "/posts", 201),
        ("POST", "/posts/1", 404),
        ("POST", "/posts/-1", 404),
        ("POST", "/object", 404),
        ("POST", "/object/1", 404),
        ("POST", "/not-found", 404),
        ("PUT", "/posts", 404),
        ("PUT", "/posts/1", 200),
        ("PUT", "/object", 200),
        ("PUT", "/object/1", 404),
        ("PUT", "/posts/-1", 404),
        ("PUT", "/not-found", 404),
        ("PATCH", "/posts", 404),
        ("PATCH", "/posts/1", 200),
        ("PATCH", "/object", 200),
        ("PATCH", "/object/1", 404),
        ("PATCH", "/posts/-1", 404),
        ("PATCH", "/not-found", 404),
        ("DELETE", "/posts", 404),
        ("DELETE", "/posts/1", 200),
        ("DELETE", "/object", 404),
        ("DELETE", "/object/1", 404),
        ("DELETE", "/posts/-1", 404),
        ("DELETE", "/not-found", 404),
    ];
    for (method, url, want) in cases {
        r = call(app, method, url);
        assert r.status == want, f"{method} {url} gave {r.status}, want {want}";
        if want == 404 {
            assert json.loads(r.body.decode()) == {
                "error": "Not Found",
            }, f"{method} {url} body {r.body!r}";
        }
    }
}

test "_where takes precedence over query params, and bodies must be objects" {
    app = fresh_app();
    where = "%7B%22title%22%3A%7B%22eq%22%3A%22foo%22%7D%7D";
    for url in ["/posts?_where=" + where, "/posts?title:eq=bar&_where=" + where] {
        r = call(app, "GET", url);
        assert r.status == 200
            and json.loads(r.body.decode()) == [{"id": "1", "title": "foo"}], url;
    }
    for (method, url, body) in [
        ("POST", "/posts", '[{"title": "foo"}]'),
        ("PATCH", "/posts/1", '"hello"'),
        ("PUT", "/posts/1", "null"),
    ] {
        r = call(app, method, url, body);
        assert r.status == 400
            and json.loads(r.body.decode()) == {
                "error": "Body must be a JSON object",
            }, f"{method} {url}";
    }
}

test "malformed JSON bodies and paths answer as tinyhttp does" {
    app = fresh_app();
    r = call(app, "POST", "/posts", "{bad");
    assert r.status == 500
        and r.body
            == b"Expected property name or &#39;}&#39; in JSON at position 1 (line 1 column 2)";
    r = call(app, "GET", "/posts/%E0%A4%A");
    assert r.status == 400 and r.body == b"Bad Request";
    r = call(app, "PUT", "/", "{}");
    assert r.status == 404 and r.body == b"Not Found";
}
