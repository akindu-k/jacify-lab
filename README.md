# jacify-lab: json-server ported to Jac with neojac 0.3.3

| Path | What it is |
|---|---|
| `FINDINGS.md` | Every bug, gap, limitation and docs problem found in neojac 0.3.3, with repros |
| `json-server-jac/` | The hand-designed idiomatic port (the deliverable): see its README |
| `difftest/` | Differential proof against the original: 417/417 responses and 8/8 db files identical |
| `absorb-trial/` | Step 1: `neojac absorb` of json-server's package.json (F05, F06) |
| `port-plain/`, `port-check*.txt`, `port-control/` | Step 2: `neojac port` on the TypeScript sources: 0 of 16 files port (F07–F10) |
| `upstream-json-server/` | Pristine clone of typicode/json-server at 89a34a4 |
| `spikes/` | Small experiments behind individual findings (served app, E1163, sort order, lint vs build) |

## Recreating the ignored upstream copies

`upstream-json-server/` and `port-plain/` aren't committed. The differential tests need `port-plain/`:

```sh
git clone https://github.com/typicode/json-server.git upstream-json-server
git -C upstream-json-server checkout 89a34a4
cp -r upstream-json-server port-plain && rm -rf port-plain/.git
(cd port-plain && neojac npm install --ignore-scripts)
(cd json-server-jac && neojac build main.jac --release -o dist/json-server-jac)
(cd difftest && neojac build difftest.jac -o difftest && ./run-all.sh)
```
