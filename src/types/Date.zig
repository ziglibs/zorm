const std = @import("std");
const time = std.time;
const fmt = std.fmt;
const heap = std.heap;
const mem = std.mem;
const testing = std.testing;
const log = std.log.scoped(.date);

/// A date based off of the Proleptic Gregorian calendar.
///
/// Dates have three valid ways of being represented:
///
/// - Absolute: A date with a year, month and day. The century, week and other information will
///             be automatically generated for you.
/// - Relative: The current date, compared to another date. You can use the `Date.now()` method
///             to return you a date where the fields represent the difference between both.
/// - Duration: A span of dates in-between two given ones, useful for representing ranges.
pub const Date = @This();

// All possible errors for a date.
const Error = error{Missing};

/// All possible days of a week, used with `Date.weekday()`.
///
/// Weekdays are linearly assigned an enum literal value, from 0 to 6 representing
/// all 7 possible days of a week on a Gregorian calendar.
const Weekday = union(enum) {
    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,

    /// Returns a weekday based off of an integer between 0 and 6.
    pub fn from(v: u8) Weekday {
        return switch (v) {
            0 => Weekday.Sunday,
            1 => Weekday.Monday,
            2 => Weekday.Tuesday,
            3 => Weekday.Wednesday,
            4 => Weekday.Thursday,
            5 => Weekday.Friday,
            6 => Weekday.Saturday,

            // We should never be able to get another value outside of 0-6,
            // so it's "unreachable."
            else => unreachable,
        };
    }
};

/// All possible ways to format a date.
pub const Format = enum {
    @"MM-DD-YYYY",
    @"DD-MM-YYYY",

    /// This is an ISO 8601 representable format.
    @"YYYY-MM-DD",
};

/// The current century, using zero-based centuries precision.
/// Centuries are purely Gregorian based and are not algorithmically produced from a Julian
/// calendar.
century: ?u64 = undefined,

/// The current year. A year constant should presumably be within 0000.
///
/// Years before 1969 or after 2038 will immediately invalidate expression returns within
/// methods requiring POSIX/UNIX validation from their Epoch.
year: ?u64 = undefined,

/// The current month.
month: ?u64 = undefined,

/// The current week. A week constant may be provided, however, automatic generation of this
/// identifier will result in accuracy loss upon rounding away from zero.
week: ?u64 = undefined,

/// The current day.
///
/// Any 30 or 31 day variation between months will be accounted for.
day: ?u64 = undefined,

/// Creates a new date.
///
/// When creating a date, you are only expected to pass the year, month and day.
/// Other identifiers of a date, such as the century and week are automatically
/// generated for you as floored constants dependent on the arguments inputted.
pub fn init(year: u64, month: u64, day: u64) Date {
    return Date{ .century = (year / 100) + 1, .year = year, .month = month, .week = day / 7, .day = day };
}

/// Validates and handles potential errors for a date or comparison of dates.
fn validate(
    self: *Date,
    /// The date to validate against.
    date: ?Date,
) Error!bool {
    // A date can still be created by struct alone - we have to run some checks.
    if (self.year == undefined or date.?.year == undefined) return Error.Missing;
    if (self.month == undefined or date.?.month == undefined) return Error.Missing;
    if (self.day == undefined or date.?.day == undefined) return Error.Missing;
    return true;
}

/// Creates a new date based off of the current system time.
///
/// Returns a date based off of `std.time.Instant`, with millisecond deviation
/// and truncated accuracy loss on the year, month and day.
///
/// An `Unsupported` error may be returned in the event that the system clock cannot
/// be accessed.
pub fn now() !Date {
    // An instant will be an unsigned 64-bit integer for a POSIX value in milliseconds.
    const current_time = try time.Instant.now();

    const ms_per_month: u64 = 30 * time.ms_per_day;
    const ms_per_year: u64 = 12 * ms_per_month;

    return Date.init(current_time.timestamp / ms_per_year, current_time.timestamp / ms_per_month, current_time.timestamp / time.ms_per_day);
}

