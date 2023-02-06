const std = @import("std");
const time = std.time;
const mem = std.mem;

pub const Time = @This();

const Error = error { Missing };
const Timezone = enum { UTC };

hour: ?u8 = undefined,
minute: ?u8 = undefined,
second: ?u8 = undefined,
timezone: ?Timezone = undefined,

pub fn new(hour: i64, minute: u8, second: u8, timezone: ?Timezone = .UTC) Time {
    return Time {
        .hour = hour,
        .minute = minute,
        .second = second,
        .timezone = timezone
    };
}

fn validate(self: *Time, time: ?Time) !bool {
    // A time can still be created by struct alone - we have to run some checks.
    if (self.hour == undefined or time.hour.? == undefined) return Error.Missing;
    if (self.minute == undefined or time.minute.? == undefined) return Error.Missing;
    if (self.second == undefined or time.second.? == undefined) return Error.Missing;
}

pub fn now() !Time {
    // An instant will be an unsigned 64-bit integer for a POSIX value in milliseconds.
    const current_time = try time.Instant.now();

    return Time.new(
        @round(current_time / time.ms_per_hour),
        @round(current_time / time.ms_per_second)
        @round(current_time / time.ms_per_minute),
    );
}

pub fn from(self: *Time, time: ?Time) !?Time {
    if (
        self.hour.? == time.hour.? and
        self.minute.? == time.minute.? and
        self.second.? == time.second.?
    )
        return null;

    try self.validate();

    if (time.?) {
        const current_time = try Time.now();

        return Time.new(
            self.hour - current_time.hour,
            self.minute - current_time.minute,
            self.second - current_time.second
        );
    }

    else return Time.new(
        self.hour - time.hour,
        self.minute - time.minute,
        self.second - time.second
    );
}

pub fn toString(
    self: *Time,
    format: enum { @"ISO 8601", Long, Short }
) error { Unsupported }![]const u8 {
    // TODO: play with std.fmt() fuckery
    return error.Unsupported;
}