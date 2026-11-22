import { getProperty, setProperty } from '../port-plain/node_modules/dot-prop/index.js';
const vals = [null, true, false, 0, -0, 1, 100, 1.5, -2.25, 1e21, 1e-7, 123456789012, 0.1, 1e16, 2e-6, 5e-324, "", "abc", "10", " 12 ", "1e3", "0x1A", "Infinity", "-Infinity", "12px", ".5", "5.", "0b11", "-0x10", " 12 ", [], [1, 2], [null, "a"], {}, {"a": 1}];
const enc = v => v === undefined ? {u: 1} : v;
const num = n => Number.isNaN(n) ? "NaN" : (n === Infinity ? "Infinity" : (n === -Infinity ? "-Infinity" : n));
const out = {};
out.toString = vals.map(v => [v, String(v)]);
out.toNumber = vals.map(v => [v, num(typeof v === 'object' && v !== null && !Array.isArray(v) ? NaN : Number(v))]);
const pairs = [];
const cmp = [null, true, 0, 1, 2, "1", "2", "a", "B", "10", "9", "", [2], {}, "\u{1F600}", "￿", 1.5];
for (const a of cmp) for (const b0 of cmp) { const b = (typeof b0 === "object" && b0 !== null) ? structuredClone(b0) : b0; pairs.push([a, b, a === b, a < b, a <= b, a > b, a >= b]); }
out.compare = pairs;
out.parseInt = ["12", " 3", "-1", "1.9", "abc", "", "2abc", "+7", "-0", "\n42", "0x10", "99999999999999999999"].map(s => [s, num(parseInt(s, 10))]);
out.numberText = [0, 1, -1, 100, 1.5, 1e21, 1e20, 123e-20, 1e-7, 1e-6, 0.000001234, 1.7976931348623157e308, 5e-324, 2**53, 2**53 + 2, 12345678.9, 0.1 + 0.2].map(n => [n, String(n)]);
out.stringify = [[{"b": 1, "2": "x", "1": [1, {}], "a": {"z": null, "y": [true, "é\n\u0001"]}}, 2], [[], 2], [{}, 2], [{"a": []}, 0], [[1.0, 2.5, 1e21], 2]].map(([v, n]) => [v, n, JSON.stringify(v, null, n)]);
out.locale = [["a", "B"], ["B", "a"], ["a", "A"], ["ä", "a"], ["10", "9"], ["a b", "ab"], ["a-b", "a_b"], ["x", "X"], ["résumé", "resume"], ["áb", "ac"], ["", "a"], ["Zeta", "alpha"], ["item 2", "item 10"], ["$", "0"], ["~", "$"]].map(([a, b]) => [a, b, Math.sign(a.localeCompare(b))]);
out.parsePath = ["a", "a.b", "a.b.c", "a\\.b", "a[0]", "a[0].b", "a.0", "a.01", "", "a..b", "a.", "constructor", "a.__proto__", "a[]", "a]", "a[0][1]", "1000001", "a\\"].map(p => { try { return [p, (() => { const o = {}; setProperty(o, p + '.x', 1); return JSON.stringify(o); })()]; } catch (e) { return [p, "ERR:" + e.message]; } });
out.parsePathErr = ["a[x]", "a[0", "a[0]b", "a[\\", "a[0]\\"].map(p => { try { setProperty({}, p, 1); return [p, "ok"]; } catch (e) { return [p, "ERR:" + e.message]; } });
const doc = {a: {b: [10, {c: "x"}], s: "hey"}, n: null};
out.getProperty = ["a.b.0", "a.b.1.c", "a.s.length", "a.s.0", "a.b.length", "n", "n.x", "zz", "a.zz.y", "a.b.5"].map(p => [p, enc(getProperty(doc, p))]);
console.log(JSON.stringify(out));
