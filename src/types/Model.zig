const std = @import("std");
const heap = std.heap;
const builtin = std.builtin;

const Model = @This();

/// Opt-in allocator for handling memory preservation
allocator: ?heap.GeneralPurposeAllocator,

/// The fields of the model. Models will work off of an anonymous struct literal
/// and concatenate two into a final struct state through their respective indices.
fields: []builtin.Type.StructField,

/// Creates a new Model
pub fn init(alloc: bool) Model {
    return Model {
        .allocator = heap.GeneralPurposeAllocator(.{}) if alloc orelse undefined
    };
}

/// Allocs the UUID and sets undefined space to the UUID (removing it)
pub fn deinit(self: *Model) void {
    if(self.allocator.?) try self.allocator.free();
    else self = undefined;
}