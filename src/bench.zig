const std = @import("std");

const sieve = @import("sieve.zig");

const MEAN = 50.0;
const ARRAY_SIZE = 12;
const NUM_ITERS = 1000;
const CACHE_CAPACITY = 68;
const STD_DEV = MEAN / 3.0;
const MAX_BUF_SIZE = 1 << 12;

pub fn main() !void {
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) @panic("Memory leaked!");

    var stdout_buf: [MAX_BUF_SIZE]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const writer = &stdout_writer.interface;

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    var buf: [MAX_BUF_SIZE]u8 = undefined;
    var fixed_buf: std.heap.FixedBufferAllocator = .init(&buf);
    const args = try std.process.argsAlloc(fixed_buf.allocator());

    switch (args[1][0]) {
        's' => try benchmarkSequence(gpa, writer),
        'c' => try benchmarkComposite(gpa, random, writer),
        'n' => try benchmarkCompositeNormal(gpa, random, writer),
        else => @panic("Unknown benchmark!"),
    }

    try writer.flush();
}

fn benchmarkSequence(gpa: std.mem.Allocator, writer: anytype) !void {
    const Cache = sieve.Cache(u64, u64);
    var cache: Cache = try .init(gpa, CACHE_CAPACITY);
    defer cache.deinit(gpa);

    var timer = try std.time.Timer.start();
    const start = timer.lap();

    var node: *Cache.Node = undefined;
    var num: u64 = undefined;
    var i: u64 = 1;
    while (i < NUM_ITERS) : (i += 1) {
        num = i % 100;
        node = try gpa.create(Cache.Node);
        node.* = .{ .key = num, .value = num };
        _ = cache.put(node);
    }

    while (i < NUM_ITERS) : (i += 1) {
        num = i % 100;
        _ = cache.get(num);
    }

    try writer.print("Sequence: {D}\n", .{timer.read() - start});
}

fn benchmarkComposite(gpa: std.mem.Allocator, random: std.Random, writer: anytype) !void {
    const Cache = sieve.Cache(u64, struct { [ARRAY_SIZE]u8, u64 });
    var cache: Cache = try .init(gpa, CACHE_CAPACITY);
    defer cache.deinit(gpa);

    var timer = try std.time.Timer.start();
    const start = timer.lap();

    var node: *Cache.Node = undefined;
    var num: u64 = undefined;
    var i: u64 = 1;
    while (i < NUM_ITERS) : (i += 1) {
        num = random.uintLessThan(u64, 100);
        node = try gpa.create(Cache.Node);
        node.* = .{ .key = num, .value = .{ @splat(0), num } };
        _ = cache.put(node);
    }

    while (i < NUM_ITERS) : (i += 1) {
        num = random.uintLessThan(u64, 100);
        _ = cache.get(num);
    }

    try writer.print("Composite: {D}\n", .{timer.read() - start});
}

fn benchmarkCompositeNormal(gpa: std.mem.Allocator, random: std.Random, writer: anytype) !void {
    const Cache = sieve.Cache(u64, struct { [ARRAY_SIZE]u8, u64 });
    var cache: Cache = try .init(gpa, @intFromFloat(STD_DEV));
    defer cache.deinit(gpa);

    var timer = try std.time.Timer.start();
    const start = timer.lap();

    var node: *Cache.Node = undefined;
    var num: u64 = undefined;
    var i: u64 = 1;
    while (i < NUM_ITERS) : (i += 1) {
        num = @intFromFloat(random.floatNorm(f64) * STD_DEV + MEAN);
        num %= 100;
        node = try gpa.create(Cache.Node);
        node.* = .{ .key = num, .value = .{ @splat(0), num } };
        _ = cache.put(node);
    }

    while (i < NUM_ITERS) : (i += 1) {
        num = @intFromFloat(random.floatNorm(f64) * STD_DEV + MEAN);
        num %= 100;
        _ = cache.get(num);
    }

    try writer.print("Composite Normal: {D}\n", .{timer.read() - start});
}
