impl CliError.init(msg: str, code: str) {
    super.init(msg);
    self.code = code;
}

impl paint(code: str, close: str, text: str) -> str {
    if not COLOR {
        return text;
    }
    return "\x1b[" + code + "m" + text + "\x1b[" + close + "m";
}

impl bold(text: str) -> str {
    return paint("1", "22", text);
}

impl gray(text: str) -> str {
    return paint("90", "39", text);
}

impl help_text -> str {
    return "Usage: json-server [options] <file>\n\nOptions:\n  -p, --port <port>  Port (default: 3000)\n  -h, --host <host>  Host (default: localhost)\n  -s, --static <dir> Static files directory (multiple allowed)\n  --help             Show this message\n  --version          Show version number\n";
}

impl parse_args(argv: list[str]) -> Options {
    o = Options(port=os.environ.get("PORT", "3000"), host=os.environ.get("HOST", "localhost"));
    strings = {
        "port": "port",
        "p": "port",
        "host": "host",
        "h": "host",
        "static": "static",
        "s": "static",
    };
    flags = {"help": "help", "version": "version", "watch": "watch", "w": "watch"};
    labels = {
        "port": "-p, --port <value>",
        "host": "-h, --host <value>",
        "static": "-s, --static <value>",
    };
    i = 0;
    while i < len(argv) {
        arg = argv[i];
        i += 1;
        if arg == "--" {
            o.positionals.extend(argv[i:]);
            break;
        }
        if not arg.startswith("-") or arg == "-" {
            o.positionals.append(arg);
            continue;
        }
        name = "";
        inline: str | None = None;
        if arg.startswith("--") {
            body = arg[2:];
            eq = body.find("=");
            name = body if eq < 0 else body[:eq];
            inline = None if eq < 0 else body[eq + 1:];
        } else {
            name = arg[1];
            inline = arg[2:] if len(arg) > 2 else None;
            if inline is not None and name in flags {
                for ch in arg[1:] {
                    if ch not in flags {
                        raise CliError(
                            f"Unknown option '-{ch}'. To specify a positional argument starting with a '-', place it at the end of the command after '--', as in '-- \"-{ch}\"",
                            code="ERR_PARSE_ARGS_UNKNOWN_OPTION",
                        );
                    }
                    setattr(o, flags[ch], True);
                }
                continue;
            }
        }
        if name in strings {
            key = strings[name];
            value = inline;
            if value is None {
                if i >= len(argv) {
                    raise CliError(
                        f"Option '{labels[key]}' argument missing",
                        code="ERR_PARSE_ARGS_INVALID_OPTION_VALUE",
                    );
                }
                value = argv[i];
                i += 1;
            }
            if key == "static" {
                o.statics.append(value);
            } else {
                setattr(o, key, value);
            }
        } elif name in flags {
            if inline is not None and arg.startswith("--") {
                raise CliError(
                    f"Option '--{name}' does not take an argument",
                    code="ERR_PARSE_ARGS_INVALID_OPTION_VALUE",
                );
            }
            setattr(o, flags[name], True);
        } else {
            shown = arg if inline is None or not arg.startswith("--") else "--" + name;
            raise CliError(
                f"Unknown option '{shown}'. To specify a positional argument starting with a '-', place it at the end of the command after '--', as in '-- \"{shown}\"",
                code="ERR_PARSE_ARGS_UNKNOWN_OPTION",
            );
        }
    }
    o.file = o.positionals[0] if o.positionals else "";
    return o;
}

impl log_routes(names: list[str], file: str, host: str, port: int) {
    print(bold("Endpoints:"));
    if len(names) == 0 {
        print(gray(f"No endpoints found, try adding some data to {file}"));
        return;
    }
    print("\n".join([gray(f"http://{host}:{port}/") + paint("34", "39", n) for n in names]));
}

impl banner(file: str, port: int) -> str {
    face = KAOMOJIS[random.randrange(len(KAOMOJIS))];
    return "\n".join([
        bold(f"JSON Server started on PORT :{port}"),
        gray("Press CTRL-C to stop"),
        gray(f"Watching {file}..."),
        "",
        paint("35", "39", face),
        "",
        bold("Index:"),
        gray(f"http://localhost:{port}/"),
        "",
        bold("Static files:"),
        gray("Serving ./public directory if it exists"),
        "",
    ]);
}

