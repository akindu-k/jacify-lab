import from functools { cmp_to_key }

glob calls: list[str] = [];

class Undef {}

glob U: Undef = Undef();

def falsy(v: any) -> bool {
    return v is None or v is U or v is False or ((isinstance(v, int) or isinstance(v, float)) and not isinstance(v, bool) and v == 0);
}

def c(x: any, y: any) -> int {
    if x is y or (type(x) == type(y) and x == y) {
        return 0;
    }
    if not ((isinstance(y, int) or isinstance(y, float)) and not isinstance(y, bool) and y == 0) and falsy(y) {
        return -1;
    }
    if not ((isinstance(x, int) or isinstance(x, float)) and not isinstance(x, bool) and x == 0) and falsy(x) {
        return 1;
    }
    xx: any = float(x) if isinstance(x, str) and not isinstance(y, str) else x;
    yy: any = float(y) if isinstance(y, str) and not isinstance(x, str) else y;
    return -1 if xx < yy else 1;
}

def k(a: any, b: any) -> int {
    calls.append(a[0] + b[0]);
    v = c(a[1], b[1]);
    return v if v != 0 else c(a[2], b[2]);
}

with entry {
    items: list[any] = [["1", True, 100], ["2", False, 200], ["3", True, "300"], ["4", U, 50], ["5", None, 0], ["6", U, 7], ["7", U, 100]];
    print([i[0] for i in sorted(items, key=cmp_to_key(k))]);
    print(calls);
}
