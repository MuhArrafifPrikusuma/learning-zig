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

// when start and end value of a slice is known at compile time it will produce a pointer to an array of that slice

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

// structs
const Vec = struct { x: f32, y: f32, z: f32 };

test "test struct" {
    const my_vect = Vec{
        .x = 0,
        .y = 100,
        .z = 50,
    };

    try std.testing.expect(my_vect.x == 0);
    try std.testing.expect(my_vect.y == 100);
    try std.testing.expect(my_vect.z == 50);
}

test "missing struct fields" {
    // struct fields cannot but implicitly uninitialized
    const my_vect = Vec{
        .x = 100,
        .z = 20,
        .y = undefined, // <- if you delete this it will throw an error
    };

    try std.testing.expect(my_vect.x == 100);
    try std.testing.expect(my_vect.z == 20);
}

// struct can be given default value
const Another_Vec = struct { x: f32 = 0, y: f32 = 0, z: f32 = 0 };

test "test default struct" {
    const my_vect = Another_Vec{
        .x = 20,
        .z = 100,
    };
    try std.testing.expect(my_vect.x == 20);
    try std.testing.expect(my_vect.y == 0); // <- y is zero since well that's the default
    try std.testing.expect(my_vect.z == 100);
}

// function inside struct

const stuff = struct {
    x: i32,
    y: i32,
    // functions inside struct will have 1 level automatic dereference
    fn swap(self: *stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "test fn in struct" {
    var thing = stuff{ .x = 200, .y = 232 };
    thing.swap();

    try std.testing.expect(thing.x == 232);
    try std.testing.expect(thing.y == 200);
}

// unions
// union act as one types that store one value of many possible data types
const Result = union {
    int: i64,
    float: f64,
    bool: bool,
};

// you cannot use 2 data types
test "simple union" {
    const result = Result{ .int = 1234 };
    // uncomment this and it will throw an error
    // result.float = 12.34;
    try std.testing.expect(result.int == 1234);
}

// tagged unions
const Tag = enum { a, b, c };
// now it used the enum as a tag to determine which field is active
const Tagged = union(Tag) { a: u8, b: f32, c: bool };

// you can also do this
// NOTE: enum tagged union cannot be packed
const ExamplTagged = union(enum) { a: u1, b: u8, c: u32 };

test "switch on tagged unions" {
    // this will automatically perform different operation based on which Tag it has
    var value = Tagged{ .a = 1 };
    switch (value) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }

    try std.testing.expect(value.a == 2);
}

// integer rules
// all numeric bases that zig supported
const decimal: i32 = 10;
const hex: u8 = 0x0a;
const another_hex: u8 = 0x0A;
const octal: u16 = 0o012;
const binary: u8 = 0b00001010;

// visual separator with underscores

const decimal_sp: i32 = 1_000_000;
const another_hex_sp: u64 = 0xFF00_02FA_00F1;
const octal_sp: u16 = 0o7_2_3;
const binary_sp: u8 = 0b0000_1010;

// this bullshit is also possible
// can go from 0 to 65535 bits
const stupid_small: u0 = 0; // <- this shit will overflow if more than 0
// this bullshit can store the whole universe in it
const stupid_large: u65535 = 999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999;

test "allowed integers" {
    std.debug.print("a: {d}\n", .{decimal});
    std.debug.print("b: {d}\n", .{hex});
    std.debug.print("c: {d}\n", .{another_hex});
    std.debug.print("d: {d}\n", .{octal});
    std.debug.print("e: {d}\n", .{binary});
    std.debug.print("f: {d}\n", .{decimal_sp});
    std.debug.print("g: {d}\n", .{another_hex_sp});
    std.debug.print("h: {d}\n", .{binary_sp});
    std.debug.print("i: {d}\n", .{stupid_small});
    std.debug.print("j: {d}\n", .{stupid_large});
}

test "@intcast" {
    const x: u64 = 200;
    const y: u8 = @as(u8, x);
    try std.testing.expect(@TypeOf(y) == u8);
}

// packed struct will squish all values that it has at bit level
// which mean this takes exactly 1 bytes instead of 5 bytes
const pstruct = packed struct { a: u1, b: u1, c: u2, d: u2, e: u2 };

test "packed struct" {
    const struct_size = @sizeOf(pstruct);
    std.debug.print("struct size: {d}\n", .{struct_size});
    try std.testing.expect(struct_size == 1);
}
// floats
// like most programming languanges zig floats is IEEE-compliant,
// but you can optimize it and avoid complex IEEE checking by using @setFloatMode(.optimized)
// which basically the equivalent of gcc -ffast-math

test "float widening" {
    const a: f16 = 0;
    const b: f64 = a;
    const c: f128 = b;
    try std.testing.expect(c == @as(f128, a));
}

// all supported literal

const floating_point: f64 = 17.0E+77;
const another_floating_point: f64 = 17.10;
const yet_floating_point: f64 = 17.0e+77;

// p is power in this notation
const hex_float: f64 = 0x0A.70p1;
const another_hex_float: f64 = 0x0A.70;
const yet_another_float: f64 = 0x0A.70P-0;

// underscores is also supported ofcourse
const ud_float: f64 = 213_231_323.000_213;
const ud_float_hex = 0x000A_0020_0123.9ACBp-10;

test "print all above" {
    std.debug.print("{d}\n", .{floating_point});
    std.debug.print("{d}\n", .{another_floating_point});
    std.debug.print("{d}\n", .{yet_floating_point});
    std.debug.print("{d}\n", .{hex_float});
    std.debug.print("{d}\n", .{another_hex_float});
    std.debug.print("{d}\n", .{yet_another_float});
    std.debug.print("{d}\n", .{ud_float});
    std.debug.print("{d}\n", .{ud_float_hex});
}

test "int float conversion" {
    const a: i32 = 0xFF;
    const b: f32 = @floatFromInt(a);
    const c: i32 = @intFromFloat(b);
    try std.testing.expect(@TypeOf(c) == @TypeOf(a));
    try std.testing.expect(@TypeOf(c) != @TypeOf(b));
}

test "labeled blocks" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 1;
        while (i <= 10) : (i += 1) sum += i;
        // break <block-name> <return-variable>
        break :blk sum;
    };
    try std.testing.expect(count == 55);
}

