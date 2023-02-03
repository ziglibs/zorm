const std = @import("std");
const time = std.time;

/// A date structure based off of a proleptic Gregorian calendar.
///
/// There are three valid ways to represent a date:
///
/// - Absolute: denotes the year, month and day.
/// - Relative: based off of another date, with a difference between the current system date
///             and the one given.
/// - Span: the difference between two given dates, whether absolute or relative.
///
/// The objectivity of this structure is to allow all three ways to be valid use cases.
/// Dates will always require a year, month and day for a relative/span representation.
/// Failing to do so will result in an improper date.
pub const Date = @This();

// Possible errors for a Date
const Error = error {
    MissingYear,
    MissingMonth,
    MissingDay,
    InvalidSpan
};

/// The year of the date.
year: i64,

/// The month of the date.
month: u8,

/// The day of the date.
day: u8,

/// Creates a new Date.
pub fn init(year: i64, month: u8, day: u8) Date {
    return Date {
        .year = year,
        .month = month,
        .day = day
    };
}

/// Retrieves the current system date.
pub fn today() !Date {
    const ts = try time.Instant.now();

    // TODO: process the Instant timestamp data and place it into a Date structure.
    return Date { .year = undefined, .month = undefined, .day = undefined };
}