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

const FileOpenError = error{ AccessDenied, OutOfMemory, FileNotFound };
const AllocationError = error{OutOfMemory};
test "Errors" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try std.testing.expect(err == FileOpenError.OutOfMemory);
}
test "error unions" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch noreturn;

    try std.testing.expect(@TypeOf(no_error) == u16);
    try std.testing.expect(no_error == 10);
}
// function error payload capturing
fn failingFunction() error{Oops}!void {
    return error.Oops;
}
test "catch error payload" {
    failingFunction() catch |err| {
        std.debug.print("catches the error\n", .{});
        try std.testing.expect(err == error.Oops);
        return;
    };
}
// try catch
fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try catch" {
    const v = failFn() catch |err| {
        std.debug.print("this we catch it here and expect true if not true then we continue\n", .{});
        try std.testing.expect(err == error.Oops);
        return;
    };
    try std.testing.expect(v == 12);
}
// errdefer
var problems: u32 = 90;
fn failFnCounter() error{Oops}!void {
    errdefer problems += 1; // <- like defer but only works when function is error
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try std.testing.expect(err == error.Oops);
        try std.testing.expect(problems == 91); // <- true since errdefer problems += 1 will execute since ffailingFunction() it's error
        return;
    };
}
// implicit error unions
fn createFile() !void {
    return error.AccessDenied;
}

test "implicit error union" {
    // also catch the error
    const x: error{AccessDenied}!void = createFile();
    _ = x catch {};
    std.debug.print("{any}\n", .{createFile()});
}

// merging error sets

const A = error{ NotDir, PathNotFound };
const B = error{ RunTimePanic, OutOfBounds };
const C = A || B; // <- now you can use C to use both errors from a and b

fn errorAExample() !void {
    return B.RunTimePanic;
}
fn errorBExample() !void {
    return A.PathNotFound;
}

// both comes from different error expression but they can both implement C since C implement both a and b
test "merged error sets" {
    errorAExample() catch |err| {
        try std.testing.expect(err == C.RunTimePanic);
        return;
    };
    errorBExample() catch |err| {
        try std.testing.expect(err == C.PathNotFound);
        return;
    };
}

// functions
// recursion might cause stack overflow
fn fibonacci(comptime n: u32) u32 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

fn fasterfib(comptime n: u32) u32 {
    var sum: u32 = 0;
    var i: u32 = 1;
    while (i <= n) : (i += 1) {
        sum += i;
    }
    return sum;
}

// switch statements
// switch can be used as both statements and expression in zig

// NOTE: cases doesn't fall through and doesn't require breaks; like in C
test "switch test" {
    var x: i8 = -1;
    switch (x) {
        // this one will run if it's either -1 to 1
        -1...1 => {
            std.debug.print("{d}\n", .{x});
            x = -x;
            try std.testing.expect(x == 1);
        },
        // this one will run if it's either 10 to 100
        10...100 => {
            std.debug.print("{d}\n", .{x});
            x = @divExact(x, 10); // <- this gurantee that division will never be zero
            try std.testing.expect(x == 1);
        },
        // else is like default:
        else => {},
    }
}

test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        // this is a way to do multiline code inside inside a switch expression
        -1...1 => min1_to1: {
            const val = @as(i8, -x);
            try std.testing.expect(x == 1);
            break :min1_to1 val;
        },
        10...100 => @divExact(x, 10),
        else => x,
    };
    try std.testing.expect(x == x or x == 1);
}

// Runtime safety
test "out of bounds array" {
    // disable for current block only
    // which mean this bullshit will somehow pass
    @setRuntimeSafety(false);
    const arrays = [_]u8{ 1, 2, 3 };
    var index: u8 = 5; // <- we need to use var here since if it's index the compiler will read it at comptime and throw compiler error
    const what_val = arrays[index];

    index = index;
    std.debug.print("{d}\n", .{what_val});
}

test "unreachable" {
    const foo: i8 = 2;
    // when it checks it at runtime and fail it will reach the unreachable code which will trigger runtime panic
    const bar: i8 = if (foo == 2) 5 else unreachable;

    try std.testing.expect(bar == 5);
}

// example of use

fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "ascii to upper test" {
    try std.testing.expect(asciiToUpper('c') == 'C');
}

// pointers

fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);
    try std.testing.expect(x == 2);
}

