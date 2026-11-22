import math;

impl entries(value: any) -> list[tuple[str, any]] {
    out: list[tuple[str, any]] = [];
    if isinstance(value, dict) {
        for k in js_keys(value) {
            out.append((k, value[k]));
        }
    } elif isinstance(value, list) {
        for (i, x) in enumerate(value) {
            if not is_undefined(x) {
                out.append((str(i), x));
            }
        }
    } elif isinstance(value, str) {
        for (i, ch) in enumerate(value) {
            out.append((str(i), ch));
        }
    }
    return out;
}

impl known_operators(value: any) -> list[str] {
    if not isinstance(value, dict) {
        return [];
    }
    return [op for op in WHERE_OPERATORS if op in value];
}

impl field_of(target: any, key: str) -> any {
    if isinstance(target, dict) {
        return target[key] if key in target else UNDEFINED;
    }
    if isinstance(target, list) or isinstance(target, str) {
        if key == "length" {
            return len(target);
        }
        if key.isdigit() and (key == "0" or not key.startswith("0")) and int(key) < len(target) {
            return target[int(key)];
        }
    }
    return UNDEFINED;
}

impl matches_where(target: any, where: any) -> bool {
    for (key, value) in entries(where) {
        if key == "or" {
            if not isinstance(value, list) or len(value) == 0 {
                return False;
            }
            matched = False;
            for sub in value {
                if isinstance(sub, dict) and matches_where(target, sub) {
                    matched = True;
                    break;
                }
            }
            if not matched {
                return False;
            }
            continue;
        }
        field = field_of(target, key);
        if isinstance(value, dict) {
            ops = known_operators(value);
            if len(ops) > 0 {
                if is_undefined(field) {
                    return False;
                }
                if "lt" in ops and not js_lt(field, value["lt"]) {
                    return False;
                }
                if "lte" in ops and not js_lte(field, value["lte"]) {
                    return False;
                }
                if "gt" in ops and not js_gt(field, value["gt"]) {
                    return False;
                }
                if "gte" in ops and not js_gte(field, value["gte"]) {
                    return False;
                }
                if "eq" in ops and not js_strict_equals(field, value["eq"]) {
                    return False;
                }
                if "ne" in ops and js_strict_equals(field, value["ne"]) {
                    return False;
                }
                if "in" in ops {
                    candidates: list[any] = value["in"]
                        if isinstance(value["in"], list)
                        else [value["in"]];
                    if not any([js_strict_equals(field, c) for c in candidates]) {
                        return False;
                    }
                }
                if "contains" in ops {
                    if not isinstance(field, str) {
                        return False;
                    }
                    if js_to_string(value["contains"]).lower() not in field.lower() {
                        return False;
                    }
                }
                if "startsWith" in ops {
                    if not isinstance(field, str) {
                        return False;
                    }
                    if not field.lower().startswith(js_to_string(value["startsWith"]).lower()) {
                        return False;
                    }
                }
                if "endsWith" in ops {
                    if not isinstance(field, str) {
                        return False;
                    }
                    if not field.lower().endswith(js_to_string(value["endsWith"]).lower()) {
                        return False;
                    }
                }
                continue;
            }
            if isinstance(field, dict) {
                if not matches_where(field, value) {
                    return False;
                }
            }
            continue;
        }
        return False;
    }
    return True;
}

impl paginate(items: list[any], page: float, per_page: float) -> Page {
    total = len(items);
    safe_per_page = per_page - per_page % 1.0
        if math.isfinite(per_page) and per_page > 0.0
        else 1.0;
    ratio = float(total) / safe_per_page;
    pages = max(1.0, ratio + (1.0 - ratio % 1.0) % 1.0);
    safe_page = page - page % 1.0 if math.isfinite(page) else 1.0;
    current = max(1.0, min(safe_page, pages));
    pages_n = int(pages);
    current_n = int(current);
    start = (current - 1.0) * safe_per_page;
    end = start + safe_per_page;
    lo = int(min(start, float(total)));
    hi = int(min(end, float(total)));
    return Page(
        first=1,
        prev=current_n - 1 if current_n > 1 else None,
        next=current_n + 1 if current_n < pages_n else None,
        last=pages_n,
        pages=pages_n,
        items=total,
        data=items[lo:hi],
    );
}

impl page_json(p: Page) -> dict[str, any] {
    return {
        "first": p.first,
        "prev": p.prev,
        "next": p.next,
        "last": p.last,
        "pages": p.pages,
        "items": p.items,
        "data": p.data,
    };
}
