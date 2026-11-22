import from functools { cmp_to_key }

def falsy(v: any) -> bool {
    return v is None or v == "U" or v is False or v == 0;
}

def cmp(a: any, b: any) -> int {
    x = a[1];
    y = b[1];
    if x == y and type(x) == type(y) {
        return 0;
    }
    if not (y == 0 and type(y) == int) and falsy(y) {
        return -1;
    }
    if not (x == 0 and type(x) == int) and falsy(x) {
        return 1;
    }
    return -1 if x < y else 1;
}

with entry {
    items: list[any] = [["1", True], ["3", True], ["6", "U"], ["4", "U"], ["7", "U"], ["5", None], ["2", False]];
    print([i[0] for i in sorted(items, key=cmp_to_key(cmp))]);
}
