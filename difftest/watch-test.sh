#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; LAB="$(dirname "$HERE")"
W="$HERE/work/watch"; rm -rf "$W"; mkdir -p "$W/orig" "$W/port"
for s in orig port; do echo '{"posts": [{"id": "1", "title": "a"}], "profile": {"name": "x"}}' > "$W/$s/db.json"; done
(cd "$W/orig" && exec neojac node --experimental-strip-types "$LAB/port-plain/src/bin.ts" db.json -p 4901 > log.txt 2>&1) & P1=$!
(cd "$W/port" && exec "$LAB/json-server-jac/dist/json-server-jac" db.json -p 4902 > log.txt 2>&1) & P2=$!
sleep 2.5
step() { # step <label> <shell edit using $F> <path to GET>
  for s in orig port; do F="$W/$s/db.json"; eval "$2"; done
  sleep 1.2
  a=$(curl -s "localhost:4901$3"); b=$(curl -s "localhost:4902$3")
  [ "$a" == "$b" ] && echo "SAME   GET $3 after: $1" || { echo "DIFFER GET $3 after: $1"; echo "  orig: $a" | head -5; echo "  port: $b" | head -5; }
}
step "new resource added" 'echo "{\"posts\": [{\"id\": \"1\", \"title\": \"a\"}], \"profile\": {\"name\": \"x\"}, \"tags\": [{\"id\": 7}]}" > "$F"' /tags
step "invalid JSON written" 'echo "{\"posts\": [" > "$F"' /posts
step "file fixed, same keys as before the error" 'echo "{\"posts\": [{\"id\": \"1\", \"title\": \"b\"}], \"profile\": {\"name\": \"x\"}, \"tags\": []}" > "$F"' /posts
step "value-only change" 'echo "{\"posts\": [{\"id\": \"1\", \"title\": \"c\"}], \"profile\": {\"name\": \"x\"}, \"tags\": []}" > "$F"' /posts/1
step "API write" 'true' '/posts'
curl -s -X PATCH localhost:4901/posts/1 -d '{"title":"api"}' > /dev/null; curl -s -X PATCH localhost:4902/posts/1 -d '{"title":"api"}' > /dev/null; sleep 1.2
step "after API PATCH (no reload spam expected)" 'true' /posts/1
step "file deleted" 'rm -f "$F"' /posts/1
step "file recreated (chokidar add event, ignored)" 'echo "{\"fresh\": []}" > "$F"' /fresh
step "recreated file edited" 'echo "{\"fresh\": [], \"more\": {}}" > "$F"' /more
step "file emptied to {} then null" 'echo "null" > "$F"' /more
kill -INT $P1 $P2; sleep 0.5; kill -TERM $P1 $P2 2>/dev/null; wait $P1 $P2 2>/dev/null
mask() { sed -E 's/^(♡⸜\(˶˃ ᵕ ˂˶\)⸝♡|♡\( ◡‿◡ \)|\( ˶ˆ ᗜ ˆ˵ \)|\(˶ᵔ ᵕ ᵔ˶\))$/<KAOMOJI>/; s/:490[12]/:PORT/g'; }
echo "--- log diff (orig vs port):"; diff <(mask < "$W/orig/log.txt") <(mask < "$W/port/log.txt") && echo "logs identical"
echo "--- port log:"; mask < "$W/port/log.txt" | tail -25
