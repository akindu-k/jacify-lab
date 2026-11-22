#!/usr/bin/env bash
# usage: run-scenario.sh <scenario.json> <db-file> [extra server args...]
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LAB="$(dirname "$HERE")"
SCEN="$1"; DB="$2"; shift 2
NAME="$(basename "$SCEN" .json)"
WORK="$HERE/work/$NAME"
rm -rf "$WORK"; mkdir -p "$WORK"
for side in orig port; do
  mkdir -p "$WORK/$side/static/sub" "$WORK/$side/public"
  cp "$LAB/upstream-json-server/public/test.html" "$WORK/$side/public/"
  printf 'hello static\n' > "$WORK/$side/static/file.txt"
  printf '<h1>sub index</h1>\n' > "$WORK/$side/static/sub/index.html"
  printf 'body{}\n' > "$WORK/$side/static/site.css"
  printf '{"a":1}\n' > "$WORK/$side/static/data.json"
  printf 'secret\n' > "$WORK/$side/static/.hidden"
  printf 'about page\n' > "$WORK/$side/static/about.html"
  for ext in js mjs png svg ico woff2 map webp wasm md xml csv txt pdf jpg gif zip; do printf 'x%.0s' $(seq 1 7) > "$WORK/$side/static/asset.$ext"; done
  printf 'gzdata' > "$WORK/$side/static/bundle.js.gz"
  printf 'noext' > "$WORK/$side/static/README"
  touch -d '2026-01-02 03:04:05' "$WORK/$side/static/"asset.* "$WORK/$side/static/bundle.js.gz" "$WORK/$side/static/README"
  touch -d '2026-01-02 03:04:05' "$WORK/$side/static/"* "$WORK/$side/static/sub/index.html" "$WORK/$side/public/test.html"
  cp "$DB" "$WORK/$side/$(basename "$DB")"
done
PA=$((4000 + RANDOM % 1000)); PB=$((5000 + RANDOM % 1000))
DBN="$(basename "$DB")"
( cd "$WORK/orig" && exec neojac node --experimental-strip-types "$LAB/port-plain/src/bin.ts" "$DBN" -p $PA -s static "$@" > "$WORK/orig.log" 2>&1 ) &
OPID=$!
( cd "$WORK/port" && exec "$LAB/json-server-jac/dist/json-server-jac" "$DBN" -p $PB -s static "$@" > "$WORK/port.log" 2>&1 ) &
PPID2=$!
for i in $(seq 1 100); do
  if grep -q "Endpoints:" "$WORK/orig.log" 2>/dev/null && grep -q "Endpoints:" "$WORK/port.log" 2>/dev/null; then break; fi
  sleep 0.1
done
"$HERE/difftest" "$SCEN" $PA $PB > "$WORK/diff.txt"; RC=$?
sleep 0.3
kill $OPID $PPID2 2>/dev/null; wait $OPID $PPID2 2>/dev/null
# compare final db files with created ids masked
neojac python -I - "$WORK/orig/$DBN" "$WORK/port/$DBN" "$SCEN.ids" >> "$WORK/diff.txt" <<'PY'
import sys, json
a = open(sys.argv[1], encoding='utf-8').read(); b = open(sys.argv[2], encoding='utf-8').read()
ids = json.load(open(sys.argv[3]))
for i, x in enumerate(ids["original"]): a = a.replace(x, f"<ID:{i}>")
for i, x in enumerate(ids["port"]): b = b.replace(x, f"<ID:{i}>")
import re
rid = re.compile(r'((?:"id"|\bid)\s*:\s*)(["\'])[A-Za-z0-9_-]{11}\2')
a = rid.sub(r'\1"<RID>"', a); b = rid.sub(r'\1"<RID>"', b)
print("DB FILE: identical" if a == b else "DB FILE: DIFFERS\n--- original\n" + a[:1500] + "\n--- port\n" + b[:1500])
PY
cat "$WORK/diff.txt"
grep -q "DB FILE: identical" "$WORK/diff.txt" && [ $RC -eq 0 ]
