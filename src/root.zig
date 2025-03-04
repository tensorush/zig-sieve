//! Root source file that exposes the library's API to users and Autodoc.

const std = @import("std");

pub const Cache = @import("sieve.zig").Cache;

test {
    std.testing.refAllDecls(@This());
}
