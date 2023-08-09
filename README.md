# bloom-zig

[Bloom filters](https://en.wikipedia.org/wiki/Bloom_filter) written in [Zig](https://ziglang.org/) with Python bindings.

**NOTE that this software is under development and it's not completely functional. Use it at your own risk!**


## Requirements

- Zig verion 0.11.0
- Python (used version 3.9)
- make


## How it works

The `src` folder contains the Zig code for the Bloom filter. It internally uses an ArrayList of u64, where each bit in a u64 element represents an element in the set. I'd preferred to use a more efficient structure or directly an array of u64, but I'm not aware of the compile-time functionality of Zig and if they integrate well with Python code. So I decided to stick with the basics.

The `code_binding` folder contains the code used to generate the Python wheel package and the Python bindings directly written in Zig. There's a `Makefile` to reproduce the building steps. The Zig code is a blind translation of the C code for writing Python bindings.

The exposed functionalities inside Python are a class called `BloomFilter` with 3 methods: `add`, `present` and `count`. There's also a function called `fnv` to compute a 128bit non-cryptographic hash.

## Why?

Never written an extension for Python so far. Just a beginner with Zig. How to conciliate these two aspects? A Python extension in Zig! The great interop that Zig has with C libraries made the process (not-so-much) simple.


## How to build the bindings

For now, the building is locally available for the AARM64 Macos architecture. If you're building using a different architecture (and this is probably the case) you should change the `--target` flag inside the `setup.py` file accordingly (sorry about that, I didn't improve this part yet). Create a Python environment with the requirements listed inside `code_binding` and source it. It should not be necessary since the only dependency (for now) is wheels, but who never knows? Then you can use the `make` command to build and install the wheel by calling `make install`. If everything is working properly, the Python REPL should have access to the "bloom" package.

## TODOs

- [ ] make wheels for manylinux
- [ ] Pypi package(s)
- [ ] examples and benchmark


## Resources

- Python offical guide to write extensions: https://docs.python.org/3/extending/index.html
- Example package of Python building with Zig: https://github.com/Lucifer-02/python_zig
- Zig documentation: https://ziglang.org/documentation/0.11.0/
