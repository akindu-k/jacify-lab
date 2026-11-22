# neojac 0.3.3 dogfooding: porting typicode/json-server (1.0.0-beta.15, 89a34a4)

Compiler: `neojac 0.3.3 (linux-x86_64, 98a4abf03de2)`, installed with the official install.sh.
Knowledge sources used: only `neojac docs`, `neojac skills`, `neojac help` and compiler diagnostics.
No neojac source was read. Each entry gives the symptom and a minimal repro; anything about a cause is marked GUESS.

## Summary

| ID | Kind | Area | Finding |
|---|---|---|---|
| F04 | LIMITATION (blocker) | apps / `@restspec` | GET/POST only, fixed paths, no parameters, no access to path, query, headers or body, no status codes. A REST API can't be served from a served space |
| F17 | LIMITATION (blocker) | apps / crossings | `dict[str, any]` isn't sendable (E1308): endpoints can't take or return schemaless JSON |
| F18 | LIMITATION + BUG | apps / graph store | A node with an `any` field can't be kept (E1229). The error is located at line 1 (`import json;`) |
| F09 | LIMITATION | `port` (TS) | 0 of 16 json-server files port: import, async, null, type aliases, generics, classes with type params, `#private`, `slice`/`includes`/`startsWith`… |
| F07 | BUG | `port` (TS) | Ignores the project's tsconfig.json: every `./x.ts` import is TS5097, and `@types/node` isn't seen |
| F08 | BUG | `absorb` + `port` | After absorb moves package.json and node_modules to eco/, port can't resolve any npm module and treats ESM as CommonJS |
| F10 | LIMITATION | `port --check` | Only tsc's errors are listed while tsc fails; E4001s appear one layer at a time |
| F05 | GAP | `absorb` | Requires a jac.toml, and nothing creates one (no `init`); the error doesn't say how |
| F06 | GAP | `absorb` | pnpm/yarn locks silently ignored, so pins are lost; upstream lifecycle scripts run inside eco/<tree> |
| F14 | BUG | type checker | `package.module.Type` annotations refused (E1163) while `module.Type` works |
| F15 | LIMITATION | stdlib / http.server | CPython's IPv6 idiom `address_family = socket.AF_INET6` is refused (E1230: the field is `int`) |
| F16 | LIMITATION | builtins | `sorted`/`list.sort` aren't CPython's TimSort: a different comparison order and different results for non-transitive comparators |
| F11 | LIMITATION (documented) | stdlib / json | `json.loads` raises OverflowError on integers past int64, which JS writes freely (`1e20` is `100000000000000000000`) |
| F19 | BUG (diagnostics) | `@restspec` | `HTTPMethod.PUT` reports a misleading E0108; the parameter error points into rt/stdjac/server.jac |
| F20 | BUG / DOCS | `test` | A module with no tests is "0 passed, 1 of 1 module passed", exit 0; the skill says status 5 |
| F21 | DOCS | lint | W-codes are called errors, but `build` and `run` ignore them (first seen in F12) |
| F12 | DOCS | docs example | The `http` page's own example fails `check` with the style rules (W3037) |
| F03/F13 | DOCS (stale) | skill `writing-jac` | "`class` is not built yet" is false: `class` works (and the http docs use it) |
| F01 | DOCS | skills | No `porting-from-javascript` skill, though port accepts JS/TS |
| F02 | DOCS | port docs | The port-javascript page cites an internal tracker number "#208" |

Observations O1–O5 (CPython-faithful behavior that bit the port, the performance profile, and the
interpretation of "root optimized abstraction") are at the end.

## Log

### F01 DOCS: no `porting-from-javascript` skill
`neojac skills` ships `porting-from-python` and `porting-from-jac`, but nothing for JS/TS, though
`neojac port` accepts `.js/.ts` and `interop/port-javascript` exists. An agent porting a Node app has
no playbook (how to lay out the result, what to keep on a `node` space, how to check behavior).

### F02 DOCS: port-javascript page cites an internal tracker number
`neojac docs interop/port-javascript` ends with "It is a gap #208 closes before JavaScript's port is
complete." #208 isn't linked or explained, and no neojac command can show it.

