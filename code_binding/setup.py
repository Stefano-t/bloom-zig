import os
import platform
import sysconfig
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext


def deps():
    return [
        "--deps",
        "bloom",
        "--mod",
        "bloom::../src/main.zig",
    ]


def get_arch_triplet():
    uname = platform.uname()

    machine = uname.machine.lower()
    if machine == "arm64":
        # Using 'arm64' on a MacOs causes runtime crashes.
        machine = "aarch64"

    system = uname.system.lower()
    if system == "darwin":
        system = "macos"

    abi = "none"
    if system == "linux":
        abi = "gnu"  # @NOTE: Not sure about that.

    return f"{machine}-{system}-{abi}"


def get_include_dir():
    paths = sysconfig.get_paths()
    return f"-I{paths.get('include', '')}"


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
                    "-lc",
                    f"-femit-bin={self.get_ext_fullpath(ext.name)}",
                    "-fallow-shlib-undefined",
                    *deps(),
                    "-target",
                    get_arch_triplet(),
                    "-dynamic",
                    get_include_dir(),
                    *[f"-I{d}" for d in self.include_dirs],
                    ext.sources[0],
                ]
            )


def readme():
    with open("../README.md") as f:
        return f.read()


setup(
    name="zig-bloom",
    version="0.0.6",
    description="Bloom filter implemented in zig",
    long_description=readme(),
    long_description_content_type="text/markdown",
    # Extension name must match the exported lib name
    ext_modules=[Extension("bloom", sources=["binding.zig"])],
    cmdclass={"build_ext": Builder},
    author="Stefano Taverni",
    author_email="ste.taverni@gmail.com",
    url="https://github.com/Stefano-t/bloom-zig",
    license="BSD-3-Clause",
)
