pub const BloomFilter = @import("bloom.zig").BloomFilter;
pub const BitArray = @import("bitarr.zig").BitArray;
pub const fnv_128 = @import("hash.zig").fnv_128;

test {
    const testing = @import("std").testing;
    testing.refAllDeclsRecursive(BloomFilter);
    testing.refAllDeclsRecursive(BitArray);
    testing.refAllDeclsRecursive(@import("hash.zig"));
}