// loop labels
// breaking and continuing outer loops from inner loops is possible here

test "loop blocks label" {
    var count: usize = 0;
    outer: for ([_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 9 }) |_| {
        for ([_]i32{ 1, 2, 3, 4, 5 }) |_| {
            count += 1;
            // it will only reach 9 since inner loop will only run once before forcing outer loop to move
            continue :outer;
        }
    }
    try std.testing.expect(count == 9);
}

// loops as expression

fn hasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number)
            break true;
    } else false;
}

test "loop have return value" {
    const tc = struct {
        begin: usize,
        end: usize,
        number: usize,
        expect: bool,
    };

    const tcs = [_]tc{
        .{ .begin = 0, .end = 10, .number = 3, .expect = true },
        .{ .begin = 4, .end = 2, .number = 3, .expect = false },
        .{ .begin = 5, .end = 10, .number = 8, .expect = true },
        .{ .begin = 3, .end = 100, .number = 11, .expect = true },
        .{ .begin = 4, .end = 8, .number = 5, .expect = true },
    };

    for (tcs) |val| {
        const is_succes = hasNumber(val.begin, val.end, val.number);
        std.debug.print("{}\n", .{is_succes});
        try std.testing.expect(is_succes == val.expect);
    }
}
test "optionals" {
    var found_index: ?usize = null;
    const data = [_]i32{ 1, 2, 3, 4, 5, 7, 8, 12, 22, 24, 48 };
    const data2 = [_]i32{ 1, 2, 3, 4, 5, 7, 8, 12, 22, 24, 48 };
    var pos: u2 = 0;
    found_index = @as(?usize, outer: while (pos < 2) : (pos += 1) {
        for (data, 0..) |value, i| {
            if (value == 10) break :outer i;
        }
        for (data2, 0..) |value, i| {
            if (value == 10) break :outer i;
        }
    } else null);

    try std.testing.expect(found_index == null);
}

// if the optional value contain a value then it will return that value but
// when it contains something like null it will unwraps to the fallback value
test "orelse" {
    const a: ?u8 = null;
    const fallback: u8 = 10;
    const b = a orelse fallback;
    try std.testing.expect(b == 10);
    try std.testing.expect(@TypeOf(b) == u8);
}

// opposite of the one above, now if you know the value can't be null, it will unwraps to null in safe mode
// and will omit the check completely for ReleaseFast or ReleaseSmall
test "orelse unreachable" {
    const a: ?f32 = 2;
    // NOTE: always put compError so that you don't accidentally change the code in the future to allow that unwanted behavior
    comptime {
        if (a == null)
            @compileError("a can't be null");
    }
    const b = a orelse unreachable;
    const c = a.?; // <- this is just another way to write oorelse unreachable
    try std.testing.expect(b == c);
    try std.testing.expect(@TypeOf(c) == f32);
}

test "optional payload capture" {
    var a: ?f32 = 2;
    // if you pass ?T to if it will check whether is null or not and it will be false if null
    if (a) |*value|
        value.* += 1;

    try std.testing.expect(a == 3);
}

