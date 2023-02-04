const std = @import("std");
const time = std.time;
const mem = std.mem;

pub const Date = @This();

const Error = error { Missing };

year: ?i64 = undefined,
month: ?u8 = undefined,
week: ?u8 = undefined,
day: ?u8 = undefined,

pub fn new(year: i64, month: u8, day: u8) Date {
    return Date {
        .year = year,
        .month = month,
        .week = day % 7,
        .day = day
    };
}

fn validate(self: *Date, date: ?Date) !bool {
    // A date can still be created by struct alone - we have to run some checks.
    if (self.year == undefined or date.year.? == undefined) return Error.Missing;
    if (self.month == undefined or date.month.? == undefined) return Error.Missing;
    if (self.day == undefined or date.day.? == undefined) return Error.Missing;
}

pub fn now() !Date {
    // An instant will be an unsigned 64-bit integer for a POSIX value in milliseconds.
    const current_time = try time.Instant.now();

    const ms_per_month: u8 = 30 * time.ms_per_day;
    const ms_per_year: i64 = 12 * ms_per_month;

    return Date.new(
        current_time / ms_per_year,
        current_time / ms_per_month,
        current_time / time.ms_per_day
    );
}

pub fn from(self: *Date, date: ?Date) !?Date {
    if (
        self.year.? == date.year.? and
        self.month.? == date.month.? and
        self.day.? == date.day.?
    )
        return null;

    try self.validate();

    if (date.?) {
        const current_date = try Date.now();

        return Date.new(
            self.year - current_date.year,
            self.month - current_date.month,
            self.day - current_date.day
        );
    }

    else return Date.new(
        self.year - date.year,
        self.month - date.month,
        self.day - date.day
    );
}

pub fn toString(
    self: *Date,
    format: enum { @"ISO 8601", @"MM-DD-YYYY" }
) error { Unsupported }![]const u8 {
    // TODO: play with std.fmt() fuckery
    return error.Unsupported;
}