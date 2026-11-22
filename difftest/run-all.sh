#!/usr/bin/env bash
# Runs every differential check of json-server-jac against the original json-server.
cd "$(dirname "$0")"
for s in "s01-app-table app-db.json" "s02-app-where app-db.json" "s03-queries rich-db.json" "s04-mutations rich-db.json" \
         "s05-static app-db.json" "s06-json5 rich-db.json5" "s08-methods app-db.json"; do
  set -- $s; ./run-scenario.sh scenarios/$1.json scenarios/$2 | tail -2 | tr '\n' ' '; echo
done
NODE_ENV=production ./run-scenario.sh scenarios/s07-production.json scenarios/app-db.json | tail -2 | tr '\n' ' '; echo
echo "--- CLI"; ./cli-test.sh | grep -c "^SAME" | sed 's/^/SAME: /'; ./cli-test.sh | grep "^DIFFER" || true
echo "--- watch"; ./watch-test.sh | grep -E "^(SAME|DIFFER)|logs identical" | sort | uniq -c
echo "--- concurrency"; ./conc-test.sh 2>/dev/null | grep -E "status codes|file:"