var numbers_left: u32 = 4;
fn eventuallyNullSequence() ?u32 {
    if (numbers_left == 0) return null;
    numbers_left -= 1;
    return numbers_left;
}

test "optional while payload capture" {
    var sum: u32 = 0;
    // this will repeat until null
    while (eventuallyNullSequence()) |val|
        sum += val;
    try std.testing.expect(sum == 6);
}

test "comptime" {
    const a: u32 = comptime fasterfib(10);
    const b: u32 = comptime blk: {
        break :blk fasterfib(10);
    };

    try std.testing.expect(a == 55);
    try std.testing.expect(b == a);
}

test "comptime floats" {
    // types in zig is a value of type which mean branching a type is possible
    const a: f32 = 20;
    const b: if (a < 10) f32 else i32 = a; // <- this is comptime contant the type is defined an comptime not runtime it's impossible to define type and runtime and also dangerous why would you turn zig into javascript anyway
    try std.testing.expect(b == 20);
    try std.testing.expect(@TypeOf(b) == i32);
}

// use pascal case for function that returns type, it even has it's own hightlight color on zls therefore making it easier for me
// and yes i mean that, zig function can return a type which can make it like generics, but better at runtime
fn Matrix(comptime T: type, comptime width: comptime_int, comptime heigth: comptime_int) type {
    return [heigth][width]T; // <- in this example it returns 2d arrays with the type of whatever the caller gave
}

test "returning a type" {
    const MyMatrix = Matrix(f32, 5, 5);
    try std.testing.expect(Matrix(f32, 5, 5) == MyMatrix);
}

// @typeInfo

fn addSmallInt(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) {
        .comptime_int => a + b,
        .int => |info| if (info.bits <= 32)
            a + b
        else
            @compileError("integers to larger"),
        else => @compileError("can only accept int type"),
    };
}

test "test typeinfo" {
    const x = addSmallInt(i32, 32, 32);
    try std.testing.expect(@TypeOf(x) == i32);
    try std.testing.expect(x == 64);
}

// @Int

fn DoubleIntSize(comptime T: type) type {
    const info = @typeInfo(T).int;
    return @Int(info.signedness, info.bits * 2);
}

test "@Int" {
    try std.testing.expect(comptime DoubleIntSize(u32) == u64);
    try std.testing.expect(comptime DoubleIntSize(i4) == i8);
}

// @This and generics
pub fn TestCreateVect(comptime count: comptime_int, comptime T: type) type {
    return struct {
        data: [count]T,
        const Self = @This(); // <- returns the struct where it's called
        // this is very usefull for something like this annonymous struct so that it can call itself

        // Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.Self.init(...);
        // yes that's a valid syntax
        fn abs(self: Self) Self {
            var tmp = Self{ .data = undefined };
            for (self.data, 0..) |value, i| {
                tmp.data[i] = if (value < 0)
                    -value
                else
                    value;
            }
            return tmp;
        }

        fn init(data: [count]T) Self {
            return Self{ .data = data };
        }
    };
}

test "generic vector" {
    const x = comptime TestCreateVect(3, i8).init([_]i8{ -10, -10, 5 });
    const y = comptime x.abs();
    // you can chain Self infinitely but why?
    const foo = comptime TestCreateVect(3, i8).Self.Self.Self.Self.init([_]i8{ -1, -3, -4 });
    const bar = comptime foo.abs();

    try std.testing.expect(std.mem.eql(i8, &y.data, &[_]i8{ 10, 10, 5 }));
    try std.testing.expect(std.mem.eql(i8, &bar.data, &[_]i8{ 1, 3, 4 }));
}

// anytype
// line any in go it generate multiple functions based on what type you pass to it
fn plusOne(x: anytype) @TypeOf(x) {
    return x + 1;
}

test "plusOne test" {
    try std.testing.expect(plusOne(@as(u2, 2)) == 3);
}

// comptime also introduce concatenating operator (++) and repeating operator (**)
// that can be used with array and slices

test "++" {
    const foo: [4]u8 = undefined;
    const fooss = foo[0..];
    const bar: [6]u8 = undefined;
    const bars = bar[0..];

    // combine both slices
    const baz = fooss ++ bars;
    try std.testing.expect(baz.len == 10);
}

test "**" {
    const array1 = [_]u8{ 0xCC, 0xAA };
    const cpycpycpy = array1 ** 3; // repeat this array 3 times (is still in continuous block)
    try std.testing.expect(std.mem.eql(u8, &cpycpycpy, &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }));
    try std.testing.expect(cpycpycpy.len == 6);
}

// payload captures

