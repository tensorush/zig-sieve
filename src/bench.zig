const std = @import("std");
const sieve = @import("sieve.zig");

const MEAN: f64 = 50.0;
const ARRAY_SIZE: u64 = 12;
const NUM_ITERS: u64 = 1000;
const CACHE_CAPACITY: u64 = 68;
const STD_DEV: f64 = MEAN / 3.0;

pub fn main() !void {
    var gpa_state = std.heap.DebugAllocator(.{}){};
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    var buf: [512]u8 = undefined;
    var fixed_buf = std.heap.FixedBufferAllocator.init(buf[0..]);
    const args = try std.process.argsAlloc(fixed_buf.allocator());

    switch (args[1][1]) {
        's' => try benchmarkSequence(gpa, writer),
        'c' => try benchmarkComposite(gpa, random, writer),
        'n' => try benchmarkCompositeNormal(gpa, random, writer),
        else => @panic("Unknown benchmark!"),
    }

    try buf_writer.flush();
}

fn benchmarkSequence(gpa: std.mem.Allocator, writer: anytype) !void {
    const Cache = sieve.Cache(u64, u64);
    var cache = try Cache.init(gpa, CACHE_CAPACITY);
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
        _ = try cache.put(node);
    }

    while (i < NUM_ITERS) : (i += 1) {
        num = i % 100;
        _ = cache.get(num);
    }

    try writer.print("Sequence: {}\n", .{std.fmt.fmtDuration(timer.read() - start)});
}

fn benchmarkComposite(gpa: std.mem.Allocator, random: std.Random, writer: anytype) !void {
    const Cache = sieve.Cache(u64, struct { [ARRAY_SIZE]u8, u64 });
    var cache = try Cache.init(gpa, CACHE_CAPACITY);
    defer cache.deinit(gpa);

    var timer = try std.time.Timer.start();
    const start = timer.lap();

    var node: *Cache.Node = undefined;
    var num: u64 = undefined;
    var i: u64 = 1;
    while (i < NUM_ITERS) : (i += 1) {
        num = random.uintLessThan(u64, 100);
        node = try gpa.create(Cache.Node);
        node.* = .{ .key = num, .value = .{ [1]u8{0} ** ARRAY_SIZE, num } };
        _ = try cache.put(node);
    }

    while (i < NUM_ITERS) : (i += 1) {
        num = random.uintLessThan(u64, 100);
        _ = cache.get(num);
    }

    try writer.print("Composite: {}\n", .{std.fmt.fmtDuration(timer.read() - start)});
}

fn benchmarkCompositeNormal(gpa: std.mem.Allocator, random: std.Random, writer: anytype) !void {
    const Cache = sieve.Cache(u64, struct { [ARRAY_SIZE]u8, u64 });
    var cache = try Cache.init(gpa, @intFromFloat(STD_DEV));
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
        node.* = .{ .key = num, .value = .{ [1]u8{0} ** ARRAY_SIZE, num } };
        _ = try cache.put(node);
    }

    while (i < NUM_ITERS) : (i += 1) {
        num = @intFromFloat(random.floatNorm(f64) * STD_DEV + MEAN);
        num %= 100;
        _ = cache.get(num);
    }

    try writer.print("Composite Normal: {}\n", .{std.fmt.fmtDuration(timer.read() - start)});
}