test "naughty pointer" {
    var x: u16 = 5;
    x -= 3; // <- change this to 5 and x will have and cannot be casted to y
    var y: *u8 = @ptrFromInt(x);
    y = y;
}

test "const pointers" {
    // pointer from this is read only
    const x: u8 = 1;
    const y = &x;

    try std.testing.expect(y.* == 1);
}

test "usize" {
    // usize and isize is like size_t and ssize_t in C
    // therefore it has 8 bytes in it just like pointers
    try std.testing.expect(@sizeOf(usize) == @sizeOf(*u8));
    try std.testing.expect(@sizeOf(isize) == @sizeOf(*u8));
}

// multi item pointer
fn doubleAllManyPointer(buffer: [*]u8, byte_count: usize) void {
    var i: usize = 0;
    while (i < byte_count) : (i += 1) buffer[i] *= 2;
}

test "multi-items pointers" {
    // ** is array repetition operator used to copy this array 100 times
    var buffer: [100]u8 = [_]u8{1} ** 100;
    const buffer_ptr: *[100]u8 = &buffer;

    // this buffer_many_ptr behave like C arrays which points to the very first elements in that address
    // which mean this is unsafe and can overlow
    const buffer_many_ptr: [*]u8 = buffer_ptr;
    doubleAllManyPointer(buffer_many_ptr, buffer.len);
    for (buffer) |byte| {
        std.debug.print("{d}\n", .{byte});
        try std.testing.expect(byte == 2);
    }

    // same address
    const first_element_ptr: *u8 = &buffer_many_ptr[0];
    // this also target the first element since it's converted to *u8 type
    const first_element_ptr_2: *u8 = @ptrCast(buffer_many_ptr);

    try std.testing.expect(first_element_ptr == first_element_ptr_2);
}

// slices here is like slices in go

fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| {
        sum += v;
        std.debug.print("items: {d}\n", .{v});
    }
    return sum;
}

test "test slices" {
    const arrays = [_]u8{ 2, 2, 3, 4, 5, 6, 7, 8 };
    const slice = arrays[0..3];
    try std.testing.expect(total(slice) == 7);
}

// when start and end value of a slice is known at compile time it will produce a pointer to that an array of that slice

test "comptime slice optimization" {
    const arrays = [_]u8{
        5,
        3,
        1,
        3,
        54,
        3,
        2,
    };
    const comptimeSlice = arrays[1..4];
    for (comptimeSlice) |v| std.debug.print("val: {d}\n", .{v});

    try std.testing.expect(@TypeOf(comptimeSlice) == *const [3]u8);
}

test "just like go slice" {
    const arrays = [_]u8{ 1, 2, 3, 4, 5 };
    const slices = arrays[0..]; // <- slice to the end
    try std.testing.expect(slices.len == 5);
}
// enums

// enum can have specified integer to not waste spaces
const Value = enum(u2) { zero, one, two };
const Value1 = enum { nzero, none, ntwo };

test "test enums" {
    try std.testing.expect(@intFromEnum(Value.zero) == 0);
    try std.testing.expect(@intFromEnum(Value.one) == 1);
    try std.testing.expect(@intFromEnum(Value.two) == 2);
}

// value can be overridden ofcourse

// next will add value of 1 to the very last enum before it
const OverValue = enum(u16) { ten = 10, hundred = 100, thousand = 1000, next };

test "set enum ordinal value" {
    try std.testing.expect(@intFromEnum(OverValue.ten) == 10);
    try std.testing.expect(@intFromEnum(OverValue.hundred) == 100);
    try std.testing.expect(@intFromEnum(OverValue.thousand) == 1000);
    try std.testing.expect(@intFromEnum(OverValue.next) == 1001);
}

// methods in enum

const foos = enum {
    fooz,
    bar,
    baz,
    pub fn isFooz(self: foos) bool {
        return self == foos.bar;
    }
};

test "enum method" {
    try std.testing.expect(foos.baz.isFooz() == foos.isFooz(.baz));
}

// declaration in enum

const Mode = enum(u1) {
    // this value is unrelated to the enum and will act like a global namespace
    var count: u32 = 0;
    on,
    off,
};

test "test mode" {
    Mode.count += 99999;
    try std.testing.expect(Mode.count == 99999);
    try std.testing.expect(@intFromEnum(Mode.on) == 0);
    try std.testing.expect(@intFromEnum(Mode.off) == 1);
}
