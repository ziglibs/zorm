const std = @import("std");
const crypto = std.crypto;
const testing = std.testing;
const mem = std.mem;
const log = std.log.scoped(.uuid);

/// A universally unique identifier (UUID), guaranteed to be cryptographically random
/// between sixteen 8-bit integers.
///
/// The "octets" are the random bytes of the UUID itself. This UUID implementation is
/// for version 4, with a 6-7 bit variation to dictate precadnence. There are a total of
/// 5.3 x 10^36 possible UUIDs.
pub const UUID = @This();

/// The pieces of data stored within the UUID. Used for internal purposes.
octets: [16]u8,

// The stored indices of specific bit ranges for string representation
const encoded = [16]u8{ 0, 2, 4, 6, 9, 11, 14, 16, 19, 21, 24, 26, 28, 30, 32, 34 };

/// Creates a new UUID.
/// A UUID will be created as version 4 with variant 1.
pub fn init() UUID {
    var uuid = UUID{ .octets = undefined };

    crypto.random.bytes(&uuid.octets); // fuck your blackjack.
    // Denote as version 4
    uuid.octets[6] = (uuid.octets[6] & 0x0f) | 0x40;
    // Declare variant 1
    uuid.octets[8] = (uuid.octets[8] & 0x3f) | 0x80;

    return uuid;
}

/// Removes all memory space within the UUID.
pub fn deinit(self: *UUID) void {
    self = undefined;
}

/// Converts a UUID to a string.
///
/// UUID strings are guaranteed to be 36 characters long in length. A malformed conversion
/// of one is impossible, and if such an event were to happen, the UUID should immediately
/// be disposed of.
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
    for (encoded, 0..) |index, val| {
        buffer[index + 0] = hex_set[self.octets[val] >> 4];
        buffer[index + 1] = hex_set[self.octets[val] & 0x0f];
    }

    return @as([]const u8, &buffer);
}

test "Create UUID" {
    var uuid = UUID.init();
    try testing.expect(&uuid.octets != undefined);

    log.debug("{s}", .{uuid.toString()});
}

test "Check UUID string" {
    var uuid = UUID.init();
    const uuid_string = uuid.toString();

    try testing.expect(uuid_string.len == 36);

    log.debug("{s}, {}/36\n", .{ uuid_string, uuid_string.len });
}
