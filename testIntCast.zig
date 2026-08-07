const std = @import("std");

pub fn main() !void {
    // this will not work with @as since it only has comptime check therefore
    // a var would fail since the compiler couldn't make sure whether this will acutally works
    // or no
    // therefore we use @intCast to get runtime check and be able check and crash at runtime
    // instead
    var x: u64 = 200;
    const y: u8 = @intCast(x);
    x += 0;
    std.debug.print("{d}\n", .{y});
}
