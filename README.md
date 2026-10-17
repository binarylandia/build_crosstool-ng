# Prebuilt GCC cross-compiler toolchains for multiple platforms

## [Releases](https://github.com/binarylandia/build_crosstool-ng/releases)

Uses [crosstool-NG](https://crosstool-ng.github.io/) to build complete cross-compilation toolchains from x86_64 Linux hosts to various targets including Linux (glibc and musl), Windows (MinGW), and different CPU architectures.

## Features

- Self-contained toolchains with sysroot
- C, C++, and Fortran support
- Multiple GCC versions available
- Parallel builds for all targets

## Use Cases

- Cross-compiling Linux binaries for ARM servers
- Building Windows executables from Linux
- Creating portable musl-linked static binaries
- CI/CD pipelines targeting multiple platforms

## Keywords

cross compiler, cross-compilation toolchain, gcc cross compile, linux to windows, linux to arm, aarch64 cross compiler, musl cross compiler, mingw cross compiler, crosstool-ng, prebuilt cross toolchain

## Building and releasing

```bash
# Build the GCC 14 toolchains into .out/<build time>/, with one metadata file per toolchain
./build 'CONFIGS="configs/14.2.0_*.config" ./scripts/main'

# Check, then publish them as release gcc-14.2.0-<build time>
./scripts/release --dry-run <build time>
./scripts/release <build time>
```

- The base image is pinned by digest and crosstool-NG by commit; crosstool-NG verifies the sources it downloads
- Archives list their files in sorted order with one owner and the commit time, so the same files give the same archive
- `scripts/release` publishes only a build of a clean, pushed commit, and never changes a published release
- Each release has `SHA256SUMS` and `manifest.json`, which records for every toolchain its target, GCC, binutils, C library, crosstool-NG commit, base image, and build commit