impl fail(message: str) {
    print(message, file=sys.stderr);
}

impl Watcher.run {
    last: tuple[float, int, int] | None = None;
    try {
        st = os.stat(self.file);
        last = (st.st_mtime, st.st_size, st.st_ino);
    } except OSError {}
    forever {
        time.sleep(0.1);
        sig: tuple[float, int, int] | None = None;
        try {
            st = os.stat(self.file);
            sig = (st.st_mtime, st.st_size, st.st_ino);
        } except OSError {
            last = None;
            continue;
        }
        if last is None {
            last = sig;
            continue;
        }
        if sig == last {
            continue;
        }
        last = sig;
        if self.app.db.writing or (sig[0], sig[1]) == self.app.db.last_write {
            continue;
        }
        self.reload();
    }
}

impl Watcher.reload {
    with self.app.lock {
        before = sorted(resource_names());
        try {
            data = self.app.db.read();
            if data is None {
                return;
            }
            after = sorted(js_keys(data)) if isinstance(data, dict) else [];
            if self.had_read_error or before != after {
                print();
                log_routes(
                    js_keys(data) if isinstance(data, dict) else [], self.file, self.host, self.port
                );
            }
            self.had_read_error = False;
        } except (JsSyntaxError, Json5Error) as e {
            self.had_read_error = True;
            print(paint("31", "39", "\n".join(["", f"Error parsing {self.file}", str(e)])));
        } except Exception as e {
            kind = type(e).__name__;
            print(f"{'TypeError' if kind == 'JsTypeError' else kind}: {e}");
        }
    }
}

impl run(argv: list[str]) -> int {
    signal.signal(signal.SIGINT, signal.SIG_DFL);
    COLOR = sys.stdout.isatty() or os.environ.get("FORCE_COLOR", "") in ["1", "2", "3", "true"];
    o = Options();
    try {
        o = parse_args(argv);
    } except CliError as e {
        if e.code == "ERR_PARSE_ARGS_UNKNOWN_OPTION" {
            print(paint("31", "39", str(e).split(".")[0]));
            print(help_text());
            return 1;
        }
        fail(f"TypeError [{e.code}]: {e}");
        return 1;
    }
    if o.version {
        print(VERSION);
        return 0;
    }
    if o.watch {
        print(
            paint(
                "33",
                "39",
                "--watch/-w can be omitted, JSON Server 1+ watches for file changes by default",
            ),
        );
    }
    if o.help or len(o.positionals) == 0 {
        print(help_text());
        return 0;
    }
    port_number = js_parse_int(o.port);
    if port_number != port_number or port_number < 0.0 or port_number >= 65536.0 {
        fail(
            f"RangeError [ERR_SOCKET_BAD_PORT]: options.port should be >= 0 and < 65536. Received type number ({js_number_text(port_number)}).",
        );
        return 1;
    }
    port = int(port_number);
    file = o.file;
    if not os.path.exists(file) {
        print(paint("31", "39", f"File {file} not found"));
        return 1;
    }
    with open(file, encoding="utf-8", errors="replace") as f {
        if f.read().strip() == "" {
            with open(file, "w") as out {
                out.write("{}");
            }
        }
    }
    db = Database(file=DataFile(path=file, is_json5=os.path.splitext(file)[1] == ".json5"));
    try {
        db.read();
    } except (JsSyntaxError, Json5Error) as e {
        fail(f"SyntaxError: {e}");
        return 1;
    } except Exception as e {
        kind = type(e).__name__;
        fail(f"{'TypeError' if kind == 'JsTypeError' else kind}: {e}");
        return 1;
    }
    production = os.environ.get("NODE_ENV", "") == "production";
    roots = [os.path.join(os.getcwd(), "public")];
    for s in o.statics {
        roots.append(s if os.path.isabs(s) else os.path.join(os.getcwd(), s));
    }
    app = App(db=db, static_roots=[os.path.normpath(r) for r in roots], production=production);
    server.APP = app;
    srv = server.make_server(port);
    print(banner(file, port));
    log_routes(resource_names(), file, o.host, port);
    sys.stdout.flush();
    if not production {
        w = Watcher(app=app, file=file, host=o.host, port=port);
        threading.Thread(target=w.run, daemon=True).start();
    }
    try {
        srv.serve_forever();
    } except KeyboardInterrupt {}
    return 0;
}
