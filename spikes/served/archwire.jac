graph layers {
    layer all { *; }
}

graph spaces {
    space api: native { api; }

    app api { run api; }
}
