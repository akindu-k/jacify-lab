import sortOn from '../port-plain/node_modules/sort-on/index.js';
let seed = 12345;
const rnd = () => { seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648; };
const pool = ['U', null, false, true, 0, 1, 2, 3, 'a', 'B', 'b', '', '10', '9', -1, 2.5];
const cases = [];
for (let c = 0; c < 300; c++) {
  const n = c < 50 ? Math.floor(rnd() * 12) : Math.floor(rnd() * 400);
  const items = [];
  for (let i = 0; i < n; i++) {
    const v = pool[Math.floor(rnd() * pool.length)];
    const w = pool[Math.floor(rnd() * pool.length)];
    const o = {i};
    if (v !== 'U') o.k = v;
    if (w !== 'U') o.j = w;
    items.push(o);
  }
  const spec = [['k'], ['-k'], ['k', '-j'], ['-j', 'k']][c % 4];
  cases.push([items, spec, sortOn(items, spec).map(o => o.i)]);
}
console.log(JSON.stringify(cases));
