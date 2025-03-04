# zig-sieve

## Zig implementation of [SIEVE cache eviction algorithm](https://cachemon.github.io/SIEVE-website/).

### Usage

- Add `sieve` dependency to `build.zig.zon`.

```sh
zig fetch --save git+https://github.com/tensorush/zig-sieve
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

### Benchmarks (MacBook M1 Pro)

- Sequence: the time to cache and retrieve integer values.

    ```sh
    $ zig build bench -- -s
    Sequence: 23.042us
    ```

- Composite: the time to cache and retrieve composite values.

    ```sh
    $ zig build bench -- -c
    Composite: 33.417us
    ```

- Composite (normal): the time to cache and retrieve normally-distributed composite values.

    ```sh
    $ zig build bench -- -n
    Composite Normal: 99.708us
    ```
