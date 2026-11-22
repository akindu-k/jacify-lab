impl NullifyForeignKey.start with Root entry {
    visit [-->];
}

impl NullifyForeignKey.at_collection with Collection entry {
    if here.name == self.source {
        return;
    }
    for r in [here ->:Holds:->] {
        if self.key in r.fields and js_strict_equals(r.fields[self.key], self.target_id) {
            r.fields[self.key] = None;
        }
    }
}

impl DeleteDependents.start with Root entry {
    visit [-->];
}

impl DeleteDependents.at_collection with Collection entry {
    if here.name == self.source or here.name not in self.dependents {
        return;
    }
    doomed = [r for r in [here ->:Holds:->] if self.key in r.fields and r.fields[self.key] is None];
    for r in doomed {
        del r;
    }
}

impl random_id -> str {
    return base64.urlsafe_b64encode(secrets.token_bytes(8)).decode("ascii").rstrip("=");
}

impl ensure_array(arg: any) -> list[any] {
    if arg is None or is_undefined(arg) {
        return [];
    }
    if isinstance(arg, list) {
        return arg;
    }
    return [arg];
}

impl resource(called: str) -> Resource | None {
    for r in [root --> [?:Resource]] {
        if r.name == called {
            return r;
        }
    }
    return None;
}

impl records(c: Collection) -> list[Record] {
    return [c ->:Holds:->];
}

impl record_by_id(c: Collection, id: str) -> Record | None {
    for r in [c ->:Holds:->] {
        if "id" in r.fields and js_strict_equals(r.fields["id"], id) {
            return r;
        }
    }
    return None;
}

impl value_of(called: str) -> any {
    r = resource(called);
    if r is None {
        return UNDEFINED;
    }
    if isinstance(r, Collection) {
        return [rec.fields for rec in [r ->:Holds:->]];
    }
    if isinstance(r, Singleton) {
        return r.value;
    }
    return UNDEFINED;
}

impl load(data: dict[str, any]) {
    for r in [root --> [?:Resource]] {
        del r;
    }
    for name in js_keys(data) {
        value = data[name];
        if isinstance(value, list) {
            c = root ++> Collection(name=name);
            for item in value {
                c +>:Holds:+> Record(fields=item);
            }
        } else {
            root ++> Singleton(name=name, value=value);
        }
    }
}

impl snapshot -> dict[str, any] {
    out: dict[str, any] = {};
    for r in [root --> [?:Resource]] {
        out[r.name] = value_of(r.name);
    }
    return out;
}

impl resource_names -> list[str] {
    return [r.name for r in [root --> [?:Resource]]];
}

impl embed(called: str, item: any, related: any) -> any {
    rel = related if isinstance(related, str) else str(related);
    if singularize(rel) == rel {
        related_data = value_of(pluralize(rel));
        if not js_truthy(related_data) {
            return item;
        }
        if not isinstance(related_data, list) {
            raise JsTypeError("relatedData.find is not a function");
        }
        key = rel + "Id";
        wanted: any = item[key] if isinstance(item, dict) and key in item else UNDEFINED;
        found: any = UNDEFINED;
        for candidate in related_data {
            cid: any = candidate["id"]
                if isinstance(candidate, dict) and "id" in candidate
                else UNDEFINED;
            if js_strict_equals(cid, wanted) {
                found = candidate;
                break;
            }
        }
        out = js_spread(item);
        out[rel] = found;
        return out;
    }
    related_data = value_of(rel);
    if not js_truthy(related_data) {
        return item;
    }
    if not isinstance(related_data, list) {
        raise JsTypeError("relatedData.filter is not a function");
    }
    key = singularize(called) + "Id";
    own_id: any = item["id"] if isinstance(item, dict) and "id" in item else UNDEFINED;
    matches: list[any] = [];
    for candidate in related_data {
        fk: any = candidate[key] if isinstance(candidate, dict) and key in candidate else UNDEFINED;
        if js_strict_equals(fk, own_id) {
            matches.append(candidate);
        }
    }
    out = js_spread(item);
    out[rel] = matches;
    return out;
}

