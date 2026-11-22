impl min_run_length(n: int) -> int {
    m = n;
    r = 0;
    while m >= 64 {
        r = r | (m & 1);
        m = m >> 1;
    }
    return m + r;
}

impl v8_sort(items: list[any], cmp: Callable[[any, any], int]) -> list[any] {
    s = TimSort(a=list(items), cmp=cmp);
    s.sort();
    return s.a;
}

impl TimSort.sort {
    n = len(self.a);
    if n < 2 {
        return;
    }
    if n <= 7 {
        self.binary_insertion(0, n, 1);
        return;
    }
    remaining = n;
    low = 0;
    min_run = min_run_length(n);
    while remaining != 0 {
        run = self.count_and_make_run(low, low + remaining);
        if run < min_run {
            forced = min(min_run, remaining);
            self.binary_insertion(low, low + forced, low + run);
            run = forced;
        }
        self.runs.append((low, run));
        self.merge_collapse();
        low += run;
        remaining -= run;
    }
    self.merge_force_collapse();
}

impl TimSort.count_and_make_run(lo: int, hi: int) -> int {
    low = lo + 1;
    if low == hi {
        return 1;
    }
    run = 2;
    descending = self.cmp(self.a[low], self.a[low - 1]) < 0;
    previous = self.a[low];
    idx = low + 1;
    while idx < hi {
        current = self.a[idx];
        order = self.cmp(current, previous);
        if descending {
            if order >= 0 {
                break;
            }
        } elif order < 0 {
            break;
        }
        previous = current;
        run += 1;
        idx += 1;
    }
    if descending {
        self.a[lo:lo + run] = self.a[lo:lo + run][::-1];
    }
    return run;
}

impl TimSort.binary_insertion(lo: int, hi: int, start: int) {
    s = start;
    if s == lo {
        s += 1;
    }
    while s < hi {
        pivot = self.a[s];
        left = lo;
        right = s;
        while left < right {
            mid = left + ((right - left) >> 1);
            if self.cmp(pivot, self.a[mid]) < 0 {
                right = mid;
            } else {
                left = mid + 1;
            }
        }
        p = s;
        while p > left {
            self.a[p] = self.a[p - 1];
            p -= 1;
        }
        self.a[left] = pivot;
        s += 1;
    }
}

impl TimSort.merge_collapse {
    while len(self.runs) > 1 {
        n = len(self.runs) - 2;
        bad_upper = n + 1 >= 2 and self.runs[n - 1][1] <= self.runs[n][1] + self.runs[n + 1][1];
        bad_lower = n >= 2 and self.runs[n - 2][1] <= self.runs[n - 1][1] + self.runs[n][1];
        if bad_upper or bad_lower {
            if self.runs[n - 1][1] < self.runs[n + 1][1] {
                n -= 1;
            }
            self.merge_at(n);
        } elif self.runs[n][1] <= self.runs[n + 1][1] {
            self.merge_at(n);
        } else {
            break;
        }
    }
}

impl TimSort.merge_force_collapse {
    while len(self.runs) > 1 {
        n = len(self.runs) - 2;
        if n > 0 and self.runs[n - 1][1] < self.runs[n + 1][1] {
            n -= 1;
        }
        self.merge_at(n);
    }
}

impl TimSort.merge_at(i: int) {
    (base_a, len_a) = self.runs[i];
    (base_b, len_b) = self.runs[i + 1];
    self.runs[i] = (base_a, len_a + len_b);
    if i == len(self.runs) - 3 {
        self.runs[i + 1] = self.runs[i + 2];
    }
    self.runs.pop();
    k = self.gallop_right(self.a, self.a[base_b], base_a, len_a, 0);
    base_a += k;
    len_a -= k;
    if len_a == 0 {
        return;
    }
    len_b = self.gallop_left(self.a, self.a[base_a + len_a - 1], base_b, len_b, len_b - 1);
    if len_b == 0 {
        return;
    }
    if len_a <= len_b {
        self.merge_low(base_a, len_a, base_b, len_b);
    } else {
        self.merge_high(base_a, len_a, base_b, len_b);
    }
}

