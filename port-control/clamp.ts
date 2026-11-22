function clampPage(page: number, pages: number): number {
  if (page < 1) {
    return 1;
  }
  if (page > pages) {
    return pages;
  }
  return page;
}

function countPrefix(xs: string[], prefix: string): number {
  let n = 0;
  for (const x of xs) {
    if (x === prefix) {
      n++;
    }
  }
  return n;
}

console.log(clampPage(9, 3), clampPage(0, 3), countPrefix(["ab", "ac", "b"], "a"));
