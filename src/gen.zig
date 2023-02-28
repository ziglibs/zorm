const std = @import("std");
const json = std.json;

const Object = @import("./types/Object.zig");

/// Acceptable types of payloads for creation and deletion.
const Payload = union {
    /// JSON formatted multiline strings.
    /// Refer to the \\ trailing syntax for more information, and `std.json`.
    JsonString: []const u8,

    /// An anonymous struct literal that has *already* been initialised.
    Struct: type
};

/// Creates an object based off of a supplied payload.
///
/// Returns an `Object` upon successful serialisation of the payload to the object.
/// Serialisation is supported through two payload types.
///
/// An `Abnormal` error may be returned in the event that serialisation fails.
pub fn create(object: Object, comptime payload: Payload) error {Abnormal}!Object {
    switch (payload) {
        .JsonString => {
            const parsed = try json.parse(object, .init(payload), .{
                .duplicate_field_behavior = .Error,
                .allow_trailing_data = true
            });
            return parsed;
        },
        .Struct => {
            return Object(payload);
        }
    }
}