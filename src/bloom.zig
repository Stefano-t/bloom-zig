const std = @import("std");
const bitarray = @import("bitarr.zig");
const BitArray = bitarray.BitArray;
const GeneralPurposeAllocator = std.head.GeneralPurposeAllocator;

// @Question: is this the correct way to init an allocator that will be used through the application?
var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = general_purpose_allocator.allocator();

/// Simple implementation of a bloom filter.
/// The hashing strategy generates n hashes on the fly, using a technique explained here:
/// Refer to https://www.eecs.harvard.edu/~michaelm/postscripts/tr-02-05.pdf
pub const BloomFilter = struct {
    const Self = @This();

    buffer: BitArray,
    n_hash: usize,

    /// Initialize a bloom filter of size `size` and `n_hash` hash functions
    pub fn init(size: usize, n_hash: usize) !Self {
        return Self{ .buffer = try BitArray.init(allocator, size), .n_hash = n_hash };
    }

    /// Release underlying array memory
    pub fn deinit(self: *Self) void {
        self.buffer.deinit();
    }

    /// Add the input hash to the filter
    pub fn add(self: *Self, hash: u128) void {
        var hash1 = @as(u64, @truncate(hash)); // init the hash with lower 64 bits
        const hash2 = @as(u64, @truncate(hash >> 64)); // second hash is upper 64 bits

        var i: usize = 0;
        while (i < self.n_hash) : (i += 1) {
            hash1 +%= i *% hash2;
            self.buffer.set(hash1 % self.buffer.capacity());
        }
    }

    /// Check if the the hash is inside the filter
    pub fn present(self: *const Self, hash: u128) bool {
        var hash1 = @as(u64, @truncate(hash));
        const hash2 = @as(u64, @truncate(hash >> 64));

        var bit_set: usize = 0;
        var i: usize = 0;
        while (i < self.n_hash) : (i += 1) {
            hash1 +%= i *% hash2;
            if (self.buffer.present(hash1 % self.buffer.capacity())) {
                bit_set += 1;
            }
        }
        return bit_set == self.n_hash;
    }

    /// Returns the number of bits set in the underlying filter
    pub fn count(self: *const Self) usize {
        return self.buffer.count();
    }
};

const testing = std.testing;

test "bloom filter" {
    var filter = try BloomFilter.init(100, 5);
    defer filter.deinit();
    filter.add(@as(u128, 10));
    filter.add(@as(u128, 20));
    try testing.expect(filter.present(10));
    try testing.expect(filter.present(20));
    try testing.expect(!filter.present(30));
    try testing.expect(!filter.present(0));
    // Even if we're using 5 distinct hash functions, we're supplying a very pathological case as input.
    // In general, we would except 10 (even if there might be collisions)
    try testing.expectEqual(@as(usize, 2), filter.count());
    filter.add(@as(u128, 2 << 121));
    try testing.expectEqual(@as(usize, 7), filter.count());
}

test "add complex object" {
    const FVN = std.hash.Fnv1a_128;
    var bloom = try BloomFilter.init(1000, 5);
    const obj = "ciao come stai";
    bloom.add(FVN.hash(std.mem.asBytes(obj)));
    try testing.expectEqual(@as(usize, 5), bloom.buffer.count());
}

test "mem hash" {
    const str = "ciao";
    const FVN = std.hash.Fnv1a_128;
    std.log.warn("str: {s}, hash {d}\n", .{ str, FVN.hash(std.mem.asBytes(str)) });
    const x = "ciao";
    std.log.warn("str: {s}, hash {d}\n", .{ x, FVN.hash(std.mem.asBytes(x)) });
    const i: u32 = 10;
    std.log.warn("int: {d}, hash {d}\n", .{ i, FVN.hash(std.mem.asBytes(&i)) });
    const j: u64 = 10;
    std.log.warn("int: {d}, hash {d}\n", .{ j, FVN.hash(std.mem.asBytes(&j)) });
    const h: u64 = 10;
    std.log.warn("int: {d}, hash {d}\n", .{ h, FVN.hash(std.mem.asBytes(&h)) });
}

test "hashing object" {
    const str = "ciao";
    const autoHash = std.hash.autoHash;
    var hasher = std.hash.Wyhash.init(0);
    const x = "ciao";
    autoHash(&hasher, x);
    std.log.warn("str: {s}, hash {d}\n", .{ x, hasher.final() });
    autoHash(&hasher, hasher);
    std.log.warn("hash: {d}\n", .{hasher.final()});
    autoHash(&hasher, str);
    std.log.warn("str: {s}, hash {d}\n", .{ str, hasher.final() });
}
