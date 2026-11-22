# json-server-jac

A port of [typicode/json-server](https://github.com/typicode/json-server) 1.0.0-beta.15 (commit `89a34a4`)
to Jac, compiled to a native binary with neojac 0.3.3. It serves a JSON or JSON5 file as a REST API, with
the original's routes, query language, persistence, file watching, static files, CORS and index page.
Differential tests show byte-identical responses to the original for every request tried.

## Build, run, test

```sh
neojac build main.jac --release -o dist/json-server-jac
./dist/json-server-jac db.json -p 3000 -s ./static     # same CLI as `json-server`
neojac test                                           # 28 unit tests, in-process
neojac check main.jac && neojac fmt --check .          # both quiet
```

The behavioral proof against the original lives in `../difftest` (see "How it was verified").

## Design

json-server's state is one JSON document: a top-level object whose array values are collections and
whose other values are single resources. The port holds it as a graph off `root`:

```
root ──▶ Collection(name="posts") ──Holds──▶ Record(fields={...})   (edge order = array order)
     ──▶ Collection(name="comments") ──Holds──▶ Record ...
     ──▶ Singleton(name="profile", value={...})                       (objects and primitives)
```

- Deleting a record runs two walkers spawned at `root`, mirroring the original's cascade:
  `NullifyForeignKey` sets `<singular>Id` to `null` across the other collections, and
  `DeleteDependents` deletes `?_dependent=` records whose key is now `null`.
- The graph is the in-memory model. The JSON file stays the database, as in the original: each write
  re-serializes the graph to a temp file and renames it into place (lowdb/steno behavior), and edits
  made to the file by hand are reloaded live.
- The served-app persistent `root` couldn't be used. It can't express REST routes and can't hold
  schemaless values (F04, F17, F18 in `../FINDINGS.md`).

| Module | Role | Mirrors |
|---|---|---|
| `jsvalue` | JS value semantics over decoded JSON: `===`, `<`/`<=` coercions, `String()`, `Number()`, `parseInt`, `JSON.stringify` (JS key order, number formatting), ICU-root `localeCompare` | V8 |
| `jsonparse` | `JSON.parse` that fails with V8's exact messages (positions in UTF-16 units) | V8 |
| `json5` | JSON5 parse (json5's error messages) and compact stringify | `json5` |
| `dotprop` | Path parsing with the original's error messages, get/set | `dot-prop` |
| `inflect` | `singularize` / `pluralize` rule tables | `inflection` |
| `query` | URLSearchParams and `node:querystring` decoding, `parseWhere` | `parse-where.ts` |
| `matching` | `matchesWhere`, `paginate` | `matches-where.ts`, `paginate.ts` |
| `timsort` | V8's `Array.prototype.sort`: binary insertion for ≤ 7 items, otherwise TimSort with galloping | V8 |
| `store` | The root graph, walkers, and the service operations | `service.ts`, `sort-on` |
| `db` | File adapter: read, `$schema` stripping, id normalization, atomic write | `lowdb`, `normalized-adapter.ts` |
| `app` | The request pipeline as a pure `App.handle(Request) -> Response` | tinyhttp + sirv + cors + milliparsec, `app.ts` |
| `views`, `mimes` | Index page (byte-identical to eta's output) and sirv's MIME table | eta, `mrmime` |
| `server` | `http.server` glue: Node's method set, chunked framing, dual-stack listen | Node `http` |
| `main` | CLI (`parseArgs` semantics), banner and endpoint log, file watcher | `bin.ts`, chokidar |

## How it was verified

`../difftest` runs the original (on neojac's bundled Node) and this binary side by side, each with a
fresh copy of the database. It replays the same scenario against both and compares status, headers
(all but date, connection and framing headers, and `X-Powered-By`), body, and the database file left
on disk. Server-generated random ids are masked; later requests use each side's own created ids.

| Scenario | Requests | Identical | DB file |
|---|---|---|---|
| s01 upstream `app.test.ts` route table | 38 | 38 | identical |
| s02 upstream `_where` and body tests | 5 | 5 | identical |
| s03 query language: operators, sort, pagination, embed, `_where`, malformed input | 124 | 124 | identical |
| s04 mutations, cascades, malformed bodies, 100 KiB limit | 48 | 48 | identical |
| s05 static files: fallbacks, ranges, traversal, MIME types | 56 | 56 | identical |
| s06 JSON5 database (s04 plus reads) | 51 | 51 | identical |
| s07 `NODE_ENV=production` (s05 plus errors) | 62 | 62 | identical |
| s08 Node's other HTTP methods, unknown method | 33 | 33 | identical |
| **Total** | **417** | **417** | **8/8** |

The other scripts in `../difftest` also match the original:
- `cli-test.sh`: 23 CLI cases (stdout and exit code).
- `watch-test.sh`: 10 live-edit steps (served data and printed logs, byte for byte).
- `conc-test.sh`: 200 concurrent writes, all kept.

The unit tests port upstream's own tests table by table (`parse-where`, `matches-where`, `paginate`,
`service`, `app`). They also check the JS-semantics modules against oracle tables generated by the
real packages on Node: 300 random non-transitive sorts, V8 `JSON.parse` errors, json5, dot-prop and
inflection.

## Known divergences

- `X-Powered-By: json-server-jac`, not `tinyhttp`. The port doesn't send `Keep-Alive: timeout=5`
  (keep-alive still works).
- Resource names that are `Object.prototype` members (`/constructor`, `/toString`, `/__proto__`, ...)
  are ordinary unknown names here. The original serves the prototype's members.
- An array directly inside a collection, and a top-level JSON value that isn't an object, are refused
  at load with a clear error. The original attaches hidden properties to them.
- A crash at startup prints one `Error: message` line where Node prints a stack trace.
- `M-SEARCH` answers 501: `do_M-SEARCH` can't be named in Jac.
- `localeCompare` reproduces ICU root order exactly for ASCII and for Latin letters with accents. Other
  scripts are ordered by code point after Latin.
- String spread and length count code points, not UTF-16 units, so astral characters in keys or
  `title.length`-style paths differ.
- Read-heavy requests that sort are slower than the original (about 2 ms against 0.2 ms to sort 200 records)
  because the comparator runs on `any`-typed values. Writes and plain reads are on par, and memory use
  is about 40% of Node's.
