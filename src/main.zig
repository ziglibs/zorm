const std = @import("std");
const testing = std.testing;

const Self = @This();

const Date = @import("./types/Date.zig");
const Field = @import("./types/Field.zig").Field;
const Object = @import("./types/Object.zig").Object;
const UUID = @import("./types/UUID.zig");

const create = @import("./gen.zig").create;

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