impl TimSort.gallop_left(arr: list[any], key: any, base: int, length: int, hint: int) -> int {
    last = 0;
    offset = 1;
    if self.cmp(arr[base + hint], key) < 0 {
        max_ofs = length - hint;
        while offset < max_ofs {
            if self.cmp(arr[base + hint + offset], key) >= 0 {
                break;
            }
            last = offset;
            offset = (offset << 1) + 1;
        }
        if offset > max_ofs {
            offset = max_ofs;
        }
        last += hint;
        offset += hint;
    } else {
        max_ofs = hint + 1;
        while offset < max_ofs {
            if self.cmp(arr[base + hint - offset], key) < 0 {
                break;
            }
            last = offset;
            offset = (offset << 1) + 1;
        }
        if offset > max_ofs {
            offset = max_ofs;
        }
        tmp = last;
        last = hint - offset;
        offset = hint - tmp;
    }
    last += 1;
    while last < offset {
        m = last + ((offset - last) >> 1);
        if self.cmp(arr[base + m], key) < 0 {
            last = m + 1;
        } else {
            offset = m;
        }
    }
    return offset;
}

impl TimSort.gallop_right(arr: list[any], key: any, base: int, length: int, hint: int) -> int {
    last = 0;
    offset = 1;
    if self.cmp(key, arr[base + hint]) < 0 {
        max_ofs = hint + 1;
        while offset < max_ofs {
            if self.cmp(key, arr[base + hint - offset]) >= 0 {
                break;
            }
            last = offset;
            offset = (offset << 1) + 1;
        }
        if offset > max_ofs {
            offset = max_ofs;
        }
        tmp = last;
        last = hint - offset;
        offset = hint - tmp;
    } else {
        max_ofs = length - hint;
        while offset < max_ofs {
            if self.cmp(key, arr[base + hint + offset]) < 0 {
                break;
            }
            last = offset;
            offset = (offset << 1) + 1;
        }
        if offset > max_ofs {
            offset = max_ofs;
        }
        last += hint;
        offset += hint;
    }
    last += 1;
    while last < offset {
        m = last + ((offset - last) >> 1);
        if self.cmp(key, arr[base + m]) < 0 {
            offset = m;
        } else {
            last = m + 1;
        }
    }
    return offset;
}

impl TimSort.merge_low(base_a: int, len_a: int, base_b: int, len_b: int) {
    a = self.a;
    tmp = a[base_a:base_a + len_a];
    dest = base_a;
    ct = 0;
    cb = base_b;
    la = len_a;
    lb = len_b;
    a[dest] = a[cb];
    dest += 1;
    cb += 1;
    lb -= 1;
    outcome = "";
    if lb == 0 {
        outcome = "succeed";
    } elif la == 1 {
        outcome = "copy";
    }
    min_gallop = self.min_gallop;
    while outcome == "" {
        wins_a = 0;
        wins_b = 0;
        forever {
            if self.cmp(a[cb], tmp[ct]) < 0 {
                a[dest] = a[cb];
                dest += 1;
                cb += 1;
                wins_b += 1;
                lb -= 1;
                wins_a = 0;
                if lb == 0 {
                    outcome = "succeed";
                    break;
                }
                if wins_b >= min_gallop {
                    break;
                }
            } else {
                a[dest] = tmp[ct];
                dest += 1;
                ct += 1;
                wins_a += 1;
                la -= 1;
                wins_b = 0;
                if la == 1 {
                    outcome = "copy";
                    break;
                }
                if wins_a >= min_gallop {
                    break;
                }
            }
        }
        if outcome != "" {
            break;
        }
        min_gallop += 1;
        first = True;
        while outcome == "" and (wins_a >= 7 or wins_b >= 7 or first) {
            first = False;
            min_gallop = max(1, min_gallop - 1);
            self.min_gallop = min_gallop;
            wins_a = self.gallop_right(tmp, a[cb], ct, la, 0);
            if wins_a > 0 {
                a[dest:dest + wins_a] = tmp[ct:ct + wins_a];
                dest += wins_a;
                ct += wins_a;
                la -= wins_a;
                if la == 1 {
                    outcome = "copy";
                    break;
                }
                if la == 0 {
                    outcome = "succeed";
                    break;
                }
            }
            a[dest] = a[cb];
            dest += 1;
            cb += 1;
            lb -= 1;
            if lb == 0 {
                outcome = "succeed";
                break;
            }
            wins_b = self.gallop_left(a, tmp[ct], cb, lb, 0);
            if wins_b > 0 {
                a[dest:dest + wins_b] = a[cb:cb + wins_b];
                dest += wins_b;
                cb += wins_b;
                lb -= wins_b;
                if lb == 0 {
                    outcome = "succeed";
                    break;
                }
            }
            a[dest] = tmp[ct];
            dest += 1;
            ct += 1;
            la -= 1;
            if la == 1 {
                outcome = "copy";
                break;
            }
        }
        if outcome == "" {
            min_gallop += 1;
            self.min_gallop = min_gallop;
        }
    }
    if outcome == "succeed" {
        if la > 0 {
            a[dest:dest + la] = tmp[ct:ct + la];
        }
    } else {
        a[dest:dest + lb] = a[cb:cb + lb];
        a[dest + lb] = tmp[ct];
    }
}

