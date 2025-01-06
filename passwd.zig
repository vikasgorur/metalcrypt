const c = @cImport({
    @cInclude("unistd.h");
});
const std = @import("std");

// Bit number 1 is always MSB in this file.

const IP_SPEC = [64]u8{
    58, 50, 42, 34, 26, 18, 10, 2,
    60, 52, 44, 36, 28, 20, 12, 4,
    62, 54, 46, 38, 30, 22, 14, 6,
    64, 56, 48, 40, 32, 24, 16, 8,
    57, 49, 41, 33, 25, 17, 9,  1,
    59, 51, 43, 35, 27, 19, 11, 3,
    61, 53, 45, 37, 29, 21, 13, 5,
    63, 55, 47, 39, 31, 23, 15, 7,
};

const IP_INV_SPEC = [64]u8{
    40, 8, 48, 16, 56, 24, 64, 32,
    39, 7, 47, 15, 55, 23, 63, 31,
    38, 6, 46, 14, 54, 22, 62, 30,
    37, 5, 45, 13, 53, 21, 61, 29,
    36, 4, 44, 12, 52, 20, 60, 28,
    35, 3, 43, 11, 51, 19, 59, 27,
    34, 2, 42, 10, 50, 18, 58, 26,
    33, 1, 41, 9,  49, 17, 57, 25,
};

test "Permutation specs have every bit position exactly once" {
    var set = std.bit_set.IntegerBitSet(64).initEmpty();
    for (IP_SPEC) |i| {
        set.set(i - 1);
    }
    try std.testing.expect(set.count() == 64);

    set = std.bit_set.IntegerBitSet(64).initEmpty();
    for (IP_INV_SPEC) |i| {
        set.set(i - 1);
    }
    try std.testing.expect(set.count() == 64);
}

/// Permute the bits of `in` according to `spec`.
fn permute(in: u64, spec: []const u8) u64 {
    var out: u64 = 0;
    for (spec, 0..spec.len) |pos, i| {
        const bit = (in >> @intCast(64 - pos)) & 1;
        out |= bit << @intCast(63 - i);
    }
    return out;
}

test "Permute" {
    // Test basic permutation
    const input: u64 = 0x0123456789ABCDEF;
    const output = permute(input, &IP_SPEC);
    try std.testing.expect(output != input); // Should change the value

    // Test that permuting twice with inverse specs returns original
    const restored = permute(output, &IP_INV_SPEC);
    try std.testing.expect(restored == input);

    // Test with all bits set
    const all_ones: u64 = 0xFFFFFFFFFFFFFFFF;
    try std.testing.expect(permute(all_ones, &IP_SPEC) == all_ones);

    // Test with single bit set
    const single_bit: u64 = 1 << 63; // MSB set
    const permuted_bit = permute(single_bit, &IP_SPEC);
    try std.testing.expect(@popCount(permuted_bit) == 1); // Should still have exactly one bit
}

pub fn main() void {
    const password = "STRANGEL";
    const hashed = c.crypt(password, "12");
    std.debug.print("Hashed password: {s}\n", .{hashed});
}
