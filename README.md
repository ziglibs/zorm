<center>
    <img src="https://user-images.githubusercontent.com/41456914/217338569-05b2fa34-e40e-434b-8f2f-41bf12502277.png" />
</center>

## Abstract

Warning
|-
This library is still in development. Please use at your own expense.

zorm is not your traditional ORM tool. Unlike other ORMs, zorm is designed to provide types for
making object-relational mapping within your scripts simple and not reliant on database table
paradigms.

In zorm, objects are cast on manually defined fields that can be compared:

### Object mapping

```zig
const std = @import("std");

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
    const myFoo: zorm.Object = try zorm.create(Foo, .{ .JsonString = dumb_payload });

    // Accessing data is now done through the newly created object.
    std.debug.print("{any}\n", .{myFoo.get("foo")});
}
```

### Using datatypes

zorm provides you a set of datatypes. An example of a datatype is `Date`:

```zig
pub fn main() !void {
    // We can build a date from a string, useful for defaults.
    const date = try zorm.Date.fromString("2002-07-23", .@"YYYY-MM-DD");

    // This is an ISO 8601 format, which zorm will intelligently determine
    const payload =
        \\{
        \\    "date": "1999-12-31"
        \\}
    ;
    const NewTable = try zorm.create(
        zorm.Object(.{
            // Default values must either be undefined or part of the type specified in the field,
            // as expected when working with structs.
            zorm.Field(?zorm.Date, .{ .name = "date", .default = date })
        }),
        .{ .JsonString = payload }
    );

    // 1999 will be returned instead of 2002.
    std.debug.print("{?}\n", .{NewTable.get("date").f_type.year});
}
```

## Building

zorm runs on 0.10.0-dev and higher versions of [Zig](https://ziglang.org).

It is recommended to install and build from source:

```bash
$ git clone --recursive https://github.com/ziglibs/zorm
$ cd ./zorm
$ zig build
```