/// Returns a date based off of the current stored date and one supplied.
///
/// If both dates are found to have the same year, month and day; and contain the
/// same values, a `null` value will be returned instead.
///
/// A `Missing` error may be returned in the event that part of the date is either found to
/// be missing, or the years specified are out of bounds. (before 1969 or after 2038)
pub fn from(self: *Date, date: ?Date) !?Date {
    // We're checking to see if both dates are the same.
    // This is necessary and cannot be simplified through checking their bare values,
    // as we use undefined to temporarily store a value to the struct identifiers.
    //
    // We want to let developers create a date either through the struct entry, or through
    // a method.
    if (self.year.? == date.?.year and
        self.month.? == date.?.month and
        self.day.? == date.?.day)
        return null;

    _ = try self.validate(self.*);

    if (@TypeOf(date.?) == Date) {
        const current_date = try Date.now();

        return Date.init(self.year.? - current_date.year.?, self.month.? - current_date.month.?, self.day.? - current_date.day.?);
    } else return Date.init(self.year.? - date.year.?, self.month.? - date.month.?, self.day.? - date.day.?);
}

/// Returns the weekday of the date.
///
/// A `Missing` error may be returned in the event that part of a date is found to be
/// missing.
pub fn weekday(self: *Date) !Weekday {
    // This implementation is based off of RFC 3339, Appendix B.
    // https://www.rfc-editor.org/rfc/rfc3339#appendix-B
    //
    // Further information about this implementation can be found by reading through
    // the Gregorian formulaic equation for Zeller's congruence.
    // https://en.wikipedia.org/wiki/Zeller%27s_congruence#Formula

    _ = try self.validate(self.*);

    var current_year: i64 = self.year.?;
    var current_month = self.month.?;

    // Unlike in `Date.init()`, we're using a zero-based century as
    // described in Zeller's congruence.
    const current_century = @divFloor(current_year, 100);

    // We're doing month shifting. Why? Because we're trying to factor in for February.
    // February is the oddball as it can be affected by the current year and if it's a leap year.
    //
    // We have to also shift the month because we're determining the week cycle.
    // This is done by also setting it up in advance to handle getting the specific day of the
    // week based off of a potential leap year and the century it coincides with.

    current_month -= 2;
    if (current_month < 1) {
        current_month += 12;
        --current_year;
    }
    current_year %= 100;

    // This is stupid and complicated. We're loosely following the above formula, with some
    // differences:
    //
    // - We multiply our month by 26, subtract by 2 to re-align the month from earlier, and
    //   because we want to go through half the year.
    // - We're dividing that by 10 because we want a base 10 notation to make accuracy easier.
    // - We're adding the current day and year together because they're closely dependent.
    // - We're dividing the current year by 4 to account for a leap year.
    // - We're dividing the current century by 4 to account for each quarter of one.
    // - We multiply the current century by 5 because we realign the week margins.
    // - We finally modulo by 7 for all possible days in a week.
    //
    // If you didn't understand any of that, then that's fine. I didn't either when I was reading
    // up on this. It just works. Please don't ask why.
    const day_of_week = ((26 * current_month - 2) / 10 + ((self.day + current_year) +
        (current_year / 4) +
        (current_century / 4) +
        (5 * current_century)) % 7);

    // Truncating it closer to zero and moving it from a *potential* float (even though it
    // shouldn't be!) to an integer. Then we take it, and from our indices of an enum literal,
    // we give it an enumerable return.
    return Weekday.from(@trunc(day_of_week));
}

// Returns a binary state whether the current date is on a leap year or not.
//
// A `Missing` error may be returned in the event that the year is missing from the date.
pub fn isLeapYear(self: *Date) !bool {
    if (self.year.? == undefined) return Error.Missing;

    return (self.year.? % 4 == 0 and (self.year.? % 100 != 0 or self.year.? % 400 == 0));
}

/// Returns a string representation of the date.
///
/// A formatter error of any kind may be produced if the date itself has been improperly passed.
pub fn toString(self: *Date, format: Format) ![]const u8 {
    const fmt_style = switch (format) {
        .@"MM-DD-YYYY" => .{ self.month.?, self.day.?, self.year.? },
        .@"DD-MM-YYYY" => .{ self.day.?, self.month.?, self.year.? },
        .@"YYYY-MM-DD" => .{ self.year.?, self.month.?, self.day.? },
    };

    var fmt_string: []u8 = undefined;
    fmt_string = try fmt.bufPrint(fmt_string, "{?}-{?}-{?}", fmt_style);

    return @as([]const u8, fmt_string);
}

