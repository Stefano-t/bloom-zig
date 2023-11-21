# The `bloom` package exports the BloomFilter class and fnv_1 function.
import bloom


def main():
    # fnv_1 is used to compute the hash of a string.
    s = "hello"
    h = bloom.fnv_1(s)  # only strings are valid.
    print("The fnv_1 hash of {} is {}".format(s, h))

    # Create the bloom filter structure.
    bf = bloom.BloomFilter(
        10_000,  # n. elements
        10,      # n. hash functions
    )

    # Add elements to the filter. You need to create an hash of your
    # values/objects before inserting them in the structure. You can you
    # whichever hash function you want, as long as it produces an usinged 64 bit
    # integers.
    bf.add(bloom.fnv_1("hello"))
    bf.add(bloom.fnv_1("hi"))
    bf.add(bloom.fnv_1("another string"))

    # Test if an element is inside the filter.
    assert bf.present(bloom.fnv_1("hello"))
    assert bf.present(bloom.fnv_1("hi"))
    assert bf.present(bloom.fnv_1("another string"))

    assert not bf.present(bloom.fnv_1("not present"))

    # Check the number of bits set in the filter. This should be 30.
    print("The number of set bits is {}".format(bf.count()))


if __name__ == "__main__":
    main()
