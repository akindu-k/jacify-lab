impl escape_html(text: str) -> str {
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace(
        '"', "&quot;"
    ).replace("'", "&#39;");
}

impl render_index(data: dict[str, any]) -> str {
    parts: list[str] = [INDEX_HEAD];
    names = js_keys(data);
    if len(names) == 0 {
        parts.append(
            "            <span class=\"empty\">No resources in db.json.</span>\n          </div>"
        );
    } else {
        for (i, name) in enumerate(names) {
            value = data[name];
            meta = f"{len(value)} items" if isinstance(value, list) else "object";
            safe = escape_html(name);
            parts.append(
                " " * (13 if i == 0 else 12)
                    + f"<a href=\"/{safe}\">\n        <span>/{safe}</span>\n        <span class=\"meta\">\n           {meta}         </span>\n      </a>\n",
            );
        }
        parts.append("           </div>");
    }
    parts.append(INDEX_TAIL);
    return "".join(parts);
}
