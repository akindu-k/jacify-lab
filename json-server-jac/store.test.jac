import from jsvalue { UNDEFINED, is_undefined, stringify, json_parse }

glob POST1: dict[str, any] = {
    "id": "1",
    "title": "a",
    "views": 100,
    "published": True,
    "author": {"name": "foo"},
    "tags": ["foo", "bar"],
};

glob POST2: dict[str, any] = {
    "id": "2",
    "title": "b",
    "views": 200,
    "published": False,
    "author": {"name": "bar"},
    "tags": ["bar"],
};

glob POST3: dict[str, any] = {
    "id": "3",
    "title": "c",
    "views": 300,
    "published": False,
    "author": {"name": "baz"},
    "tags": ["foo"],
};

glob COMMENT1: dict[str, any] = {"id": "1", "title": "a", "postId": "1"};

def fresh {
    load({
        "posts": [dict(POST1), dict(POST2), dict(POST3)],
        "comments": [dict(COMMENT1)],
        "object": {"f1": "foo"},
    });
}

def same(got: any, want: any) -> bool {
    if is_undefined(want) {
        return is_undefined(got);
    }
    return stringify(got) == stringify(want);
}

test "findById matches upstream service.test.ts" {
    fresh();
    with_comments = dict(POST1);
    with_comments["comments"] = [COMMENT1];
    with_post = dict(COMMENT1);
    with_post["post"] = POST1;
    cases: list[tuple[str, str, any, any]] = [
        ("posts", "1", None, POST1),
        ("posts", "xxx", None, UNDEFINED),
        ("posts", "1", ["comments"], with_comments),
        ("comments", "1", ["post"], with_post),
        ("xxx", "1", None, UNDEFINED),
    ];
    for (name, id, embeds, want) in cases {
        got = find_by_id(name, id, embeds);
        assert same(got, want), f"findById({name}, {id}, {embeds!r}) gave {got!r}";
    }
}

test "find matches upstream service.test.ts" {
    fresh();
    cases: list[tuple[ListQuery, any]] = [
        (ListQuery(where={"title": {"eq": "b"}}), [POST2]),
        (ListQuery(where={"author": {"name": {"eq": "bar"}}}), [POST2]),
        (ListQuery(where={}, sort="-views"), [POST3, POST2, POST1]),
        (
            ListQuery(where={}, page=2.0, per_page=2.0),
            {
                "first": 1,
                "prev": 1,
                "next": None,
                "last": 2,
                "pages": 2,
                "items": 3,
                "data": [POST3],
            },
        ),
    ];
    for (q, want) in cases {
        got = find("posts", q);
        assert same(got, want), f"find gave {got!r}";
    }
}

test "create gives a fresh string id and ignores unknown resources" {
    fresh();
    made = create("posts", {"title": "new post"});
    assert made["title"] == "new post";
    assert isinstance(made["id"], str) and len(made["id"]) == 11;
    other = create("posts", {"title": "new post", "id": "foo"});
    assert other["id"] != "foo";
    assert is_undefined(create("xxx", {"title": "x"}));
    assert len(find("posts", ListQuery(where={}))) == 5;
}

test "update and patch work on objects only" {
    fresh();
    replacement: dict[str, any] = {"f1": "bar"};
    assert update_or_patch("object", replacement, False) is replacement;
    assert is_undefined(update_or_patch("xxx", replacement, False));
    assert is_undefined(update_or_patch("posts", {}, False));
    fresh();
    assert same(update_or_patch("object", {"f2": "bar"}, True), {"f1": "foo", "f2": "bar"});
    assert is_undefined(update_or_patch("xxx", {"f2": "bar"}, True));
    assert is_undefined(update_or_patch("posts", {}, True));
}

test "updateById and patchById keep the id" {
    for is_patch in [False, True] {
        fresh();
        got = update_or_patch_by_id("posts", "1", {"id": "xxx", "title": "updated post"}, is_patch);
        assert got["id"] == "1" and got["title"] == "updated post";
        assert ("views" in got) == is_patch;
        assert is_undefined(update_or_patch_by_id("xxx", "1", {"title": "t"}, is_patch));
        assert is_undefined(update_or_patch_by_id("posts", "xxx", {"title": "t"}, is_patch));
    }
}

test "destroy nullifies foreign keys, deletes dependents, ignores unknowns" {
    fresh();
    destroy_by_id("posts", "1", None);
    assert len(find("posts", ListQuery(where={}))) == 2;
    nulled = dict(COMMENT1);
    nulled["postId"] = None;
    assert same(find("comments", ListQuery(where={})), [nulled]);
    fresh();
    destroy_by_id("posts", "1", ["comments"]);
    assert len(find("posts", ListQuery(where={}))) == 2;
    assert len(find("comments", ListQuery(where={}))) == 0;
    assert is_undefined(destroy_by_id("xxx", "1", None));
    assert is_undefined(destroy_by_id("posts", "xxx", None));
}

test "sort uses ICU order for strings and puts falsy values last" {
    load({
        "t": [
            {"id": "1", "n": "b"},
            {"id": "2", "n": "B"},
            {"id": "3", "n": "a"},
            {"id": "4", "n": None},
            {"id": "5", "n": "A"},
        ],
    });
    got = find("t", ListQuery(where={}, sort="n"));
    assert [x["id"] for x in got] == ["3", "5", "1", "2", "4"], f"{got!r}";
    got = find("t", ListQuery(where={}, sort="-n"));
    assert [x["id"] for x in got] == ["4", "2", "1", "5", "3"], f"{got!r}";
}

test "sort_on orders exactly as the sort-on package on V8, non-transitive cases included" {
    with open("testdata/sort_oracle.json") as f {
        cases: list[any] = json_parse(f.read());
        for (n, row) in enumerate(cases) {
            got = [x["i"] for x in sort_on(row[0], row[1])];
            assert got == row[2], f"case {n} ({len(row[0])} items, {row[1]}) differs";
        }
    }
}
