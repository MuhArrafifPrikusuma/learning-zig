const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, {s}!\n", .{"world"});
    assign();
    array();
}

test "this is test" {
    try std.testing.expect(true);
}

// assignments
pub fn assign() void {
    const constant: i32 = 5;
    var variable: u32 = 320;
    variable += 300;

    // @as perform type coersion, it will only works if it's possible to convert without losing data
    const inferred_constant = @as(i64, constant);
    var inferred_variable = @as(u64, variable);
    inferred_variable -= 100;

    std.debug.print("Constant: {d}\nVariable: {d}\n", .{ inferred_constant, inferred_variable });
}

// array in zig has predefined lenght and not null terminated except if specifically called
pub fn array() void {
    const a = [5]u8{ 't', 't', 'i', 'd', 'k' };
    const len_a = a.len;
    std.debug.print("length of a is {d}\n", .{len_a});
    // [_] automatically detect the size of the array
    const b = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g' };
    const len_b = b.len;
    std.debug.print("length of b is {d}\n", .{len_b});
}

test "if statements" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }

    try std.testing.expect(x == 1);
}

test "while without continue expression" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    try std.testing.expect(i == 128);
}

test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }
    try std.testing.expect(sum == 55);
}

test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2)
            continue;
        sum += i;
    }
    try std.testing.expect(sum == 4);
}

test "while with break" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        if (i == 5) break;
        sum += i;
    }
    try std.testing.expect(sum == 10);
}

test "for loops" {
    const string = [_]u8{ 'h', 'e', 'l', 'l', 'o' };

    for (string, 0..) |character, index| {
        std.debug.print("character: {c} at index: {d}\n", .{ character, index });
    }
    for (string) |character| {
        _ = character;
    }

    // we don't take character here we only take the index
    for (string, 0..) |_, index| {
        std.debug.print("index: {d}\n", .{index});
    }
}

test "test fibonacci functions" {
    const val = fibonacci(10);
    try std.testing.expect(@TypeOf(val) == u32);
    try std.testing.expect(val == 55);
}
test "faster fibonacci" {
    const val = fasterfib(10);
    try std.testing.expect(val == 55);
}

test "defer" {
    var x: i16 = 5;
    // arbitrary block scoping to shrink scope inside function
    // oh and also defer here is block scoped unlike go function scope
    {
        defer x += 2;
        std.debug.print("x: {d}\n", .{x});
        try std.testing.expect(x == 5);
    }
    std.debug.print("x: {d}\n", .{x});
    try std.testing.expect(x == 7);
}

// this will execute the defer on reverse order just like in go
test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2; // <- then this
        defer x /= 2; // <- this first
    }
    try std.testing.expect(x == 4.5);
}

// functions
// recursion might cause stack overflow
fn fibonacci(n: u32) u32 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

fn fasterfib(n: u32) u32 {
    var sum: u32 = 0;
    var i: u32 = 1;
    while (i <= n) : (i += 1) {
        sum += i;
    }
    return sum;
}
