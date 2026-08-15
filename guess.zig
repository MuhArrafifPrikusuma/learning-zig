const std = @import("std");
const guess = @This();

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var handle: HandleIo(1024) = undefined;
    handle.init(&io);

    const random_number: u8 = getRandom(&io) catch |err| {
        std.debug.print("{any}\n", .{err});
    };
    std.debug.print("{d}\n", .{random_number});

    try handle.stdout.print("<<- Find a random number ->>\n", .{});
    try handle.stdout.flush();

    var clue_counter: u8 = 0;
    while (true) {
        try handle.stdout.print("Guess the number: ", .{});
        try handle.stdout.flush();

        const rawInput = try handle.stdin.takeDelimiter('\n') orelse unreachable;
        const input = std.mem.trim(u8, rawInput, "\r\n");
        if (input.len == 0) continue;

        const correct = checkAnswer(u8, input, random_number) catch |err| switch (err) {
            error.InvalidCharacter => {
                std.debug.print("nope that's not a number\n", .{});
                continue;
            },

            error.Overflow => {
                std.debug.print("number too big!\n", .{});
                continue;
            },

            error.WrongAnswer => {
                std.debug.print("wrong answer\n", .{});
                clue_counter += try guess.clues(clue_counter, &io);
                continue;
            },
        };

        if (correct) {}
        std.debug.print("{any}\n", .{correct});
    }
}

fn getRandom(io: *const std.Io) !u8 {
    var buf: [8]u8 = undefined;
    io.*.random(&buf);

    const seed = std.mem.readInt(u64, &buf, .big);
    var rand = std.Random.Xoroshiro128.init(seed);

    var getRand = rand.random();

    return getRand.intRangeLessThan(u8, 0, 101);
}

fn checkAnswer(T: type, input: []const u8, answer: T) error{ InvalidCharacter, Overflow, WrongAnswer }!bool {
    const input_int = std.fmt.parseInt(T, input, 10) catch |err| return err;
    var maxSize: T = 0;
    maxSize = ~maxSize;

    if (input_int > maxSize)
        return error.Overflow;

    if (input_int != answer)
        return error.WrongAnswer;

    return true;
}

fn HandleIo(comptime bufSize: u64) type {
    return struct {
        bufout: [bufSize]u8 = undefined,
        bufin: [bufSize]u8 = undefined,

        stdout_wrapper: std.Io.File.Writer = undefined,
        stdin_wrapper: std.Io.File.Reader = undefined,

        stdout: *std.Io.Writer = undefined,
        stdin: *std.Io.Reader = undefined,

        fn init(self: *@This(), io: *const std.Io) void {
            self.stdout_wrapper = std.Io.File.stdout().writer(io.*, &self.bufout);
            self.stdin_wrapper = std.Io.File.stdin().reader(io.*, &self.bufin);

            self.stdout = &self.stdout_wrapper.interface;
            self.stdin = &self.stdin_wrapper.interface;
        }
    };
}

fn clues(clue_count: u8, io: *const std.Io) !u8 {
    var count: u8 = 0;

    var handle: HandleIo(1024) = undefined;
    handle.init(io);

    while (true) {
        switch (count) {
            0 => try handle.stdout.print("Need some clue?\n", .{}),
            1 => try handle.stdout.print("That's not a valid option\n", .{}),
            else => unreachable,
        }
        count = 0;
        try handle.stdout.print("1. yes\n2. no\nchoose: ", .{});
        try handle.stdout.flush();

        const rawInput = try handle.stdin.takeDelimiter('\n') orelse unreachable;
        const input = std.mem.trim(u8, rawInput, "\r\n");

        const input_int = std.fmt.parseInt(u8, input, 10) catch {
            count = 1;
            continue;
        };

        switch (input_int) {
            1 => {
                giveClues(clue_count, io);
            },
            2 => return 0,

            else => {
                count = 1;
                continue;
            },
        }
    }
    return 1;
}

fn giveClues(clue_count: u8, io: *const std.Io) void {
    var handle: HandleIo(1024) = undefined;
    handle.init(&io);
}
