test "parseWhere matches upstream parse-where.test.ts" {
    cases: list[tuple[str, dict[str, any]]] = [
        ("views:gt=100&title:eq=a", {"views": {"gt": 100}, "title": {"eq": "a"}}),
        ("title=hello", {"title": {"eq": "hello"}}),
        ("author.name:lt=c&author.id:ne=2", {"author": {"name": {"lt": "c"}, "id": {"ne": 2}}}),
        ("views:gt=100&views:lt=300", {"views": {"gt": 100, "lt": 300}}),
        ("name:eq=Alice", {"name": {"eq": "Alice"}}),
        (
            "views:gt=100&published:eq=true&ratio:lt=0.5&deleted:eq=null",
            {
                "views": {"gt": 100},
                "published": {"eq": True},
                "ratio": {"lt": 0.5},
                "deleted": {"eq": None},
            },
        ),
        ("views:foo=100&title:eq=a", {"title": {"eq": "a"}}),
        ("views:foo=100", {}),
        ("views_gt=100&title_eq=a", {"views": {"gt": 100}, "title": {"eq": "a"}}),
        (
            "first_name_eq=Alice&author.first_name_ne=Bob",
            {"first_name": {"eq": "Alice"}, "author": {"first_name": {"ne": "Bob"}}},
        ),
        ("first_name=Alice", {"first_name": {"eq": "Alice"}}),
        ("views_gt=100&views:lt=300", {"views": {"gt": 100, "lt": 300}}),
        ("id:in=1,3", {"id": {"in": [1, 3]}}),
        ("title_in=hello,world", {"title": {"in": ["hello", "world"]}}),
        ("title:contains=ello", {"title": {"contains": "ello"}}),
        ("title:startsWith=hel", {"title": {"startsWith": "hel"}}),
        ("title:endsWith=rld", {"title": {"endsWith": "rld"}}),
    ];
    for (q, want) in cases {
        got = parse_where(q);
        assert got == want, f"parseWhere({q!r}) gave {got!r}, want {want!r}";
    }
}

test "query strings decode as URLSearchParams and node:querystring do" {
    assert search_params("a=1&b=x+y&c=%E2%9C%93&&d&=e&f=%zz&g=a=b") == [
        ("a", "1"),
        ("b", "x y"),
        ("c", "✓"),
        ("d", ""),
        ("", "e"),
        ("f", "%zz"),
        ("g", "a=b"),
    ];
    assert search_params("bad=%E0%A4%A") == [("bad", "�%A")];
    assert query_object("_embed=a&_embed=b&x=1") == {"_embed": ["a", "b"], "x": "1"};
}
