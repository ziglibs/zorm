const std = @import("std");
const time = std.time;
const mem = std.mem;

pub const Date = @This();

const Error = error { Missing };
const Weekday = enum {
    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday
};

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

pub fn weekday(self: *Date) !Weekday {
    try self.validate();

    var current_year = self.year;
    var current_month = self.month;
    const current_century = current_year / 100;

    current_month -= 2;
    if (current_month < 1) |month| {
        month += 12;
        --current_year;
    }
    current_year %= 100;

    const day_of_week = (
        (26 * current_month - 2) / 10 + (
            (self.day + current_year) +
            (current_year / 4) +
            (current_century / 4) +
            (5 * current_century)
        ) % 7
    );

    return switch(day_of_week) {
        0 => Weekday.Sunday,
        1 => Weekday.Monday,
        2 => Weekday.Tuesday,
        3 => Weekday.Wednesday,
        4 => Weekday.Thursday,
        5 => Weekday.Friday,
        6 => Weekday.Saturday,
        else => unreachable
    };
}

pub fn isLeapYear(self: *Date) !bool {
    if (self.year == undefined) return Error.Missing;
    else return (
        self.year % 4 == 0 and (
            year % 100 != 0
            or year % 400 == 0
        )
    );
}

pub fn toString(
    self: *Date,
    format: enum { @"ISO 8601", @"MM-DD-YYYY" }
) error { Unsupported }![]const u8 {
    // TODO: play with std.fmt() fuckery
    return error.Unsupported;
}