### F03 DOCS (contradiction): `class` vs `obj`
The `writing-jac` skill, rule 5, says "`class` is not built yet: write `obj`". `neojac docs library/http`
and `library/socket` both derive request handlers with `class Hello(http.server.BaseHTTPRequestHandler)`.
(Checked by compiling below, see F0x.)

### F04 LIMITATION (blocker for the served-app route): `@restspec` can't express a REST API
`neojac docs apps/server` "A path of its own": `@restspec` takes only `HTTPMethod.GET`/`POST`
(`http.HTTPMethod` isn't there either), only a fixed absolute path, and only a function with **no
parameters**. A route function can't see the path's segments, the query string, headers or body, and it
can't set a status code or response headers. Anything else is 404. So a served space (the one whose
`root` graph persists) can't implement any of json-server's surface: `GET /:name/:id`, PUT/PATCH/DELETE,
OPTIONS preflight, `?views:gt=100`, 201/400/404, CORS headers, the HTML index at `/`, static files.
Everything in an app server is `POST /__jac/call/...` with a JSON envelope `{"ok":..,"data":..}`.

### F05 GAP: `absorb` needs a jac.toml, and nothing makes one
`neojac absorb` in a fresh checkout: `neojac: absorb: no jac.toml in that directory or above, for the
manifest to go into` (exit 1). There's no `neojac init`/`new`. The fix (hand-writing a two-line
`[project]` table) is only in the `starting-a-project` skill, and the error doesn't point there.

