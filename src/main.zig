const std = @import("std");
const testing = std.testing;

pub const Date = @import("types/Date.zig").Date;
pub const Field = @import("types/Field.zig").Field;
pub const Object = @import("types/Object.zig").Object;
pub const UUID = @import("types/UUID.zig").UUID;

pub const create = @import("gen.zig").create;

pub fn main() !void {
    std.debug.print("{s}\n\n", .{"Hello, world!"});
}

test {
    _ = Date;

    // Tests are failing on the Field function and I can't figure out why.
    //     _ = Field;
    _ = Object;
    _ = UUID;
    _ = create;
}
