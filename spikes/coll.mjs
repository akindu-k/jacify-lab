const chars = [];
for (let i = 32; i < 127; i++) chars.push(String.fromCharCode(i));
const sorted = [...chars].sort((a, b) => a.localeCompare(b));
console.log(JSON.stringify(sorted.join('')));
const groups = [];
for (const c of sorted) {
  const last = groups[groups.length - 1];
  if (last && last[0].localeCompare(c, undefined, {sensitivity: 'base'}) === 0) last.push(c); else groups.push([c]);
}
console.log(JSON.stringify(groups.map(g => g.join(''))));
console.log(['a','B','b','A','ä','Ä','z','é','e','E','10','9','a b','ab','a-b','a_b'].sort((a,b)=>a.localeCompare(b)).join('|'));
console.log("\t".localeCompare(""), "a\u0001b".localeCompare("ab"), "x".localeCompare("X"), "résumé".localeCompare("resume"), "a".localeCompare("á"), "áb".localeCompare("ac"));
