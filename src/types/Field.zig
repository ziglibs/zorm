const FieldMetadata = struct {
    /// The name of the field.
    name: []const u8,

    /// The description of the field.
    desc: ?[]const u8,

    /// What the potential default value may be.
    default: ?type
};

/// A field to go within an object.
///
/// Anonymous struct literals are concatenated within the object when providing the final Modal
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