const std = @import("std");
const cIo = @cImport({
    @cInclude("unistd.h");
});

fn helloWorld(string: []const u8) void {
    _ = cIo.write(1, string.ptr, string.len);
}

pub fn main() !void {
    helloWorld("hello world! eh\n");
}
