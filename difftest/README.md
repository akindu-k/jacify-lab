# difftest: json-server-jac against the original json-server

`run-all.sh` runs every check. Each check starts the original (`../port-plain`, on `neojac node`) and
`../json-server-jac/dist/json-server-jac` from identical fresh working directories, then compares them.

| Script | Compares |
|---|---|
| `run-scenario.sh <scenario> <db>` | Replays `scenarios/*.json` with `difftest` (a Jac program). Compares status, headers, body, and the db file left on disk; random ids are masked |
| `cli-test.sh` | 23 command lines: stdout and exit code, plus stderr's first line |
| `watch-test.sh` | Live edits of the db file: what each server serves after each edit, and the printed logs |
| `conc-test.sh` | 200 concurrent POSTs (all must be kept) and rough throughput |
| `http-bench.sh` | HTTP-layer latency: Node vs the port vs bare native `http.server` vs CPython's |

Needs `../port-plain` (a copy of upstream json-server with `neojac npm install` run in it). Build
`difftest` with `neojac build difftest.jac -o difftest`.
