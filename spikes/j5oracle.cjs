const JSON5 = require('../port-plain/node_modules/json5');
const docs = [
  "{posts: [{id: '1', title: 'a title'},], comments: [], profile: {name: 'typicode',},}",
  "// c\n{/* x */ a: 1, 'b': \"two\", c: [1, 2.5, .5, 5., +1, -0x1F, 1e3, Infinity, -Infinity], d: null, e: true}",
  "{$a_1: 'it\\'s', \"q\": 'say \"hi\"', s: 'line\\\nnext', u: '\\u00e9\\x41\\0', n: 0xFF}",
  "[1, 'a', {}, []]",
  "{a: 1,, }", "{a: }", "{a 1}", "[1 2]", "'unterminated", "{1a: 2}", "{a: 01}", "{a: 'x\\1'}", "", "{a: 1} x", "/ x", "{a: tru}"
];
const parsed = docs.map(d => { try { const v = JSON5.parse(d); return [d, "OK", JSON.stringify(v, (k, x) => (typeof x === 'number' && !Number.isFinite(x)) ? String(x) : x)]; } catch (e) { return [d, "ERR", e.message]; } });
const values = [{posts: [{id: "1", title: "a title"}], profile: {name: "typicode"}}, {"a b": 1, "": 2, "$x": "it's", "q": 'say "hi" \'x\'', "1": [true, null, 1.5, 1e21], "é": "\u0001\n\t\0 1", "z": "\u00002"}, [], {}];
const strs = values.map(v => [v, JSON5.stringify(v)]);
console.log(JSON.stringify({parsed, strs}));