### F06 GAP: `absorb` silently drops pnpm/yarn locks; absorbed lifecycle scripts run in eco/<tree>
json-server ships `pnpm-lock.yaml`, not `package-lock.json`. `neojac absorb --tree server` reported
success, left `pnpm-lock.yaml` where it was, and wrote no `jac.lock`. `neojac install` then
re-resolved every range from scratch, so the upstream pins are lost without a warning. The absorbed
`scripts.prepare = "husky"` also runs on `neojac install` inside `eco/server` ("> husky / .git can't be
found"). It's harmless here but meaningless in that directory.

### F07 BUG: `port` ignores the project's tsconfig.json
Repro: a plain copy of json-server with `node_modules` installed (incl. `@types/node`), then
`neojac port --check src`. Every relative import `'./service.ts'` is refused with
`error[tsc TS5097]: An import path can only end with a '.ts' extension when 'allowImportingTsExtensions'
is enabled`. But the repo's tsconfig.json sets `"allowImportingTsExtensions": true` and
`"module": "nodenext"`. Also `Cannot find name 'node:test'` / `'node:crypto'` / `structuredClone` /
`URLSearchParams` although `@types/node` is installed. Any Node ≥22 `--experimental-strip-types` project
(which imports with `.ts` extensions) is refused wholesale. `neojac help port` lists no option to pass a
tsconfig. GUESS: port runs its pinned tsc with default compiler options.

### F08 BUG: absorb then port (the documented order) breaks port
After `neojac absorb` moves `package.json` and `node_modules` into `eco/server`, `neojac port --check src`
in the project reports 32× `TS2307 Cannot find module 'lowdb'` (every dependency), 17×
`TS1309 The current file is a CommonJS module and cannot use 'await' at the top level` (because the
`"type": "module"` package.json is gone), and `TS1470 import.meta not allowed`. Port doesn't resolve
modules from the project's absorbed npm tree.

### F09 LIMITATION: port translates 0 of json-server's 16 TS files
Even with node_modules in place (F07 aside), every file is refused. E4001 constructs seen:
`import` (any), `async`/`await`, `null`, `type` aliases, generic functions (`paginate<T>`), classes with
type params or `extends`, `#private` fields, function expressions (`onReadStart = function () {}`),
the global `Number`, `Array.prototype.slice`/`includes`, `String.prototype.startsWith`, and object
literals not typed `Record<string, T>`. Positive control: a 20-line TS file inside the mapping
(numbers, `for..of`, `===`) ports, and `neojac run` prints the same as `neojac node` (`3 1 0`).
Changing `x === prefix` to `x.startsWith(prefix)` makes it refuse again.

### F10 LIMITATION: `port --check` doesn't list every refusal at once
For files where tsc reports errors, only the tsc errors are printed and no E4001s. The E4001 list for
`observer.ts` only appeared once tsc accepted the file. Docs (`toolchain/port`) say `--check` "lists what
stands between it and a port". It's only the first layer of it.

### F11 LIMITATION (documented): `json.loads` refuses valid JSON integers past int64
`json.loads("100000000000000000000")` raises `OverflowError: int too large to fit in 64 bits`
(documented in `neojac docs library/json`, "Differences from CPython"). It bites JSON interchange with
JavaScript: `JSON.stringify(1e20)` writes `100000000000000000000` (JS prints integers below 1e21 without an
exponent), so a db.json written by the original json-server can crash a neojac program that reads it.
Workaround used: `json.loads(text, parse_int=...)` returning a float past 2**53, which matches JS doubles.

### F12 DOCS: the `http` page's own example fails `neojac check` with the style rules
`neojac docs library/http`'s example declares `def do_GET -> None` and `def log_message(...) -> None`.
With `[check.lint] select = ["style"]`, `neojac check` reports `W3037 '-> None' on 'do_GET' is
unnecessary`. The writing-jac skill says "Every `W` code is an error here", yet `neojac run` builds and
runs the same file without complaint. So W codes stop `check` and nothing else, and no doc says that.

### F13 DOCS (stale skill): `class` IS built
Confirms F03. `class Handler(http.server.BaseHTTPRequestHandler) { ... }` compiles and serves requests in
0.3.3. The `writing-jac` skill's rule 5 ("`class` is not built yet: write `obj`") is stale.
`coming-from-python` documents `class` correctly.

### F14 BUG: a type named through a dotted package path is refused (E1163)
```jac
import http.server;
import re;
def ok -> re.Pattern { return re.compile("a"); }                    # accepted
def bad(s: http.server.HTTPServer) -> int { return s.server_port; }  # E1163: an attribute access is not a type
```
`xml.etree.ElementTree.Element` fails the same way. `module.Type` works; `package.module.Type` doesn't, though
`import http.server;` binds it and `http.server.HTTPServer(...)` works as a call. The E1163 entry
doesn't mention dotted paths. Workaround: `import from http.server { HTTPServer }`.

### F15 LIMITATION: the CPython IPv6 server idiom doesn't carry over (E1230)
`class DualStackServer(http.server.ThreadingHTTPServer) { has address_family: socket.AddressFamily =
socket.AF_INET6; }` is refused: "field address_family of TCPServer is int; a subclass cannot declare it
again as AddressFamily". In CPython the attribute is an `AddressFamily` (an IntEnum). The http page says
class attributes become fields that a subclass redeclares, but not that the native field types differ
from CPython's. Workaround: `has address_family: int = ...`.

### F16 LIMITATION: `sorted` / `list.sort` aren't CPython's TimSort
Same comparator, same input, traced with `functools.cmp_to_key`: neojac calls the comparator in the order
`21, 43, 65, 31, 32, 42, ...` (it looks like a bottom-up merge sort). CPython 3.15 (via `neojac python`)
calls it `21, 32, 12, 32, 31, 43, ...` (count-run plus binary insertion). Both are stable, so a
consistent comparator gives the same result. A non-transitive one, such as JS `sort-on`'s
"falsy values last" when `undefined`, `null` and `false` mix, gives a different order: neojac
`['1','3','6','4','7','5','2']`, CPython and V8 `['1','3','6','7','5','4','2']`. Comparator side
effects also run in a different order. `library/list-methods` says lists have "Python's results"; it
doesn't say the algorithm differs. It matters when porting JS, since V8 also uses TimSort.
Workaround used: a hand-written V8 TimSort in Jac (`timsort.jac`).

### F17 LIMITATION (served apps): schemaless JSON can't cross an endpoint (E1308)
```jac
def:pub create(fields: dict[str, any]) -> str { ... }       # E1308 'fields: dict[str, any]' is not sendable across a concurrency boundary
def:pub read(id: str) -> dict[str, any] | None { ... }       # E1308 'read() -> dict[str, any]' is not sendable ...
```
A REST mock server takes and returns arbitrary JSON, so every endpoint must take and return JSON text
(`str`) and parse it by hand. That gives up the typed-call benefit and the envelope still wraps it. Docs
(`apps/crossings`) define "sendable", but no page shows how to serve schemaless data.

### F18 LIMITATION + diagnostic BUG (served apps): a node with an `any` field can't be kept, and the error points at line 1
`node Item { has fields: dict[str, any]; }` connected to `root.shared` in a served space:
```
api.jac:1:1: error[E1229]: keep_node() cannot be specialized for Item
 1 | import json;
/home/akindu/.neojac/0.3.3/rt/stdjac/codec.jac:70:9: error[E0109]: comptime assertion failed: the codec sends only what is sendable: no `any`, function value, ...
```
The location is the module's first line (`import json;`), not the node declaration. The second diagnostic
points into neojac's own runtime. Workaround that works: `has text: str` holding JSON, re-parsed on each
read. Persistence across a restart was then verified (`[{"title": "a", "tags": [1, null]}]` after kill and
restart). Together with F04 and F17 this rules out the persistent served `root` for json-server, whose
whole data model is schemaless. (Its contract is also that the JSON file *is* the database, edited by
hand and reloaded live, which a graph.db can't honor.)

### F19 BUG (diagnostics): misleading messages for `@restspec` misuse
- `@restspec(method=HTTPMethod.PUT, ...)` gives `E0108 cannot evaluate at compile time: neojac evaluates only
  enum members and methods as attributes`. The real problem is that `HTTPMethod` has no `PUT`; the message
  doesn't say so.
- `@restspec(...) def:pub get_post(id: str)` gives an error located at
  `rt/stdjac/server.jac:346:5: error[E0109]: comptime assertion failed: a function served at a path of its own
  takes no parameters`, showing a line of neojac's library (`comptime assert len(params(f))`) rather than
  pointing at the user's decorator or `def`.

### F20 BUG/DOCS: `neojac test` on a module with no tests reports success
`neojac test notests.jac` (a file with no `test` blocks) prints `notests.jac: 0 passed` /
`0 passed; 1 of 1 module passed` and exits 0. The `starting-a-project` skill's table says nothing to
test is "`no tests found`, status 5". Easy to mistake for a green suite. The same happened mid-run:
`timsort.jac: 0 passed` counted as a passed module while another module failed to compile.

### F21 DOCS: lint "errors" don't stop `build`/`run`
`neojac check` reports `error[W3037]`, while `neojac build w.jac -o w` succeeds and the binary runs. The
skills say "Every `W` code is an error here" and "a code that starts with `W` is an error too". That holds
only for `check`, and no doc says build ignores the lint rules (F12 was the first sighting).

## Observations (CPython-faithful behavior that bit the port; not neojac defects)
- O1 `http.server` with `protocol_version = "HTTP/1.1"` stalls about 41 ms per keep-alive request (Nagle plus
  delayed ACK, since headers and body are separate writes). CPython 3.15 does exactly the same.
  `disable_nagle_algorithm = True` (a socketserver field) fixes it; the `http` page doesn't mention it.
  After the fix the port answers keep-alive requests in 0.11 ms against Node's 0.14 ms.
- O2 `BaseHTTPRequestHandler.path` collapses a leading `//` to `/` (CPython's security fix). Node doesn't,
  so `GET //` must be routed from `self.requestline`.
- O3 A process started with SIGINT ignored (a background job of a script) keeps it ignored, as CPython does.
  Node resets it. The port calls `signal.signal(SIGINT, SIG_DFL)` to match.
- O4 `any`-heavy code is about 10× slower than V8 for json-server's sort comparator (2.1 ms against about 0.2 ms
  for 200 records). That's consistent with `neojac docs types-any`'s warning. Per-request HTTP cost isn't the
  bottleneck: native `http.server` is faster than CPython's (0.55 against 0.74 ms per new connection).
- O5 The task's phrase "root optimized abstraction" isn't a term any neojac doc or skill defines
  (`neojac docs search optimiz`/`root`). Interpreted as: state held in the object-spatial graph off
  `root`, with walkers for the cross-resource cascades, built with `--release`.
