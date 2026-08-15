const std = @import("std");
const guess = @This();

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var handle: HandleIo(1024) = undefined;
    handle.init(&io);

    const random_number: u8 = getRandom(&io, 0, 100) catch |err| {
        std.debug.print("{any}\n", .{err});
    };

    try handle.stdout.print("<<- Find a random number ->>\n", .{});

    var clue_counter: u8 = 0;

    while (true) {
        try handle.stdout.print("Guess the number: ", .{});
        try handle.stdout.flush();

        const rawInput = try handle.stdin.takeDelimiter('\n') orelse unreachable;
        const input = std.mem.trim(u8, rawInput, "\r\n");
        if (input.len == 0) continue;

        const correct = checkAnswer(u8, input, random_number) catch |err| switch (err) {
            error.InvalidCharacter => {
                try handle.stdout.print("nope that's not a number\n", .{});
                try handle.stdout.flush();
                continue;
            },

            error.Overflow => {
                try handle.stdout.print("number too big!\n", .{});
                try handle.stdout.flush();
                continue;
            },

            error.WrongAnswer => {
                try handle.stdout.print("wrong answer!\n", .{});
                try handle.stdout.flush();
                clue_counter += try guess.clues(clue_counter, &io, &random_number);
                continue;
            },
        };

        if (correct) {
            try handle.stdout.print("{d} IS THE CORRECT ANSWER!, YOU WIN!\n", .{random_number});
            try handle.stdout.flush();
            break;
        }
    }
}

fn getRandom(io: *const std.Io, min: u8, max: u8) !u8 {
    var buf: [8]u8 = undefined;
    io.*.random(&buf);

    const seed = std.mem.readInt(u64, &buf, .big);
    var rand = std.Random.Xoroshiro128.init(seed);

    var getRand = rand.random();

    return getRand.intRangeLessThan(u8, min, max + 1);
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

fn clues(clue_count: u8, io: *const std.Io, answer: *const u8) !u8 {
    var count: u8 = 0;

    var handle: HandleIo(1024) = undefined;
    handle.init(io);

    if (clue_count >= 7) {
        try handle.stdout.print("oops ran out of clues\n", .{});
        try handle.stdout.flush();
        return 0;
    }

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
                guess.giveClues(clue_count, io, answer) catch unreachable;
                return 1;
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

fn giveClues(clue_count: u8, io: *const std.Io, answer: *const u8) !void {
    var handle: HandleIo(1024) = undefined;
    handle.init(io);

    const which = guess.getRandom(io, clue_count, 10) catch |err| std.debug.print("{any}\n", .{err});

    switch (which) {
        0...4 => {
            if (answer.* % @as(u8, 2) == 0) {
                try handle.stdout.print("clue: the answer is an even number\n", .{});
            } else {
                try handle.stdout.print("clue: the answer is an odd number\n", .{});
            }
            try handle.stdout.flush();
        },
        5...7 => {
            var n: u8 = 0;
            var val: u8 = answer.*;

            n = guess.getRandom(io, 0, answer.*) catch unreachable;
            val -= n;
            try handle.stdout.print("the number is {d} <= ? <=", .{val});

            n = guess.getRandom(io, answer.* - val, 100 - val) catch unreachable;
            val += n;
            try handle.stdout.print(" {d}\n", .{val});
        },
        8...10 => {
            var n: u8 = 0;
            var val: u8 = answer.*;

            n = guess.getRandom(io, 0, 5) catch unreachable;
            if (answer.* - n < 0) n = 0;

            val = answer.* - n;
            try handle.stdout.print("number is {d} <= ? <=", .{val});

            n = guess.getRandom(io, 0, 5) catch unreachable;
            if (answer.* + n > 100) n = 0;

            val = answer.* + n;
            try handle.stdout.print(" {d}\n", .{val});
        },
        else => unreachable,
    }
    try handle.stdout.flush();
}
