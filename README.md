## :lizard: :moneybag: **zig sieve**

[![CI][ci-shd]][ci-url]
[![CD][cd-shd]][cd-url]
[![DC][dc-shd]][dc-url]
[![CC][cc-shd]][cc-url]
[![LC][lc-shd]][lc-url]

### Zig implementation of the [SIEVE cache eviction algorithm](https://cachemon.github.io/SIEVE-website/) created by [Yazhuo Zhang](https://github.com/yazhuo) and [Juncheng Yang](https://github.com/1a1a11a).

### :rocket: Usage

1. Add `sieve` as a dependency in your `build.zig.zon`.

    <details>

    <summary><code>build.zig.zon</code> example</summary>

    ```zig
    .{
        .name = "<name_of_your_package>",
        .version = "<version_of_your_package>",
        .dependencies = .{
            .sieve = .{
                .url = "https://github.com/tensorush/zig-sieve/archive/<git_tag_or_commit_hash>.tar.gz",
                .hash = "<package_hash>",
            },
        },
    }
    ```

    Set `<package_hash>` to `12200000000000000000000000000000000000000000000000000000000000000000`, and Zig will provide the correct found value in an error message.

    </details>

2. Add `sieve` as a module in your `build.zig`.

    <details>

    <summary><code>build.zig</code> example</summary>

    ```zig
    const sieve = b.dependency("sieve", .{});
    exe.addModule("sieve", sieve.module("sieve"));
    ```

    </details>


#### :bar_chart: Benchmarks

```bash
$ zig build bench
Sequence: 27.666us
Composite: 38.5us
Composite Normal: 141.458us
```

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-sieve/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/zig-sieve/blob/main/.github/workflows/ci.yaml
[cd-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-sieve/cd.yaml?branch=main&style=for-the-badge&logo=github&label=CD&labelColor=black
[cd-url]: https://github.com/tensorush/zig-sieve/blob/main/.github/workflows/cd.yaml
[dc-shd]: https://img.shields.io/badge/click-F6A516?style=for-the-badge&logo=zig&logoColor=F6A516&label=docs&labelColor=black
[dc-url]: https://tensorush.github.io/zig-sieve
[cc-shd]: https://img.shields.io/codecov/c/github/tensorush/zig-sieve?style=for-the-badge&labelColor=black
[cc-url]: https://app.codecov.io/gh/tensorush/zig-sieve
[lc-shd]: https://img.shields.io/github/license/tensorush/zig-sieve.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/tensorush/zig-sieve/blob/main/LICENSE.md
