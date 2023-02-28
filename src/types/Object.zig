const UUID = @import("UUID.zig").UUID;
const Field = @import("Field.zig").Field;

/// An item container for fields of an "object."
///
/// Objects are nothing more than structs with implicitly defined identifiers added in.
/// An object will always have access to an Allocator and UUID. To actually define the
/// fields you want, you must use Field containing the type and potential field metadata.
///
/// A Model type is returned which acts as an abstraction layer between the anonymous struct
/// literal and the implicitly added identifiers.
pub fn Object(comptime T: type) type {
    return struct {
        const Model = @This();

        /// UUID of the model. Implicitly created for you, with the option to provide your own.
        id: UUID = UUID.init(),

        /// The fields of the model. To access their contents, you will need to iterate
        /// through each field. Type information will always be present.
        fields: []Field = T,

        /// Removes all memory space within the UUID.
        pub fn deinit(self: Model) void {
            self.* = undefined;
        }

        /// Gets data on a field from the object.
        pub fn get(self: *Model, field_name: []const u8) ?Field {
            for (self.fields) |field| {
                if (field.name == field_name) return field;
            }
        }
    }{};
}
