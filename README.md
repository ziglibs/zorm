# zorm

A new way to think about ORMs

## Abstract

zorm is not your traditional ORM tool. Unlike other ORMs, zorm is designed to provide types for
making object-relational mapping within your scripts simple and not reliant on database table
paradigms.

In zorm, objects are cast on manually defined fields that can be compared:

```zig
const std = @import("std");
const json = std.json;

// In this example, we'll be mapping our object from JSON.
// For this very specific use case, zorm will handle assuming types to be tight and memory-bound.
const dumb_payload =
    \\{
    \\   "foo": "hello, world",
    \\   "bar": 420
    \\}
;

const zorm = @import("zorm");

// Objects are defined as a sort of "factory method." The inner argument is a comptime-known
// anonymous struct literal containing fields.
const Foo = zorm.Object(.{
    // (comptime T: type, data: ?FieldMetadata)
    // Fields can have a name, description and default value.
    zorm.Field(?[]const u8, .{ .name = "foo", .default = undefined }),
    zorm.Field(usize, .{ .name = "bar" })
});

pub fn main() !void {
    // With an object defined, we can now generate our own from our payload.
    // (comptime T: type, data: anytype)
    const myFoo: zorm.Object = try zorm.create(Foo, dumb_payload);

    // Accessing data is now done through the newly created object.
    std.debug.print("{?}\n", .{myFoo.get("foo")});
}
```

## Building

zorm runs on 0.10.0-dev and higher versions of [Zig](https://ziglang.org).

It is recommended to install and build from source:

```bash
$ git clone --recursive https://github.com/i0bs/zorm
$ cd ./zorm
$ zig build
```