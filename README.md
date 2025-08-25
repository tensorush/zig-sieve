# zig-sieve

## Zig implementation of [SIEVE cache eviction algorithm](https://cachemon.github.io/SIEVE-website/).

### Usage

1. Add `sieve` dependency to `build.zig.zon`:

```sh
zig fetch --save git+https://github.com/tensorush/zig-sieve.git
```

2. Use `sieve` dependency in `build.zig`:

```zig
const sieve_dep = b.dependency("sieve", .{
    .target = target,
    .optimize = optimize,
});
const sieve_mod = sieve_dep.module("sieve");

...
    .imports = &.{
        .{ .name = "sieve", .module = sieve_mod },
    },
...
```

### Benchmarks (MacBook M1 Pro)

- Sequence - the time to cache and retrieve integer values:

```sh
$ zig build bench -- s
Sequence: 22.958us
```

- Composite - the time to cache and retrieve composite values:

```sh
$ zig build bench -- c
Composite: 37.668us
```

- Composite (normal) - the time to cache and retrieve normally-distributed composite values:

```sh
$ zig build bench -- n
Composite Normal: 108.001us
```
