const std = @import("std");
const math = std.math;
const ArrayList = std.ArrayList;

// [NOTE]: comptime support would be great, but don't know if it nicely plays
// with Python bindings. If bindings support comptime variables (not sure, since
// we're exposing something dinamically), BoundedArray can be used.

// @FIXME: add OOB error checking. We should store size to check also internal OOB
/// Dinamically alloacted bit array. Efficient set and unset operations given an
/// index.
pub const BitArray = struct {
    const Self = @This();

    memory: ArrayList(u64),
    size: usize,

    pub fn init(ally: std.mem.Allocator, size: usize) !Self {
        // Get the number of elements. Divide by 64 since we're using u64 as
        // base element.
        const vec_elts = try math.divCeil(usize, size, @as(usize, 64));
        // Create the vector
        var vec = try ArrayList(u64).initCapacity(ally, vec_elts);
        var i: usize = 0;
        while (i < vec_elts) : (i += 1) {
            vec.appendAssumeCapacity(0);
        }

        return Self{
            .memory = vec,
            .size = size,
        };
    }

    /// Deallocate this bit array
    pub fn deinit(self: Self) void {
        self.memory.deinit();
    }

    /// Set value and `idx`. If value was already set, do nothing.
    pub fn set(self: *Self, idx: usize) void {
        // Compute u64 bag and bit.
        const vec_idx = @divFloor(idx, @as(usize, 64));
        const bit = idx % 64;
        // Set to 1 the bit in the corresponding element.
        self.memory.items[vec_idx] |= math.shl(u64, 1, bit);
    }

    /// Unset value and `idx`. If value was already set, do nothing.
    pub fn unset(self: *Self, idx: usize) void {
        // Compute u64 bag and bit.
        const vec_idx = @divFloor(idx, @as(usize, 64));
        const bit = idx % 64;
        // Set to 1 the bit in the corresponding element.
        self.memory.items[vec_idx] &= ~math.shl(u64, 1, bit);
    }

    /// Check whether the value ad index `idx` is set.
    pub fn present(self: *const Self, idx: usize) bool {
        const vec_idx = @divFloor(idx, @as(usize, 64));
        const bit = idx % 64;
        return (self.memory.items[vec_idx] & math.shl(u64, 1, bit)) != 0;
    }

    /// Compute the number of bit set in the array.
    pub fn count(self: *const Self) usize {
        var c: usize = 0;
        var tmp: u64 = 0;
        // Kerninghan's way to compute bits set
        for (self.memory.items) |item| {
            tmp = item;
            while (tmp != 0) : (c += 1) {
                tmp &= tmp - 1;
            }
        }

        return c;
    }

    pub inline fn capacity(self: Self) usize {
        return self.size;
    }
};

const testing = std.testing;

test "bitarray" {
    var arr = try BitArray.init(testing.allocator, 100);
    defer arr.deinit();
    try testing.expectEqual(arr.memory.capacity, 2);

    arr.set(0);
    arr.set(23);
    arr.set(64);
    arr.set(65);

    try testing.expectEqual(arr.memory.items[0], (1 << 0) + (1 << 23));
    try testing.expectEqual(arr.memory.items[1], (1 << 0) + (1 << 1));
    try testing.expectEqual(arr.count(), 4);

    arr.set(65);
    try testing.expectEqual(arr.memory.items[1], (1 << 0) + (1 << 1));

    try testing.expect(arr.present(0));
    try testing.expect(arr.present(65));
    try testing.expect(!arr.present(1));
    try testing.expect(!arr.present(70));

    // change nothing
    arr.unset(25);
    try testing.expectEqual(arr.memory.items[0], (1 << 0) + (1 << 23));
    try testing.expectEqual(arr.memory.items[1], (1 << 0) + (1 << 1));

    arr.unset(64);
    try testing.expectEqual(arr.memory.items[0], (1 << 0) + (1 << 23));
    try testing.expectEqual(arr.memory.items[1], (1 << 1));

    arr.unset(64);
    try testing.expectEqual(arr.memory.items[1], (1 << 1));

    try testing.expectEqual(arr.count(), 3);
}
