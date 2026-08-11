const std = @import("std");

pub fn main() !void {
    const a: u32 = 200000;
    var b: u128 = 0;
    var i: u32 = a;
    while (i != 0) : (i -= 1) b += a;

    std.debug.print("{d}\n", .{b});
}
