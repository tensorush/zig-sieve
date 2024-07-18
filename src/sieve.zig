//! Root library file that exposes the public API.

const std = @import("std");

/// Intrusive cache based on the SIEVE eviction algorithm.
pub fn Cache(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();
        const HashMapUnmanaged = if (K == []const u8) std.StringHashMapUnmanaged(*Node) else std.AutoHashMapUnmanaged(K, *Node);

        /// Intrusive cache's node.
        pub const Node = struct {
            is_visited: bool = false,
            prev: ?*Node = null,
            next: ?*Node = null,
            value: V,
            key: K,
        };

        map: HashMapUnmanaged = HashMapUnmanaged{},
        hand: ?*Node = null,
        head: ?*Node = null,
        tail: ?*Node = null,

        /// Initialize cache with given capacity.
        pub fn init(allocator: std.mem.Allocator, capacity: u32) !Self {
            var self = Self{};
            try self.map.ensureTotalCapacity(allocator, capacity);
            return self;
        }

        /// Deinitialize cache.
        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.map.deinit(allocator);
            self.* = undefined;
        }

        /// Check if cache is empty.
        pub fn isEmpty(self: Self) bool {
            return self.map.size == 0;
        }

        /// Check if cache contains given key.
        pub fn contains(self: Self, key: K) bool {
            return self.map.contains(key);
        }

        /// Retrieve value associated with given key, otherwise return `null`.
        pub fn get(self: Self, key: K) ?V {
            var node = self.map.get(key) orelse return null;
            node.is_visited = true;
            return node.value;
        }

        /// Put node pointer and return `true` if associated key is not already present.
        /// Otherwise, put node pointer, evicting old entry, and return `false`.
        pub fn put(self: *Self, node: *Node) !bool {
            if (self.map.getPtr(node.key)) |old_node| {
                node.is_visited = true;
                old_node.* = node;
                return false;
            } else {
                if (self.map.size >= self.map.capacity()) {
                    self.evict();
                }

                node.next = self.head;
                if (self.head) |head| {
                    head.prev = node;
                }

                self.head = node;
                if (self.tail == null) {
                    self.tail = self.head;
                }

                self.map.putAssumeCapacityNoClobber(node.key, node);
                return true;
            }
        }

        /// Remove key and return associated value, otherwise return `null`.
        pub fn fetchRemove(self: *Self, key: K) ?V {
            const node = self.map.get(key) orelse return null;
            if (self.hand == node) {
                self.hand = node.prev;
            }
            _ = self.map.remove(key);
            self.removeNode(node);
            return node.value;
        }

        fn removeNode(self: *Self, node: *Node) void {
            if (node.prev) |prev| {
                prev.next = node.next;
            } else {
                self.head = node.next;
            }

            if (node.next) |next| {
                next.prev = node.prev;
            } else {
                self.tail = node.prev;
            }
        }

        fn evict(self: *Self) void {
            var node_opt = self.hand orelse self.tail;
            while (node_opt) |node| : (node_opt = node.prev orelse self.tail) {
                if (!node.is_visited) {
                    break;
                }
                node.is_visited = false;
            }
            if (node_opt) |node| {
                self.hand = node.prev;
                _ = self.map.remove(node.key);
                self.removeNode(node);
            }
        }
    };
}

test Cache {
    {
        const StringCache = Cache([]const u8, []const u8);

        var cache = try StringCache.init(std.testing.allocator, 3);
        defer cache.deinit(std.testing.allocator);

        var zigzag_node = StringCache.Node{ .key = "zig", .value = "zag" };
        var foobar_node = StringCache.Node{ .key = "foo", .value = "bar" };
        var flipflop_node = StringCache.Node{ .key = "flip", .value = "flop" };
        var ticktock_node = StringCache.Node{ .key = "tick", .value = "tock" };

        try std.testing.expect(try cache.put(&zigzag_node));
        try std.testing.expect(try cache.put(&foobar_node));

        try std.testing.expectEqualStrings("bar", cache.fetchRemove("foo").?);

        try std.testing.expect(try cache.put(&flipflop_node));
        try std.testing.expect(try cache.put(&ticktock_node));

        try std.testing.expectEqualStrings("zag", cache.get("zig").?);
        try std.testing.expectEqual(cache.get("foo"), null);
        try std.testing.expectEqualStrings("flop", cache.get("flip").?);
        try std.testing.expectEqualStrings("tock", cache.get("tick").?);
    }
    {
        const StringCache = Cache([]const u8, []const u8);

        var cache = try StringCache.init(std.testing.allocator, 3);
        defer cache.deinit(std.testing.allocator);

        var zigzag_node = StringCache.Node{ .key = "zig", .value = "zag" };
        var zigupd_node = StringCache.Node{ .key = "zig", .value = "upd" };
        var foobar_node = StringCache.Node{ .key = "foo", .value = "bar" };
        var flipflop_node = StringCache.Node{ .key = "flip", .value = "flop" };

        try std.testing.expect(try cache.put(&zigzag_node));
        try std.testing.expect(try cache.put(&foobar_node));
        try std.testing.expect(!try cache.put(&zigupd_node));
        try std.testing.expect(try cache.put(&flipflop_node));

        try std.testing.expectEqualStrings("upd", cache.get("zig").?);
    }
}
