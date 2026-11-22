import from "node:console" { default as console }

def clampPage(page: float, pages: float) -> float {
    if page < 1.0 {
        return 1.0;
    }
    if page > pages {
        return pages;
    }
    return page;
}

def countPrefix(xs: list[str], prefix: str) -> float {
    n: float = 0.0;
    for x in xs {
        if x == prefix {
            n += 1.0;
        }
    }
    return n;
}

with entry {
    console.log(clampPage(9.0, 3.0), clampPage(0.0, 3.0), countPrefix(["ab", "ac", "b"], "a"));
}
