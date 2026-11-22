#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"; LAB="$(dirname "$HERE")"
W="$HERE/work/cli"; rm -rf "$W"; mkdir -p "$W"; cd "$W"
echo '{"posts": [], "profile": {}}' > ok.json; : > empty.json; echo '{bad' > bad.json; echo '{a: }' > bad.json5; echo '{}' > none.json
echo '{"tags": ["a", "b"]}' > prim.json; echo '{"x": [null]}' > nullitem.json; echo '[1, 2]' > toparray.json
ORIG=(neojac node --experimental-strip-types "$LAB/port-plain/src/bin.ts"); PORT=("$LAB/json-server-jac/dist/json-server-jac")
mask() { sed -E 's/^(♡⸜\(˶˃ ᵕ ˂˶\)⸝♡|♡\( ◡‿◡ \)|\( ˶ˆ ᗜ ˆ˵ \)|\(˶ᵔ ᵕ ᵔ˶\))$/<KAOMOJI>/'; }
run() { # run <label> <timeout> <env> args...
  local label="$1" t="$2" envs="$3"; shift 3
  for side in orig port; do
    local -n cmd=$([ $side = orig ] && echo ORIG || echo PORT)
    rm -rf "$W/$side"; mkdir -p "$W/$side"; cp "$W"/*.json "$W"/*.json5 "$W/$side/"
    (cd "$W/$side" && env $envs timeout -s INT $t "${cmd[@]}" "$@" > "$W/out-$side.txt" 2> "$W/err-$side.txt"; echo "exit=$?" >> "$W/out-$side.txt")
  done
  local oo="$(mask < out-orig.txt)" po="$(mask < out-port.txt)"
  local oe="$(head -1 err-orig.txt)" pe="$(head -1 err-port.txt)"
  if [ "$oo" == "$po" ]; then echo "SAME   stdout+exit  $label"; else echo "DIFFER stdout+exit  $label"; diff <(echo "$oo") <(echo "$po") | head -12; fi
  if [ -s err-orig.txt ] || [ -s err-port.txt ]; then echo "       stderr orig: $(grep -m1 -E 'Error|error' err-orig.txt)"; echo "       stderr port: $pe"; fi
}
run "--help" 5 "" --help
run "--version" 5 "" --version
run "no args" 5 ""
run "unknown long option" 5 "" --nope ok.json
run "unknown short option" 5 "" -x ok.json
run "unknown option with value" 5 "" --nope=3 ok.json
run "missing value" 5 "" ok.json --port
run "boolean with value" 5 "" --help=yes
run "missing file" 5 "" missing.json
run "start + endpoints" 2 "" ok.json -p 4801
run "-w deprecated flag" 2 "" -w ok.json -p 4802
run "PORT env" 2 "PORT=4803" ok.json
run "HOST env and -h" 2 "HOST=myhost" ok.json -h other -p 4804
run "empty db file" 2 "" empty.json -p 4805
run "no resources" 2 "" none.json -p 4806
run "invalid JSON db" 5 "" bad.json -p 4807
run "invalid JSON5 db" 5 "" bad.json5 -p 4808
run "primitive array item" 5 "" prim.json -p 4809
run "null array item" 5 "" nullitem.json -p 4810
run "bad port" 5 "" ok.json -p abc
run "port=value form" 2 "" ok.json --port=4811
run "-p<value> form" 2 "" ok.json -p4812
run "-- positional" 2 "" -p 4813 -- ok.json