test "optional if" {
    const maybe: ?i32 = 5;
    if (maybe) |val| {
        try std.testing.expect(@TypeOf(val) == i32);
        try std.testing.expect(val == 5);
    } else unreachable;
}

const Unknown = error{unknownEntity};
test "with error unions" {
    const maybeError: Unknown!u32 = Unknown.unknownEntity;
    if (maybeError) |n| {
        try std.testing.expect(@TypeOf(n) == u32);
        try std.testing.expect(n == 10);
    } else |err| {
        _ = err catch {
            std.debug.print("error: {}\n", .{err});
            try std.testing.expect(err == Unknown.unknownEntity);
        };
    }
}

// while loops optionals

test "while optional payload captures" {
    const sequence = [_]?u8{ 0x0A, 0x0B, 0x0C, null };
    var i: usize = 0;
    // it will stop if it's null
    while (sequence[i]) |num| : (i += 1)
        try std.testing.expect(@TypeOf(num) == u8);

    try std.testing.expect(i == 3);
    try std.testing.expect(sequence[i] == null);
}

// while error union capture

var numbers_left2: u32 = undefined;
fn eventuallyErrorSequence() !u32 {
    return if (numbers_left2 == 0) error.ReachedZero else blk: {
        numbers_left2 -= 1;
        break :blk numbers_left2;
    };
}

test "while error union payload capture" {
    var sum: u32 = 0;
    numbers_left2 = 4;
    while (eventuallyErrorSequence()) |value| {
        sum += value;
    } else |err| try std.testing.expect(err == error.ReachedZero);

    try std.testing.expect(sum == 6);
}

// for loops

test "for loops payload captures" {
    const x = [_]i8{ 1, 5, -20, -5 };
    for (x) |value| try std.testing.expect(@TypeOf(value) == i8);
}

// switch cases on tagged unions

const Info = union(enum) {
    a: u32,
    b: f32,
    c,
    d: u32,
};

test "switch capture" {
    const b: Info = .{ .a = 20 };
    const x = switch (b) {
        .a, .d => |num| blk: {
            try std.testing.expect(@TypeOf(num) == u32);
            break :blk num * 2;
        },
        .c => 2,
        .b => |floaters| blk: {
            try std.testing.expect(@TypeOf(floaters) == f32);
            break :blk floaters / 2;
        },
    };

    try std.testing.expect(x == 40);
}

test "captures with pointers to modify it" {
    var data = [_]u8{ 1, 2, 3 };
    // payload capture value is also immutable by default
    for (&data) |*value| value.* += 1;
    try std.testing.expect(std.mem.eql(u8, &data, &[_]u8{ 2, 3, 4 }));
}

// inline loops
// this unroll the loops making it faster but can cause problem and the performance gain is not that much
// and might even slow things down and bloat the binary size therefore test carefully and make sure everything
// work and the loop is actually faster if unrolled

test "inline loops" {
    const types = [_]type{ i32, u32, f16, bool };
    var sum: usize = 0;
    inline for (types) |T| sum += @sizeOf(T);

    try std.testing.expect(sum == 11);
}

// opaque
// this is basically void pointer with type safety, the void* equivalent in zig is anyopaque type

const Window = opaque {};
const Button = opaque {};

// extern fn show_window(*Window) callconv(.c) void;

test "opaque" {
    // this succeded
    // const main_window: *Window = undefined;
    // show_window(main_window);

    // this example will throw an error since this isn't the generic *Window type
    // const this_button: *Button = undefined;
    // show_window(this_button);
}

// opaque can also have declaration inside of it just any other complex types

const Windows = opaque {
    fn addOne(self: *Windows) []const u8 {
        _ = self;
        return "succes";
    }
};

test "opaque with declaration" {
    var new_window: *Windows = undefined;
    const capture_return = new_window.addOne();
    std.debug.print("it return: {s}\n", .{capture_return});
}

// annonymous sturcts

test "annonymous struct literal" {
    const Point = struct { x: i32, y: i32 };

    const pt: Point = .{
        .x = 13,
        .y = 20,
    };

    try std.testing.expect(pt.x == 13 and pt.y == 20);
}

// there are five possible place where comptime can be placed in this block, can you find it?
// <<= start blk =>>
fn dump(args: anytype) !void {
    try std.testing.expect(args.int == 1234);
    try std.testing.expect(args.float == 5.5);
    try std.testing.expect(args.b);
    try std.testing.expect(std.mem.eql(u8, &args.s, "hello"));
}

test "fully annonymous struct" {
    try comptime dump(.{ .int = @as(i32, 1234), .float = @as(f16, 5.5), .b = true, .s = "hello".* });
}
// <<= end blk =>>
