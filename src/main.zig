pub const BloomFilter = @import("bloom.zig").BloomFilter;
pub const BitArray = @import("bitarr.zig").BitArray;
pub const fnv_1 = @import("hash.zig").fnv_1;
pub const fnv_1a = @import("hash.zig").fnv_1a;

test {
    const testing = @import("std").testing;
    testing.refAllDeclsRecursive(BloomFilter);
    testing.refAllDeclsRecursive(BitArray);
    testing.refAllDeclsRecursive(@import("hash.zig"));
}
