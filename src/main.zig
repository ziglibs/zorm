const std = @import("std");

const Date = @import("./types/Date.zig");
const Field = @import("./types/Field.zig");
const Object = @import("./types/Object.zig");
const UUID = @import("./types/UUID.zig");

pub fn main() void {
    std.debug.print("{s}", .{"Hello, world!"});
}