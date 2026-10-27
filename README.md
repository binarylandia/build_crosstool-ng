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
./build 'CONFIGS="configs/14.4.0_*.config" ./scripts/main'

# Check, then publish them as release gcc-14.4.0-<build time>
./scripts/release --dry-run <build time>
./scripts/release <build time>
```

- The base image (Debian 13) is pinned by digest and crosstool-NG by commit; crosstool-NG verifies the sources it downloads
- The image trusts neither emSign ECC Root CA - G3 nor AAA Certificate Services, the roots above the eMudhra intermediate CAs whose private keys became public in October 2026 (`docker/files/distrust-compromised-roots`)
- The tools of every toolchain are compiled by the `x86_64-unknown-linux-gnu` GCC 16 toolchain of an earlier release, whose sysroot has glibc 2.17 (`docker/files/install-host-gcc`, pinned by checksum in `docker/files/checksums`). Every toolchain links glibc dynamically and runs on any Linux host with glibc 2.17 or later; the companion libraries and libstdc++ are linked statically. A fully static toolchain would embed its own glibc, and its GNU ld crashes when it loads the LTO plugin on a host with another glibc. The build fails when a tool needs a newer glibc
- `docker/patches/` changes crosstool-NG itself, and `patches/` holds the patches that crosstool-NG applies to the packages it builds. crosstool-NG allows only binutils older than 2.30 with aarch64 glibc older than 2.26; `patches/glibc/2.17/` backports the glibc fixes that make glibc 2.17 build with current binutils, and `docker/patches/` lifts the limit
- All configs (GCC 12.5.0, 14.4.0, 15.3.0, and 16.2.0) are made for the pinned crosstool-NG 1.29.0. `scripts/derive-gcc-configs` derives the configs of another GCC major from those of one version
- Archives list their files in sorted order with one owner and the commit time, so the same files give the same archive
- `scripts/release` publishes only a build of a clean, pushed commit, and never changes a published release
- Each release has `SHA256SUMS` and `manifest.json`, which records for every toolchain its target, GCC, binutils, C library, crosstool-NG commit, base image, host compiler, and build commit