impl sort_on(items: list[any], props: list[str]) -> list[any] {
    parsed: dict[str, list[any]] = {};
    def compare(a: any, b: any) -> int {
        for element in props {
            desc = element.startswith("-");
            path = element[1:] if desc else element;
            if path not in parsed {
                parsed[path] = parse_path(path);
            }
            x = get_property_parts(a, parsed[path]);
            y = get_property_parts(b, parsed[path]);
            if js_strict_equals(x, y) {
                continue;
            }
            if not (is_number(y) and y == 0) and not js_truthy(y) {
                return 1 if desc else -1;
            }
            if not (is_number(x) and x == 0) and not js_truthy(x) {
                return -1 if desc else 1;
            }
            if isinstance(x, str) and isinstance(y, str) {
                r = locale_compare(y, x) if desc else locale_compare(x, y);
                if r != 0 {
                    return r;
                }
                continue;
            }
            lt = js_lt(x, y);
            if desc {
                return 1 if lt else -1;
            }
            return -1 if lt else 1;
        }
        return 0;
    }
    return v8_sort(items, compare);
}

impl find(called: str, q: ListQuery) -> any {
    r = resource(called);
    if r is None {
        return UNDEFINED;
    }
    if isinstance(r, Singleton) {
        return r.value;
    }
    results: list[any] = value_of(called);
    for related in ensure_array(q.embed) {
        results = [embed(called, item, related) for item in results];
    }
    results = [item for item in results if matches_where(item, q.where)];
    if q.sort is not None and q.sort != "" {
        results = sort_on(results, q.sort.split(","));
    }
    if q.page is not None {
        return page_json(paginate(results, q.page, q.per_page if q.per_page is not None else 10.0));
    }
    return results;
}

impl find_by_id(called: str, id: str, embeds: any) -> any {
    r = resource(called);
    if not isinstance(r, Collection) {
        return UNDEFINED;
    }
    rec = record_by_id(r, id);
    if rec is None {
        return UNDEFINED;
    }
    item: any = rec.fields;
    for related in ensure_array(embeds) {
        item = embed(called, item, related);
    }
    return item;
}

impl create(called: str, body: dict[str, any]) -> any {
    r = resource(called);
    if not isinstance(r, Collection) {
        return UNDEFINED;
    }
    item = js_spread(body);
    item["id"] = random_id();
    r +>:Holds:+> Record(fields=item);
    return item;
}

impl update_or_patch(called: str, body: dict[str, any], is_patch: bool) -> any {
    r = resource(called);
    if not isinstance(r, Singleton) {
        return UNDEFINED;
    }
    if is_patch {
        merged = js_spread(r.value);
        for (k, v) in body.items() {
            merged[k] = v;
        }
        r.value = merged;
        return merged;
    }
    r.value = body;
    return body;
}

impl update_or_patch_by_id(called: str, id: str, body: dict[str, any], is_patch: bool) -> any {
    r = resource(called);
    if not isinstance(r, Collection) {
        return UNDEFINED;
    }
    rec = record_by_id(r, id);
    if rec is None {
        return UNDEFINED;
    }
    next_item: dict[str, any] = js_spread(rec.fields) if is_patch else {};
    for (k, v) in body.items() {
        next_item[k] = v;
    }
    next_item["id"] = id;
    rec.fields = next_item;
    return next_item;
}

impl destroy_by_id(called: str, id: str, dependent: any) -> any {
    r = resource(called);
    if not isinstance(r, Collection) {
        return UNDEFINED;
    }
    rec = record_by_id(r, id);
    if rec is None {
        return UNDEFINED;
    }
    item = rec.fields;
    del rec;
    key = singularize(called) + "Id";
    root spawn NullifyForeignKey(source=called, target_id=id, key=key);
    root spawn DeleteDependents(
        source=called, dependents=[str(d) for d in ensure_array(dependent)], key=key
    );
    return item;
}