impl TimSort.merge_high(base_a: int, len_a: int, base_b: int, len_b: int) {
    a = self.a;
    tmp = a[base_b:base_b + len_b];
    dest = base_b + len_b - 1;
    ct = len_b - 1;
    ca = base_a + len_a - 1;
    la = len_a;
    lb = len_b;
    a[dest] = a[ca];
    dest -= 1;
    ca -= 1;
    la -= 1;
    outcome = "";
    if la == 0 {
        outcome = "succeed";
    } elif lb == 1 {
        outcome = "copy";
    }
    min_gallop = self.min_gallop;
    while outcome == "" {
        wins_a = 0;
        wins_b = 0;
        forever {
            if self.cmp(tmp[ct], a[ca]) < 0 {
                a[dest] = a[ca];
                dest -= 1;
                ca -= 1;
                wins_a += 1;
                la -= 1;
                wins_b = 0;
                if la == 0 {
                    outcome = "succeed";
                    break;
                }
                if wins_a >= min_gallop {
                    break;
                }
            } else {
                a[dest] = tmp[ct];
                dest -= 1;
                ct -= 1;
                wins_b += 1;
                lb -= 1;
                wins_a = 0;
                if lb == 1 {
                    outcome = "copy";
                    break;
                }
                if wins_b >= min_gallop {
                    break;
                }
            }
        }
        if outcome != "" {
            break;
        }
        min_gallop += 1;
        first = True;
        while outcome == "" and (wins_a >= 7 or wins_b >= 7 or first) {
            first = False;
            min_gallop = max(1, min_gallop - 1);
            self.min_gallop = min_gallop;
            k = self.gallop_right(a, tmp[ct], base_a, la, la - 1);
            wins_a = la - k;
            if wins_a > 0 {
                dest -= wins_a;
                ca -= wins_a;
                a[dest + 1:dest + 1 + wins_a] = a[ca + 1:ca + 1 + wins_a];
                la -= wins_a;
                if la == 0 {
                    outcome = "succeed";
                    break;
                }
            }
            a[dest] = tmp[ct];
            dest -= 1;
            ct -= 1;
            lb -= 1;
            if lb == 1 {
                outcome = "copy";
                break;
            }
            k = self.gallop_left(tmp, a[ca], 0, lb, lb - 1);
            wins_b = lb - k;
            if wins_b > 0 {
                dest -= wins_b;
                ct -= wins_b;
                a[dest + 1:dest + 1 + wins_b] = tmp[ct + 1:ct + 1 + wins_b];
                lb -= wins_b;
                if lb == 1 {
                    outcome = "copy";
                    break;
                }
                if lb == 0 {
                    outcome = "succeed";
                    break;
                }
            }
            a[dest] = a[ca];
            dest -= 1;
            ca -= 1;
            la -= 1;
            if la == 0 {
                outcome = "succeed";
                break;
            }
        }
        if outcome == "" {
            min_gallop += 1;
            self.min_gallop = min_gallop;
        }
    }
    if outcome == "succeed" {
        if lb > 0 {
            a[dest - (lb - 1):dest + 1] = tmp[0:lb];
        }
    } else {
        dest -= la;
        ca -= la;
        a[dest + 1:dest + 1 + la] = a[ca + 1:ca + 1 + la];
        a[dest] = tmp[ct];
    }
}
