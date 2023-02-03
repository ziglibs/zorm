const std = @import("std");
const crypto = std.crypto;

const UUID = @This();

/// The pieces of data stored within the UUID
octets: [16]u8,

/// The stored indices of specific bit ranges for string representation
const encoded = [16]u8{ 0, 2, 4, 6, 9, 11, 14, 16, 19, 21, 24, 26, 28, 30, 32, 34 };

/// Creates a new UUID
pub fn init() UUID {
    var uuid = UUID{ .octets = undefined };

    crypto.random.bytes(&uuid.octets);
    // Denote as version 4
    uuid.octets[6] = (uuid.octets[6] & 0x0f) | 0x40;
    // Declare variant 1
    uuid.octets[8] = (uuid.octets[8] & 0x3f) | 0x80;

    return uuid;
}

/// Allocs the UUID and sets undefined space to the UUID (removing it)
pub fn deinit(self: *UUID) void {
    self = undefined;
}

/// Converts a given existing UUID structure to a string
pub fn toString(self: *UUID) []const u8 {
    // UUID 4 values are 36 characters in total
    var buffer: [36]u8 = undefined;
    const hex_set = "0123456789abcdef";

    // Set group spacers for delimiting
    buffer[8] = '-';
    buffer[13] = '-';
    buffer[18] = '-';
    buffer[23] = '-';

    // Iterate through all stored indices known and bitshift to a random cryptographic value
    for (encoded) |index, val| {
      buffer[index + 0] = hex_set[self.octets[val] >> 4];
      buffer[index + 1] = hex_set[self.octets[val] & 0x0f];
    }

    return @as([]const u8, &buffer);
}