/// Returns a date from a string.
pub fn fromString(date: []const u8, format: Format) !Date {
    var values = mem.split(u8, date, "-");
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    var num_array = std.ArrayList([]const u8).init(gpa.allocator());

    defer {
        num_array.deinit();
        const leak = gpa.deinit();

        if (leak) @panic("Allocator exhausted memory buffer!");
    }

    while (values.next()) |value| {
        try num_array.append(value);
    }

    return switch (format) {
        .@"MM-DD-YYYY" => Date.init(try fmt.parseInt(u64, num_array.items[2], 0), try fmt.parseInt(u8, num_array.items[1], 0), try fmt.parseInt(u8, num_array.items[0], 0)),
        .@"DD-MM-YYYY" => Date.init(try fmt.parseInt(u64, num_array.items[1], 0), try fmt.parseInt(u8, num_array.items[2], 0), try fmt.parseInt(u8, num_array.items[0], 0)),
        .@"YYYY-MM-DD" => Date.init(try fmt.parseInt(u64, num_array.items[0], 0), try fmt.parseInt(u8, num_array.items[2], 0), try fmt.parseInt(u8, num_array.items[1], 0)),
    };
}

// This is a pretty redundant test, but it's just to make sure undefined
// values are being properly handled and checked.
test "Create date" {
    const date = Date.init(2002, 7, 23);

    try testing.expect(date.year.? == 2002);
    try testing.expect(date.month.? == 7);
    try testing.expect(date.day.? == 23);

    log.debug("Y {?} M {?} D {?}\n", .{ date.year, date.month, date.day });
}

test "Create current date" {
    const date = try Date.now();

    try testing.expect(date.year != undefined);
    try testing.expect(date.month != undefined);
    try testing.expect(date.day != undefined);

    log.debug("Current Y {?} M {?} D {?}\n", .{ date.year, date.month, date.day });
}

// FIXME: This panics into an integer overflow. Not good! Isolate and do verbose debug check.
test "Compare dates" {
    var date = Date.init(2002, 7, 23);
    var date_now = try Date.now();
    var relative_date = try date.from(date_now);

    try testing.expect(date_now.year != relative_date.?.year);
    try testing.expect(date_now.month != relative_date.?.month);
    try testing.expect(date_now.day != relative_date.?.day);

    log.debug("\nOrigin Y {?} M {?} D {?}\nNow Y {?} M {?} D {?}\nDifference Y {?} M {?} D {?}\n", .{ date.year, date.month, date.day, date_now.year, date_now.month, date_now.day, relative_date.?.year, relative_date.?.month, relative_date.?.day });
}

// TODO: fix an annoying u64 -> i64 bug for current_month
test "Get weekday" {
    var date = Date.init(2002, 7, 23);
    var date_weekday = try date.weekday();

    try testing.expect(date_weekday == Weekday.Tuesday);

    log.debug("Weekday is {?}\n", .{date_weekday});
}

test "Check leap year" {
    var date = Date.init(2024, 1, 1);
    var leap_year = try date.isLeapYear();

    try testing.expect(leap_year);

    log.debug("Leap year - {?}\n", .{leap_year});
}

// FIXME: I'm segfaulting because std.fmt is broken. Fix when stdlib is corrected!
test "Date to string" {
    var date = Date.init(2002, 7, 23);
    var date_as_string = try date.toString(.@"YYYY-MM-DD");

    try testing.expect(mem.eql(u8, date_as_string, "2002-07-23"));

    log.debug("{any}?\n", .{date_as_string});
}

test "String to date" {
    const string_as_date = try Date.fromString("2002-07-23", .@"YYYY-MM-DD");
    const pseudo_date = Date.init(2002, 7, 23);

    try testing.expect(string_as_date.year == pseudo_date.year);
    try testing.expect(string_as_date.month == pseudo_date.month);
    try testing.expect(string_as_date.day == pseudo_date.day);

    log.debug("{?} -> Y {?} M {?} D {?}\n", .{ string_as_date, string_as_date.year, string_as_date.month, string_as_date.day });
}
