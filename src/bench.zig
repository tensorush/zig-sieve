//! Root benchmark file that measures SIEVE eviction algorithm's performance.

const std = @import("std");
const sieve = @import("sieve.zig");

const MEAN: f64 = 50.0;
const ARRAY_SIZE: u64 = 12;
const NUM_ITERS: u64 = 1000;
const CACHE_CAPACITY: u64 = 68;
const STD_DEV: f64 = MEAN / 3.0;

pub fn main() !void {
    // Arena allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    // Standard output
    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    // Number generator
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    // "Sequence" benchmark
    {
        const Cache = sieve.Cache(u64, u64);
        var cache = try Cache.init(allocator, CACHE_CAPACITY);
        defer cache.deinit(allocator);

        var timer = try std.time.Timer.start();
        const start = timer.lap();

        var node: *Cache.Node = undefined;
        var num: u64 = undefined;
        var i: u64 = 1;
        while (i < NUM_ITERS) : (i += 1) {
            num = i % 100;
            node = try allocator.create(Cache.Node);
            node.* = .{ .key = num, .value = num };
            _ = try cache.put(node);
        }

        while (i < NUM_ITERS) : (i += 1) {
            num = i % 100;
            _ = cache.get(num);
        }

        try writer.print("Sequence: {}\n", .{std.fmt.fmtDuration(timer.read() - start)});
    }

    // "Composite" benchmark
    {
        const Cache = sieve.Cache(u64, struct { [ARRAY_SIZE]u8, u64 });
        var cache = try Cache.init(allocator, CACHE_CAPACITY);
        defer cache.deinit(allocator);

        var timer = try std.time.Timer.start();
        const start = timer.lap();

        var node: *Cache.Node = undefined;
        var num: u64 = undefined;
        var i: u64 = 1;
        while (i < NUM_ITERS) : (i += 1) {
            num = random.uintLessThan(u64, 100);
            node = try allocator.create(Cache.Node);
            node.* = .{ .key = num, .value = .{ [1]u8{0} ** ARRAY_SIZE, num } };
            _ = try cache.put(node);
        }

        while (i < NUM_ITERS) : (i += 1) {
            num = random.uintLessThan(u64, 100);
            _ = cache.get(num);
        }

        try writer.print("Composite: {}\n", .{std.fmt.fmtDuration(timer.read() - start)});
    }

    // "Composite Normal" benchmark
    {
        const Cache = sieve.Cache(u64, struct { [ARRAY_SIZE]u8, u64 });
        var cache = try Cache.init(allocator, @intFromFloat(STD_DEV));
        defer cache.deinit(allocator);

        var timer = try std.time.Timer.start();
        const start = timer.lap();

        var node: *Cache.Node = undefined;
        var num: u64 = undefined;
        var i: u64 = 1;
        while (i < NUM_ITERS) : (i += 1) {
            num = @intFromFloat(random.floatNorm(f64) * STD_DEV + MEAN);
            num %= 100;
            node = try allocator.create(Cache.Node);
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

    try buf_writer.flush();
}
