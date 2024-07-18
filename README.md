# zig-sieve

[![CI][ci-shd]][ci-url]
[![CD][cd-shd]][cd-url]
[![DC][dc-shd]][dc-url]
[![LC][lc-shd]][lc-url]

## Zig implementation of [SIEVE cache eviction algorithm](https://cachemon.github.io/SIEVE-website/).

### :rocket: Usage

- Add `sieve` dependency to `build.zig.zon`.

```sh
zig fetch --save https://github.com/tensorush/zig-sieve/archive/<git_tag_or_commit_hash>.tar.gz
```

- Use `sieve` dependency in `build.zig`.

```zig
const sieve_dep = b.dependency("sieve", .{
    .target = target,
    .optimize = optimize,
});
const sieve_mod = sieve_dep.module("sieve");
<compile>.root_module.addImport("sieve", sieve_mod);
```

### :bar_chart: Benchmarks

- Sequence: the time to cache and retrieve integer values.

    ```sh
    $ zig build bench -- -s
    Sequence: 28.833us
    ```

- Composite: the time to cache and retrieve composite values.

    ```sh
    $ zig build bench -- -c
    Composite: 45.291us
    ```

- Composite (normal): the time to cache and retrieve normally-distributed composite values.

    ```sh
    $ zig build bench -- -n
    Composite Normal: 135.25us
    ```

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-sieve/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/zig-sieve/blob/main/.github/workflows/ci.yaml
[cd-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-sieve/cd.yaml?branch=main&style=for-the-badge&logo=github&label=CD&labelColor=black
[cd-url]: https://github.com/tensorush/zig-sieve/blob/main/.github/workflows/cd.yaml
[dc-shd]: https://img.shields.io/badge/click-F6A516?style=for-the-badge&logo=zig&logoColor=F6A516&label=docs&labelColor=black
[dc-url]: https://tensorush.github.io/zig-sieve
[lc-shd]: https://img.shields.io/github/license/tensorush/zig-sieve.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/tensorush/zig-sieve/blob/main/LICENSE
