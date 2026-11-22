test "matchesWhere matches upstream matches-where.test.ts" {
    target: dict[str, any] = {"a": 10, "b": 20, "c": "x", "nested": {"a": 10, "b": 20}};
    cases: list[tuple[dict[str, any], bool]] = [
        ({"a": {"eq": 10}}, True),
        ({"a": {"eq": 11}}, False),
        ({"c": {"ne": "y"}}, True),
        ({"c": {"ne": "x"}}, False),
        ({"a": {"lt": 11}}, True),
        ({"a": {"lt": 10}}, False),
        ({"a": {"lte": 10}}, True),
        ({"a": {"lte": 9}}, False),
        ({"b": {"gt": 19}}, True),
        ({"b": {"gt": 20}}, False),
        ({"b": {"gte": 20}}, True),
        ({"b": {"gte": 21}}, False),
        ({"a": {"gt": 0}, "b": {"lt": 30}}, True),
        ({"a": {"gt": 10}, "b": {"lt": 30}}, False),
        ({"or": [{"a": {"lt": 0}}, {"b": {"gt": 19}}]}, True),
        ({"or": [{"a": {"lt": 0}}, {"b": {"gt": 20}}]}, False),
        ({"nested": {"a": {"eq": 10}}}, True),
        ({"nested": {"b": {"lt": 20}}}, False),
        ({"a": {"in": [10, 11]}}, True),
        ({"a": {"in": [1, 2]}}, False),
        ({"c": {"in": ["x", "y"]}}, True),
        ({"c": {"in": ["y", "z"]}}, False),
        ({"a": {"in": [10, 11], "gt": 9}}, True),
        ({"a": {"in": [10, 11], "gt": 10}}, False),
        ({"a": {"foo": 10}}, True),
        ({"a": {"foo": 10, "eq": 10}}, True),
        ({"missing": {"foo": 1}}, True),
        ({"c": {"contains": "x"}}, True),
        ({"c": {"contains": "X"}}, True),
        ({"c": {"contains": "z"}}, False),
        ({"a": {"contains": "1"}}, False),
        ({"c": {"contains": 1}}, False),
        ({"c": {"startsWith": "x"}}, True),
        ({"c": {"startsWith": "X"}}, True),
        ({"c": {"startsWith": "z"}}, False),
        ({"a": {"startsWith": "1"}}, False),
        ({"c": {"startsWith": 1}}, False),
        ({"c": {"endsWith": "x"}}, True),
        ({"c": {"endsWith": "X"}}, True),
        ({"c": {"endsWith": "z"}}, False),
        ({"a": {"endsWith": "1"}}, False),
        ({"c": {"endsWith": 1}}, False),
    ];
    for (where, want) in cases {
        assert matches_where(target, where) == want, f"matchesWhere({where!r}) should be {want}";
    }
}

test "JS loose comparison: bools are not numbers, strings compare numerically to numbers" {
    assert not matches_where({"p": True}, {"p": {"eq": 1}});
    assert matches_where({"v": "10"}, {"v": {"gt": 9}});
    assert not matches_where({"v": "abc"}, {"v": {"lt": 5}});
    assert not matches_where({"v": "abc"}, {"v": {"gte": 5}});
    assert not matches_where({"t": "x"}, {"t": "x"});
}

test "paginate matches upstream paginate.test.ts" {
    cases: list[tuple[list[any], float, float, dict[str, any]]] = [
        (
            [1, 2, 3, 4, 5],
            1.0,
            2.0,
            {
                "first": 1,
                "prev": None,
                "next": 2,
                "last": 3,
                "pages": 3,
                "items": 5,
                "data": [1, 2],
            },
        ),
        (
            [1, 2, 3, 4, 5],
            2.0,
            2.0,
            {"first": 1, "prev": 1, "next": 3, "last": 3, "pages": 3, "items": 5, "data": [3, 4]},
        ),
        (
            [1, 2, 3, 4, 5],
            9.0,
            2.0,
            {"first": 1, "prev": 2, "next": None, "last": 3, "pages": 3, "items": 5, "data": [5]},
        ),
        (
            [1, 2, 3],
            0.0,
            2.0,
            {
                "first": 1,
                "prev": None,
                "next": 2,
                "last": 2,
                "pages": 2,
                "items": 3,
                "data": [1, 2],
            },
        ),
        (
            [],
            1.0,
            2.0,
            {"first": 1, "prev": None, "next": None, "last": 1, "pages": 1, "items": 0, "data": []},
        ),
        (
            [1, 2, 3],
            1.0,
            0.0,
            {"first": 1, "prev": None, "next": 2, "last": 3, "pages": 3, "items": 3, "data": [1]},
        ),
        (
            [1, 2, 3],
            1.0,
            1e300,
            {
                "first": 1,
                "prev": None,
                "next": None,
                "last": 1,
                "pages": 1,
                "items": 3,
                "data": [1, 2, 3],
            },
        ),
        (
            [1, 2, 3],
            -7.5,
            2.0,
            {
                "first": 1,
                "prev": None,
                "next": 2,
                "last": 2,
                "pages": 2,
                "items": 3,
                "data": [1, 2],
            },
        ),
    ];
    for (items, page, per, want) in cases {
        got = page_json(paginate(items, page, per));
        assert got == want, f"paginate({items!r}, {page}, {per}) gave {got!r}";
    }
}
