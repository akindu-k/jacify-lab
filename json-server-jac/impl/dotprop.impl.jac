impl should_coerce_to_number(segment: str) -> bool {
    if segment == "0" {
        return True;
    }
    if len(segment) == 0 or segment[0] < "1" or segment[0] > "9" or len(segment) > 7 {
        return False;
    }
    for ch in segment {
        if ch < "0" or ch > "9" {
            return False;
        }
    }
    return int(segment) <= MAX_ARRAY_INDEX;
}

impl push_segment(segment: str, parts: list[any]) -> bool {
    if segment in DISALLOWED_KEYS {
        return False;
    }
    if segment != "" and should_coerce_to_number(segment) {
        parts.append(int(segment));
    } else {
        parts.append(segment);
    }
    return True;
}

impl parse_path(path: str) -> list[any] {
    parts: list[any] = [];
    current = "";
    index_segment = "";
    had_property = False;
    part = "start";
    escaping = False;
    position = 0;
    for ch in path {
        position += 1;
        if escaping {
            current += ch;
            escaping = False;
            continue;
        }
        if ch == "\\" {
            if part == "index" {
                raise ValueError(f"Invalid character '{ch}' in an index at position {position}");
            }
            if part == "indexEnd" {
                raise ValueError(f"Invalid character '{ch}' after an index at position {position}");
            }
            escaping = True;
            if part == "start" {
                part = "property";
            }
            continue;
        }
        if ch == "." {
            if part == "index" {
                raise ValueError(f"Invalid character '{ch}' in an index at position {position}");
            }
            if part == "indexEnd" {
                part = "property";
                continue;
            }
            if not push_segment(current, parts) {
                return [];
            }
            current = "";
            part = "property";
        } elif ch == "[" {
            if part == "index" {
                raise ValueError(f"Invalid character '{ch}' in an index at position {position}");
            }
            if part == "indexEnd" {
                part = "index";
                continue;
            }
            if part == "property" and current in DISALLOWED_KEYS {
                return [];
            }
            had_property = part == "property";
            part = "index";
        } elif ch == "]" {
            if part == "indexEnd" {
                raise ValueError(f"Invalid character '{ch}' after an index at position {position}");
            }
            if part != "index" {
                if part == "start" {
                    part = "property";
                }
                current += ch;
                continue;
            }
            if index_segment == "" {
                current += "[]";
                part = "property";
                continue;
            }
            if (current != "" or had_property) and not push_segment(current, parts) {
                return [];
            }
            current = "";
            had_property = False;
            if len(index_segment) <= 7
                and str(int(index_segment)) == index_segment
                and int(index_segment) <= MAX_ARRAY_INDEX
            {
                parts.append(int(index_segment));
            } else {
                parts.append(index_segment);
            }
            index_segment = "";
            part = "indexEnd";
        } else {
            if part == "index" {
                if ch < "0" or ch > "9" {
                    raise ValueError(
                        f"Invalid character '{ch}' in an index at position {position}"
                    );
                }
                index_segment += ch;
                continue;
            }
            if part == "indexEnd" {
                raise ValueError(f"Invalid character '{ch}' after an index at position {position}");
            }
            if part == "start" {
                part = "property";
            }
            current += ch;
        }
    }
    if escaping {
        current += "\\";
    }
    if part == "property" {
        if not push_segment(current, parts) {
            return [];
        }
    } elif part == "index" {
        raise ValueError("Index was not closed");
    } elif part == "start" {
        parts.append("");
    }
    return parts;
}

impl js_get(container: any, key: any) -> any {
    name = key if isinstance(key, str) else js_number_text(key);
    if isinstance(container, dict) {
        return container[name] if name in container else UNDEFINED;
    }
    if isinstance(container, list) or isinstance(container, str) {
        if name == "length" {
            return len(container);
        }
        if isinstance(key, int) and key >= 0 and key < len(container) {
            return container[key];
        }
        return UNDEFINED;
    }
    return UNDEFINED;
}

impl js_set(container: any, key: any, value: any) {
    if isinstance(container, dict) {
        container[key if isinstance(key, str) else js_number_text(key)] = value;
    } elif isinstance(container, list) and isinstance(key, int) {
        while len(container) <= key {
            container.append(UNDEFINED);
        }
        container[key] = value;
    }
}

impl get_property(target: any, path: str) -> any {
    if not (isinstance(target, dict) or isinstance(target, list)) {
        return target;
    }
    return get_property_parts(target, parse_path(path));
}

impl get_property_parts(target: any, keys: list[any]) -> any {
    if not (isinstance(target, dict) or isinstance(target, list)) {
        return target;
    }
    if len(keys) == 0 {
        return UNDEFINED;
    }
    current: any = target;
    for (i, key) in enumerate(keys) {
        current = js_get(current, key);
        if is_undefined(current) or current is None {
            if i != len(keys) - 1 {
                return UNDEFINED;
            }
            break;
        }
    }
    return current;
}

impl set_property(target: any, path: str, value: any) {
    if not (isinstance(target, dict) or isinstance(target, list)) {
        return;
    }
    keys = parse_path(path);
    current: any = target;
    for (i, key) in enumerate(keys) {
        if i == len(keys) - 1 {
            js_set(current, key, value);
            continue;
        }
        existing = js_get(current, key);
        if isinstance(existing, dict) or isinstance(existing, list) {
            current = existing;
            continue;
        }
        fresh: any = [] if isinstance(keys[i + 1], int) else {};
        js_set(current, key, fresh);
        current = fresh;
    }
}
