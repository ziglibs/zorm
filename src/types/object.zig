const std = @import("std");
const heap = std.heap;

const UUID = @import("UUID.zig");

/// An item container for fields of an "object."
///
/// Objects are nothing more than structs with implicitly defined identifiers added in.
/// An object will always have access to an Allocator and UUID. To actually define the
/// fields you want, you must use Field containing the type and potential field metadata.
///
/// A Model type is returned which acts as an abstraction layer between the anonymous struct
/// literal and the implicitly added identifiers.
pub fn Object(
    /// An anonymous struct literal with fields you wish the object to have.
    /// Items must use Field in order to be validated properly:
    ///
    /// .{
    ///     Field(?[]u8, .{ .desc = "Something for foo", .default = 'hello' }),
    ///     Field(usize, .{})
    /// }
    comptime T: type
) type {
    return struct {
        const Model = @This();

        /// UUID of the model. Implicitly created for you, with the option to provide your own.
        id = UUID.init(),

        /// The fields of the model. To access their contents, you will need to iterate
        /// through each field. Type information will always be present.
        fields: []Field = T,

        // Our allocator for storing empty pointers and referencing field data.
        allocator = heap.GeneralPurposeAllocator(.{}),

        /// Removes all memory space within the UUID.
        pub fn deinit(self: Model) void {
            self.* = undefined;
        }
    };
}

const FieldMetadata = struct {
    /// The description of the field when compiling to a Data Definition Language (.DDL) file.
    desc: ?[]const u8,

    /// What the potential default value may be.
    default: ?anytype
};

/// A field to go within an Object.
///
/// Anonymous struct literals are concatenated within the Object when providing the final Modal
/// type. Because of this, we have to resort to defining things such as the type we want, and
/// additional metadata unique to the field.
///
pub fn Field(
    /// The type that the field is supplied with.
    /// Fields will extract the type information provided, including optionality.
    comptime T: type,

    /// Additional metadata to be applied onto the field.
    data: ?FieldMetadata
) type {
    return struct {
        f_type: T = T,
        f_metadata: ?FieldMetadata = data
    };
}