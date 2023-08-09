import os
import platform
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext

def deps():
    return [
        "--deps",
        "bloom",
        "--mod",
        "bloom::../src/main.zig",
    ]

class Builder(build_ext):
    def build_extension(self, ext):
        assert len(ext.sources) == 1

        if not os.path.exists(self.build_lib):
            os.makedirs(self.build_lib)
            mode = "Debug" if self.debug else "ReleaseFast"
            self.spawn(
                [
                    "zig",
                    "build-lib",
                    "-O",
                    mode,
                    # "-lc",  # @TODO: not sure if libc is useful. It seems useful only with certain architectures (e.g., arm)
                    f"-femit-bin={self.get_ext_fullpath(ext.name)}",
                    "-fallow-shlib-undefined",
                    *deps(),
                    "-target",
                    "aarch64-macos-none",  # @TODO: make general
                    "-dynamic",
                    *[f"-I{d}" for d in self.include_dirs],
                    ext.sources[0],
                ]
            )


setup(
    name="zig-bloom",
    version="0.0.1",
    description="Bloom filter implemented in zig",
    # Extension name must match the exported lib name
    ext_modules=[Extension("bloom", sources=["binding.zig"])],
    cmdclass={"build_ext": Builder},
)
