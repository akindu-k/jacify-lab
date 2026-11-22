impl DataFile.read -> any {
    text = "";
    try {
        with open(self.path, encoding="utf-8", errors="replace") as f {
            text = f.read();
        }
    } except FileNotFoundError {
        return None;
    }
    if self.is_json5 {
        return json5_parse(text);
    }
    return parse_json(text);
}

impl DataFile.write(data: dict[str, any]) {
    text = json5_stringify(data) if self.is_json5 else stringify(data, 2);
    folder = os.path.dirname(self.path);
    temp = os.path.join(folder, "." + os.path.basename(self.path) + ".tmp");
    with open(temp, "w", encoding="utf-8") as f {
        f.write(text);
    }
    os.replace(temp, self.path);
}

impl describe_primitive(v: any) -> str {
    if isinstance(v, bool) {
        return "boolean '" + ("true" if v else "false") + "'";
    }
    if is_number(v) {
        return "number '" + js_number_text(v) + "'";
    }
    return "string '" + str(v) + "'";
}

impl normalize(data: any) -> any {
    if not isinstance(data, dict) {
        return data;
    }
    if "$schema" in data {
        del data["$schema"];
    }
    for value in data.values() {
        if not isinstance(value, list) {
            continue;
        }
        for item in value {
            if item is None {
                raise JsTypeError("Cannot read properties of null (reading 'id')");
            }
            if isinstance(item, list) {
                raise UnsupportedData(
                    "json-server-jac: an array directly inside a collection is not supported"
                );
            }
            if not isinstance(item, dict) {
                raise JsTypeError("Cannot create property 'id' on " + describe_primitive(item));
            }
            if "id" in item and is_number(item["id"]) {
                item["id"] = js_number_text(item["id"]);
            }
            if "id" not in item {
                item["id"] = random_id();
            }
        }
    }
    return data;
}

impl with_schema(data: dict[str, any]) -> dict[str, any] {
    out: dict[str, any] = {};
    for (k, v) in data.items() {
        out[k] = v;
    }
    out["$schema"] = DEFAULT_SCHEMA_PATH;
    return out;
}

impl Database.read -> any {
    raw = self.file.read();
    data = normalize(raw);
    if js_truthy(data) {
        if not isinstance(data, dict) {
            raise UnsupportedData(
                "json-server-jac: the database file must hold a JSON object at its top level"
            );
        }
        load(data);
    }
    return data;
}

impl Database.write {
    self.writing = True;
    try {
        self.file.write(with_schema(snapshot()));
        st = os.stat(self.file.path);
        self.last_write = (st.st_mtime, st.st_size);
    } finally {
        self.writing = False;
    }
}
