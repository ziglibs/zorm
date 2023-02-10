const std = @import("std");
const Object = @import("./types/Object.zig");

/// Acceptable types of payloads for creation and deletion.
const Payload = union {
    /// JSON formatted multiline strings.
    /// Refer to the \\ trailing syntax for more information, and `std.json`.
    json: []const u8,

    /// A structure that has *already* been initialised.
    structure: type
};

/// Creates an object based off of a supplied payload.
///
/// Returns an `Object` upon successful serialisation of the payload to the object.
/// Serialisation is supported through two payload types.
///
/// An `Abnormal` error may be returned in the event that serialisation fails.
pub fn create(object: Object, comptime payload: Payload) error {Abnormal}!Object {
    _ = object;

    if (@TypeOf(payload) == []const u8)
        return error.Abnormal;
}