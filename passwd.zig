const c = @cImport({
    @cInclude("unistd.h");
});
const std = @import("std");
const math = std.math;

const specs = @import("./specs.zig");

// Bit number 1 is always MSB in this file.

/// S boxes
/// Permute the bits of `in` according to `spec`.
fn permute(in: u64, spec: []const u8) u64 {
    var out: u64 = 0;
    for (spec, 0..spec.len) |pos, i| {
        const bit = (in >> @intCast(64 - pos)) & 1;
        out |= bit << @intCast(63 - i);
    }
    return out;
}

fn initialPermutation(in: u64) u64 {
    return permute(in, &specs.IP_SPEC);
}

fn finalPermutation(in: u64) u64 {
    return permute(in, &specs.IP_INV_SPEC);
}

fn dropParityBits(in: u64) u64 {
    return permute(in, &specs.DROP_PARITY_BITS_SPEC) >> 8;
}

// Split the 56-bit key into two 28-bit halves, shift both according to the
// round schedule and return the combined 56-bit key
fn keyShift(round: u8, key: u64) u64 {
    const left = key & 0b0000000011111111111111111111111111110000000000000000000000000000;
    const right = key & 0b0000000000000000000000000000000000001111111111111111111111111111;

    const shift = @as(usize, specs.KEY_SHIFT_SCHEDULE[round]);

    return (math.rotl(u64, left, shift) << 28) | math.rotl(u64, right, shift);
}

fn compressionPermutation(key: u64) u64 {
    return permute(key, &specs.COMPRESSION_SPEC) >> 16;
}

// Expand the 32-bit right half into 48-bits using the expansion
// permutation
fn expansionPermutation(input: u64) u64 {
    return permute(input, &specs.EXPANSION_SPEC);
}

fn pBoxPermutation(input: u32) u32 {
    return permute(input, &specs.P_BOX_SPEC);
}

fn feistelRound(round: u8, in: u64, key: u64) u64 {
    const left = in & ((1 << 32) - 1) << 32;
    const right = in & ((1 << 32) - 1);

    const roundKey = compressionPermutation(keyShift(round, key));
    const sBoxInput = expansionPermutation(right) ^ roundKey;
    return left | right ^ sBoxInput;
}

fn crypt(input: u64) u64 {
    return input;
}

fn cryptCommand(password: []const u8) void {
    if (password.len != 8) {
        std.debug.print("password must be exactly 8 characters\n", .{});
        std.process.exit(1);
    }

    // crypt(3) requires a null-terminated string
    var pass_buf: [9:0]u8 = undefined;
    @memcpy(pass_buf[0..password.len], password[0..password.len]);
    pass_buf[password.len] = 0;

    // Use "aa" as the salt
    const salt = "aa";

    const result = c.crypt(&pass_buf, salt);
    if (result == null) {
        std.debug.print("crypt failed\n", .{});
        return;
    }

    // Print the hash
    const hash = std.mem.span(result);
    std.debug.print("{s}\n", .{hash});
}

fn crackCommand(_: []const u8) void {
    std.debug.print("not implemented\n", .{});
}

pub fn main() void {
    const help =
        \\ Usage:
        \\   passwd crypt <password>
        \\   passwd crack <hash>
        \\
    ;
    var args = std.process.args();
    _ = args.skip(); // skip program name

    var argv: [2][:0]const u8 = undefined;
    var i: usize = 0;

    while (args.next()) |arg| {
        if (i >= 2) break;
        argv[i] = arg;
        i += 1;
    }

    if (i < 2) {
        std.debug.print("{s}", .{help});
        std.process.exit(1);
    }

    const command = argv[0];
    const arg = argv[1];

    if (std.mem.eql(u8, command, "crypt")) {
        cryptCommand(arg);
    } else if (std.mem.eql(u8, command, "crack")) {
        crackCommand(arg);
    } else {
        std.debug.print("{s}", .{help});
        std.process.exit(1);
    }
}

test "permutation specs have every bit position exactly once" {
    // We need this to be 65 because the DES standard numbers the bits 1..64.
    var set = std.bit_set.IntegerBitSet(65).initEmpty();
    for (specs.IP_SPEC) |i| {
        set.set(i);
    }
    try std.testing.expect(set.count() == 64);

    set = std.bit_set.IntegerBitSet(65).initEmpty();
    for (specs.IP_INV_SPEC) |i| {
        set.set(i);
    }
    try std.testing.expect(set.count() == 64);
}

test "drop parity bits ignores every 8th bit" {
    var bits = std.bit_set.IntegerBitSet(65).initEmpty();
    for (specs.DROP_PARITY_BITS_SPEC) |i| {
        bits.set(i);
    }

    for (1..8) |i| {
        try std.testing.expect(!bits.isSet(i * 8));
    }
}

test "drop parity bits example" {
    const key = 0b0001001100110100010101110111100110011011101111001101111111110001;
    const reduced = 0b11110000110011001010101011110101010101100110011110001111;
    try std.testing.expect(dropParityBits(key) == reduced);
}

test "permute" {
    // Test basic permutation
    const input: u64 = 0x0123456789ABCDEF;
    const output = permute(input, &specs.IP_SPEC);
    try std.testing.expect(output != input); // Should change the value

    // Test that permuting twice with inverse specs returns original
    const restored = permute(output, &specs.IP_INV_SPEC);
    try std.testing.expect(restored == input);

    // Test with all bits set
    const all_ones: u64 = 0xFFFFFFFFFFFFFFFF;
    try std.testing.expect(permute(all_ones, &specs.IP_SPEC) == all_ones);

    // Test with single bit set
    const single_bit: u64 = 1 << 63; // MSB set
    const permuted_bit = permute(single_bit, &specs.IP_SPEC);
    try std.testing.expect(@popCount(permuted_bit) == 1); // Should still have exactly one bit
}
