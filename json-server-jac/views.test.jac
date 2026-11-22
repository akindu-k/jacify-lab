test "the index page is byte-identical to the original's eta rendering" {
    with open("testdata/index_fixture.html") as f {
        want = f.read();
        got = render_index({
            "posts": [{}, {}],
            "comments": [{}, {}],
            "profile": {"name": "typicode"},
        });
        assert got == want, "fixture rendering differs";
    }
    with open("testdata/index_empty.html") as f {
        assert render_index({}) == f.read(), "empty rendering differs";
    }
}
