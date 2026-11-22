impl mime_lookup(name: str) -> str {
    text = name.strip().lower();
    dot = text.rfind(".");
    ext = text if dot < 0 else text[dot + 1:];
    return MIMES.get(ext, "");
}
