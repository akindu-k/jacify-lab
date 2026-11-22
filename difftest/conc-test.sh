#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; LAB="$(dirname "$HERE")"
W="$HERE/work/conc"; rm -rf "$W"; mkdir -p "$W/orig" "$W/port"
for s in orig port; do echo '{"posts": [], "comments": []}' > "$W/$s/db.json"; done
(cd "$W/orig" && exec neojac node --experimental-strip-types "$LAB/port-plain/src/bin.ts" db.json -p 4961 > log.txt 2>&1) & P1=$!
(cd "$W/port" && exec "$LAB/json-server-jac/dist/json-server-jac" db.json -p 4962 > log.txt 2>&1) & P2=$!
sleep 2.5
for p in 4961 4962; do echo "port $p POST status codes: $(seq 1 200 | xargs -P 50 -I{} curl -s -o /dev/null -w '%{http_code}\n' -X POST localhost:$p/posts -d '{"n": {}}' | sort | uniq -c | tr -s ' \n' ' ')"; done
sleep 0.5
for s in orig port; do neojac python -I -c "import json; d=json.load(open('$W/$s/db.json')); print('$s file: posts =', len(d['posts']), 'unique ids =', len({p['id'] for p in d['posts']}))"; done
for p in 4961 4962; do curl -s localhost:$p/posts | neojac python -I -c "import json,sys; print('served by $p:', len(json.load(sys.stdin)))"; done
for p in 4961 4962; do start=$(date +%s.%N); seq 1 2000 | xargs -P 8 -I{} curl -s -o /dev/null "localhost:$p/posts?n:gt=100&_sort=-id&_page=2&_per_page=20"; end=$(date +%s.%N); echo "port $p: 2000 filter+sort+paginate GETs over 200 items, 8 clients: $(echo "$end - $start" | bc) s"; done
for p in 4961 4962; do start=$(date +%s.%N); seq 1 300 | xargs -P 8 -I{} curl -s -o /dev/null -X PATCH "localhost:$p/posts/does-not-exist" -d '{}'; seq 1 300 | xargs -P 8 -I{} curl -s -o /dev/null -X POST "localhost:$p/comments" -d '{"t":"x"}'; end=$(date +%s.%N); echo "port $p: 300 failed PATCH + 300 POST (each POST rewrites the file): $(echo "$end - $start" | bc) s"; done
ps -o rss=,comm= -p $P1 -p $P2 | awk '{printf "RSS %s MB %s\n", $1/1024, $2}'
kill -TERM $P1 $P2; wait $P1 $P2 2>/dev/null
