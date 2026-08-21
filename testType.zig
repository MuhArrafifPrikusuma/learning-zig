const std = @import("std");

const idk = struct {
    hello: u32,
};
pub fn main() !void {
    std.debug.print("{any}::{any}\n", .{ @TypeOf(std), @TypeOf(idk) });
}
