from timeit import repeat
import bloom

def bench_bloom_filter():
    b = bloom.BloomFilter(10_000_000, 30)

    for i in range(10_000_000):
        h = bloom.fnv_1(f"{i+0.5}")
        b.add(h)


scores = repeat("bloom.fnv_1('hello')", globals=globals())
res = sum(scores) / len(scores)
print("Benchmark fnv_1 (1'000'000 times): {:.5f}sec".format(res))

scores = repeat("bench_bloom_filter()", globals=globals(), number=1, repeat=5)
res = sum(scores) / len(scores)
print("Benchmark Bloom Filter: {:.5f}sec".format(res))
