# bloom-zig

[Bloom filters](https://en.wikipedia.org/wiki/Bloom_filter) written in
[Zig](https://ziglang.org/) with Python bindings.

**NOTE that this software is under development and it's not completely functional!**

## How to install

Right now, there's only a wheel for Macos. To install it, you can run the usual

```bash
pip install zig-bloom
```

If you need to install this package for another architecture, refer to the
section about building from source.


### Building from source

To build this package from source, you'll need:

- Zig (version 0.11.0)
- Python (version used is 3.9, but it should work with lower versions)
- Python development header
- make (not mandatory, but handy)

If everything correctly installed, you can run `zig build test` to double check
that everything works.

Then, go inside `code_binding` directory. You can create a Python env with the
`requirements.txt` installed or install the requirements in your current env.
With everything in place, run

```bash
make install
```

This should install the `bloom` package in your environment. To test that the
package has been correctly installed, run `make test`.


## How it works

The `src` folder contains the Zig code for the Bloom filter. It internally uses
an ArrayList of u32, where each bit in a u32 element represents an element in
the set. I'd preferred to use a more efficient structure or directly an array
of u64, but I'm not aware of the compile-time functionality of Zig and if they
integrate well with Python code. So I decided to stick with the basics.

The `code_binding` folder contains the code used to generate the Python wheel
package and the Python bindings directly written in Zig. There's a `Makefile`
to reproduce the building steps. The Zig code is a blind translation of the C
code for writing Python bindings.

The exposed functionalities inside Python are a class called `BloomFilter` with
3 methods: `add`, `present` and `count`. There's also a function called `fnv`
to compute a 64 bit non-cryptographic hash.

## Why?

Never written an extension for Python so far. Just a beginner with Zig. How to
conciliate these two aspects? A Python extension in Zig! The great interop that
Zig has with C libraries made the process (not-so-much) simple.


## TODOs

- [X] make wheels for manylinux
- [X] Pypi package(s)
- [X] examples and benchmark


## Resources

- Python official guide to write extensions: https://docs.python.org/3/extending/index.html
- Example package of Python building with Zig: https://github.com/Lucifer-02/python_zig
- Zig documentation: https://ziglang.org/documentation/0.11.0/
