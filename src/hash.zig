const std = @import("std");
const rand = std.rand;
const time = std.time;

/// Computes the FNV hashing algorithm
pub fn fnv_1(bytes: []const u8) u64 {
    var hash: u64 = 0xcbf29ce484222325;
    const fnv_prime: u64 = 0x100000001b3;
    for (bytes) |byte| {
        // allow overflow
        hash *%= fnv_prime;
        hash = @as(u64, byte) ^ hash;
    }
    return hash;
}

/// Inverse FNV hashing
pub fn fnv_1a(bytes: []const u8) u64 {
    var hash: u64 = 0xcbf29ce484222325;
    const fnv_prime: u64 = 0x100000001b3;
    for (bytes) |byte| {
        hash = @as(u64, byte) ^ hash;
        // allow overflow
        hash *%= fnv_prime;
    }
    return hash;
}

/// Jenkins hash function
pub fn jenkins(bytes: []const u8) u64 {
    var hash: u64 = 0;
    for (bytes) |byte| {
        hash +%= byte;
        hash +%= hash << 10;
        hash ^= hash >> 6;
    }
    hash +%= hash << 3;
    hash ^= hash >> 11;
    hash +%= hash << 15;
    return hash;
}

/// Elf hashing function
pub fn elf(bytes: []const u8) u64 {
    var hash: u64 = 0;
    var high: u64 = 0;
    for (bytes) |byte| {
        hash = (hash << 4) +% byte;
        high = hash & 0xF0000000;
        if (high == 0) {
            hash ^= high >> 24;
        }
        hash &= ~high;
    }
    return hash;
}

/// FNV variant that generates 128 bit hash
pub fn fnv_128(bytes: []const u8) u128 {
    var hash: u128 = 0x6c62272e07bb014262b821756295c58d;
    const fnv_prime: u128 = 0x0000000001000000000000000000013B;
    for (bytes) |byte| {
        // allow overflow
        hash *%= fnv_prime;
        hash = @as(u128, byte) ^ hash;
    }
    return hash;
}

/// Generates multiple hashes starting from a single hash value.
/// The formula to generate the n-th hash function is:
///     g_n = h_1 + n * h_2
/// where h_1 and h_2 are the lower and upper part of the input hash.
///
/// Refer to https://www.eecs.harvard.edu/~michaelm/postscripts/tr-02-05.pdf
pub fn generate_nth_hash(hash: u128, k: usize) u64 {
    var hash1: u64 = @truncate(hash); // init the hash with lower 64 bits
    const hash2: u64 = @truncate(hash >> 64); // second hash is upper 64 bits
    var step: usize = 0;
    while (step <= k) : (step += 1) {
        hash1 +%= step *% hash2;
    }
    return hash1;
}

test "bit shifting" {
    const v: u16 = 0xFF00;
    try std.testing.expect(@as(u8, @truncate(v)) == 0x00);
    try std.testing.expect(@as(u8, @truncate((v >> 8))) == 0xFF);
}

test "generate hash" {
    const h = fnv_128("ciao");
    var i: usize = 0;
    var hashed: u64 = 0;
    var tmp: u64 = 0;
    while (i < 10) : (i += 1) {
        tmp = generate_nth_hash(h, i);
        try std.testing.expect(tmp != hashed);
        hashed = tmp;
    }
}

test "AND operator" {
    try std.testing.expect((0x0aaa & 0xF000) == 0);
    try std.testing.expect((0x0000 & 0xF000) == 0);
    try std.testing.expect((0x2000 & 0xF000) != 0);
}
