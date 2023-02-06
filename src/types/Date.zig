const std = @import("std");
const time = std.time;
const fmt = std.fmt;

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
const Error = error {
    /// Part of the date is missing, such as the year, month or day.
    Missing,

    /// This date is out of range because it is out of bounds for POSIX/UNIX validation.
    OutOfRange
};

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
        return switch(@trunc(day_of_week)) {
            0 => Weekday.Sunday,
            1 => Weekday.Monday,
            2 => Weekday.Tuesday,
            3 => Weekday.Wednesday,
            4 => Weekday.Thursday,
            5 => Weekday.Friday,
            6 => Weekday.Saturday,

            // We should never be able to get another value outside of 0-6,
            // so it's "unreachable."
            else => unreachable
        };
    }
};

/// All possible ways to format a date.
const Format = enum {
    @"MM-DD-YYYY",
    @"DD-MM-YYYY",

    /// This is an ISO 8601 representable format.
    @"YYYY-MM-DD"
};

/// The current century, using zero-based centuries precision.
/// Centuries are purely Gregorian based and are not algorithmically produced from a Julian
/// calendar.
century: ?u8 = undefined,

/// The current year. A year constant should presumably be within 0000.
///
/// Years before 1969 or after 2038 will immediately invalidate expression returns within
/// methods requiring POSIX/UNIX validation from their Epoch.
year: ?i64 = undefined,

/// The current month.
month: ?u8 = undefined,

/// The current week. A week constant may be provided, however, automatic generation of this
/// identifier will result in accuracy loss upon rounding away from zero.
week: ?u8 = undefined,

/// The current day.
///
/// Any 30 or 31 day variation between months will be accounted for.
day: ?u8 = undefined,

/// Creates a new date.
///
/// When creating a date, you are only expected to pass the year, month and day.
/// Other identifiers of a date, such as the century and week are automatically
/// generated for you as floored constants dependent on the arguments inputted.
pub fn init(
    /// The year of the date.
    year: i64,
    /// The month of the date.
    month: u8,
    /// The day of the date.
    day: u8
) Date {
    return Date {
        .century = @floor(year / 100) + 1,
        .year = year,
        .month = month,
        .week = @floor(day / 7),
        .day = day
    };
}

/// Validates and handles potential errors for a date or comparison of dates.
fn validate(
    self: *Date,
    /// The date to validate against.
    date: ?Date
) !bool {
    // A date can still be created by struct alone - we have to run some checks.
    if (self.year == undefined or date.year.? == undefined) return Error.Missing;
    if (self.month == undefined or date.month.? == undefined) return Error.Missing;
    if (self.day == undefined or date.day.? == undefined) return Error.Missing;

    // A year value can be out of bounds.
    if (self.year < 1969 or date.year.? < 1969 and date.year != undefined)
        return Error.OutOfRange;
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

    const ms_per_month: u8 = 30 * time.ms_per_day;
    const ms_per_year: i64 = 12 * ms_per_month;

    return Date.new(
        current_time / ms_per_year,
        current_time / ms_per_month,
        current_time / time.ms_per_day
    );
}

/// Returns a date based off of the current stored date and one supplied.
///
/// If both dates are found to have the same year, month and day; and contain the
/// same values, a `null` value will be returned instead.
///
/// A `Missing` or `OutOfRange` error may be returned in the event that part of the date
/// is either found to be missing, or the years specified are out of bounds. (before 1969 or
/// after 2038)
pub fn from(self: *Date, date: ?Date) !?Date {
    // We're checking to see if both dates are the same.
    // This is necessary and cannot be simplified through checking their bare values,
    // as we use undefined to temporarily store a value to the struct identifiers.
    //
    // We want to let developers create a date either through the struct entry, or through
    // a method.
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

    try self.validate();

    var current_year = self.year;
    var current_month = self.month;

    // Unlike in `Date.init()`, we're using a zero-based century as
    // described in Zeller's congruence.
    const current_century = @floor(current_year / 100);

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
    const day_of_week = (
        (26 * current_month - 2) / 10 + (
            (self.day + current_year) +
            (current_year / 4) +
            (current_century / 4) +
            (5 * current_century)
        ) % 7
    );

    // Truncating it closer to zero and moving it from a *potential* float (even though it
    // shouldn't be!) to an integer. Then we take it, and from our indices of an enum literal,
    // we give it an enumerable return.
    return Weekday.from(day_of_week);
}

// Returns a binary state whether the current date is on a leap year or not.
//
// A `Missing` error may be returned in the event that the year is missing from the date.
pub fn isLeapYear(self: *Date) !bool {
    if (self.year == undefined) return Error.Missing;
    else return (
        self.year % 4 == 0 and (
            year % 100 != 0
            or year % 400 == 0
        )
    );
}

// pub fn toString(
//     self: *Date,
//     format: Format
// ) ![]const u8 {
//     // TODO: go through hell with std.fmt fuckery! :')
// }