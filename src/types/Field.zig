const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const log = std.log.scoped(.field);

const FieldMetadata = struct {
    /// The name of the field.
    name: []const u8,

    /// The description of the field.
    desc: ?[]const u8 = undefined,

    /// What the potential default value may be.
    default: ?comptime_int = undefined,
};

/// A field to go within an object.
///
/// Anonymous struct literals are concatenated within the object when providing the final Modal
/// type. Because of this, we have to resort to defining things such as the type we want, and
/// additional metadata unique to the field.
pub fn Field(comptime T: type, comptime data: ?FieldMetadata) type {
    return struct {
        /// The field type. Use @TypeOf() builtin for the child type of the field.
        f_type: T = T,

        /// The field metadata.
        f_metadata: ?FieldMetadata = data,
    }{};
}

test "Create required field" {
    const field = Field([]const u8, .{ .name = "foo" });

    try testing.expect(field.f_type == []const u8);
    try testing.expect(mem.eql(u8, field.f_metadata.name, "foo"));
}

test "Create optional field" {
    const field = Field(?usize, .{ .name = "bar", .default = 10 });

    try testing.expect(field.f_type == ?usize);
    try testing.expect(field.f_metadata.default == 10);
}
