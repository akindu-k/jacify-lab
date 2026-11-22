obj TimSort {
    has a: list[any],
        cmp: Callable[[any, any], int],
        runs: list[tuple[int, int]] = [],
        min_gallop: int = 7;

    def sort;

    def count_and_make_run(lo: int, hi: int) -> int;

    def binary_insertion(lo: int, hi: int, start: int);

    def merge_collapse;

    def merge_force_collapse;

    def merge_at(i: int);

    def gallop_left(arr: list[any], key: any, base: int, length: int, hint: int) -> int;

    def gallop_right(arr: list[any], key: any, base: int, length: int, hint: int) -> int;

    def merge_low(base_a: int, len_a: int, base_b: int, len_b: int);

    def merge_high(base_a: int, len_a: int, base_b: int, len_b: int);
}

def min_run_length(n: int) -> int;

def v8_sort(items: list[any], cmp: Callable[[any, any], int]) -> list[any];
