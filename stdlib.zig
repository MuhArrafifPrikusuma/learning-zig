const std = @import("std");

test "Allocators" {
    // this is extreamly inefficient since it perform syscall and also
    // ask the OS for a whole page of memory so it can take kibibytes of memory even if
    // i only allocate like 1 byte
    const Allocator = std.heap.page_allocator;

    const memory = try Allocator.alloc(u8, 100);
    defer Allocator.free(memory);

    try std.testing.expect(memory.len == 100);
    try std.testing.expect(@TypeOf(memory) == []u8);
}

test "fixed buffer allocator" {
    // this one cannot exceed the amount of buffer that you initiated
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // this is the maximum, oh btw you can allocate multiple stuff too aslong it fits in the buffer
    const memory = try allocator.alloc(u8, 500);
    defer allocator.free(memory);
    const memory2 = try allocator.alloc(u8, 500);

    try std.testing.expect(memory.len == 500);
    try std.testing.expect(memory2.len == 500);
}

test "Arena allocator" {
    // take a child allocator and allow you to free all the allocator by freeing the arena
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // <- free all of the child allocator

    const allocator = arena.allocator();

    _ = try allocator.alloc(u8, 1);
    _ = try allocator.alloc(u8, 10);
    _ = try allocator.alloc(u8, 100);
    _ = try allocator.alloc(u8, 1000);
    _ = try allocator.alloc(u8, 10000);
    _ = try allocator.alloc(u8, 100000);
}

// free and alloc is used for slices, for single item use this
test "create and destroy" {
    const byte = try std.heap.page_allocator.create(u8);
    defer std.heap.page_allocator.destroy(byte);
    byte.* = 128;
    try std.testing.expect(byte.* == 128);
}

// general purpose debug allocator that can prevent use after free and detect leak
// and even thread safety, all of those can also be turned off via it's configuration
// struct. this allocator purpose is safety over performance but it's still might perform
// better than page allocator since it doesn't ask for a whole page
test "gpa" {
    // it's also good for testing
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();

        // if i didn't free it then throw an error
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const bytes = try allocator.alloc(u8, 200);
    defer allocator.free(bytes);

    try std.testing.expect(bytes.len == 200);
}

// std.heap.SmpAllocator is a general purpose allocator that was built for maximum perf
// with very few safety features

test "smpAlloc" {
    const allocator = std.heap.smp_allocator;

    const bytes = try allocator.alloc(u8, 2000);
    defer allocator.free(bytes);

    try std.testing.expect(bytes.len == 2000);
}

// ArrayList, a way to make string without shooting yourself
// best used for runtime slices

test "ArrayList" {
    const allocator = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);
    try list.append(allocator, 'H');
    try list.append(allocator, 'E');
    try list.append(allocator, 'L');
    try list.append(allocator, 'L');
    try list.append(allocator, 'O');
    try list.append(allocator, '!');
    try list.appendSlice(allocator, ", World!");

    try std.testing.expect(std.mem.eql(u8, list.items, "HELLO!, World!"));
}

// Filesystem
test "create, write, seekto, read" {
    const io = std.testing.io; // <- use init io in non testing env
    const file = try std.Io.Dir.cwd().createFile(io, "junkfile.txt", .{ .read = true });
    defer {
        file.close(io);
        std.Io.Dir.cwd().deleteFile(io, "junkfile.txt") catch {};
    }

    const expected_String = "Hello World!";

    var write_buffer: [100]u8 = undefined;
    var writer = file.writer(io, &write_buffer);
    try writer.interface.writeAll(expected_String);

    try writer.flush(); // flush buffer to file immediately

    var read_buffer: [4096]u8 = undefined;
    var reader = file.reader(io, &read_buffer);
    const bytes_read = try reader.interface.readSliceShort(&read_buffer);

    std.debug.print("string in read: {s}\n", .{read_buffer[0..bytes_read]});
    try std.testing.expectEqualStrings(expected_String, read_buffer[0..bytes_read]);
}

// file stat

test "file stats" {
    const Io = std.testing.io;
    const file = try std.Io.Dir.cwd().createFile(Io, "idkfile.txt", .{ .read = true });
    defer {
        file.close(Io);
        std.Io.Dir.cwd().deleteFile(Io, "idkfile.txt") catch {};
    }

    const content = "Hello!";
    var write_buffer: [100]u8 = undefined;
    var writer = file.writer(Io, &write_buffer);
    try writer.interface.writeAll(content);
    try writer.flush();

    var read_buffer: [4096]u8 = undefined;
    var reader = file.reader(Io, &read_buffer);

    var dest_buffer: [4096]u8 = undefined;

    const bytes_read = try reader.interface.readSliceShort(&dest_buffer);
    const sliceRead = dest_buffer[0..bytes_read];

    const stat = try file.stat(Io);

    try std.testing.expectEqualStrings(content, sliceRead);
    try std.testing.expect(stat.kind == .file);
    try std.testing.expect(stat.ctime.toNanoseconds() <= std.Io.Clock.now(.real, Io).toNanoseconds());
    try std.testing.expect(stat.mtime.toNanoseconds() <= std.Io.Clock.now(.real, Io).toNanoseconds());
    try std.testing.expect(stat.atime.?.toNanoseconds() <= std.Io.Clock.now(.real, Io).toNanoseconds());

    std.debug.print("fileSize {d} bytes and contain:\n", .{stat.size});
    std.debug.print("{s}\n", .{sliceRead});
}

test "make dir" {
    const Io = std.testing.io;
    try std.Io.Dir.cwd().createDir(Io, "test-dir", .default_dir);
    var iter_dir = try std.Io.Dir.cwd().openDir(Io, "test-dir", .{ .iterate = true });

    defer {
        iter_dir.close(Io);
        std.Io.Dir.cwd().deleteTree(Io, "test-dir") catch unreachable;
    }

    _ = try iter_dir.createFile(Io, "a", .{ .read = true });
    _ = try iter_dir.createFile(Io, "b", .{ .read = true });
    _ = try iter_dir.createFile(Io, "c", .{ .read = true });

    var file_count: usize = 0;
    var iterate_over = iter_dir.iterate();
    while (try iterate_over.next(Io)) |entry| {
        if (entry.kind == .file) file_count += 1;
    }

    try std.testing.expect(file_count == 3);
}

// readers and writers

test "reader writer" {
    const allocator = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    try list.print(allocator, "Hello {s}!\n", .{"World"});

    try std.testing.expectEqualStrings("Hello World!\n", list.items);
}

test "reading from file" {
    const Io = std.testing.io;
    const allocator = std.testing.allocator;
    const file = try std.Io.Dir.cwd().openFile(Io, "testFile.txt", .{ .mode = .read_only });
    defer file.close(Io);

    const stat = try file.stat(Io);

    // i read the whole file so use unbuffered rader;
    // the standard buffer size for reading file is 4096 bytes since it allign perfectly
    // with OS page size
    var file_buffer: [0]u8 = undefined;
    var reader = file.reader(Io, &file_buffer);

    const content = try reader.interface.readAlloc(allocator, stat.size);

    defer allocator.free(content);

    std.debug.print("content: {s} <<- EOF ->>\nfile size: {d} KB\n", .{ content, stat.size / 1024 });
}

test "read until newline" {
    const Io = std.testing.io;

    var stdout_buf: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(Io, &stdout_buf);
    const stdout: *std.Io.Writer = &writer.interface;

    var stdin_buf: [1024]u8 = undefined;
    var reader = std.Io.File.stdin().reader(Io, &stdin_buf);
    const stdin: *std.Io.Reader = &reader.interface;

    try stdout.writeAll("Enter your name\n");
    try stdout.flush();

    const bare_line = try stdin.takeDelimiter('\n') orelse unreachable;
    const line = std.mem.trim(u8, bare_line, "\n\r");

    try stdout.print("Yourname is: \"{s}\"\n", .{line});
    try stdout.flush();
}

// formatting

test "fmt" {
    const allocator = std.testing.allocator;
    const string = try std.fmt.allocPrint(allocator, "{d} + {d} = {d}", .{ 9, 10, 19 });
    defer allocator.free(string);

    try std.testing.expect(std.mem.eql(u8, string, "9 + 10 = 19"));
}

test "print" {
    const allocator = std.testing.allocator;

    var Lists: std.ArrayList(u8) = .empty;
    defer Lists.deinit(allocator);
    try Lists.print(
        allocator,
        "{} + {} = {}",
        .{ 9, 10, 19 },
    );

    try std.testing.expect(std.mem.eql(u8, Lists.items, "9 + 10 = 19"));
}

// NOTE: std.debug.print prints to stderr and it's protected with mutex by default

// custom formatting

const Person = struct {
    name: []const u8,
    birth_year: u16,
    death_year: ?u16,

    pub fn format(self: Person, writer: *std.Io.Writer) !void {
        try writer.print("{s} ({}-", .{ self.name, self.birth_year });

        if (self.death_year) |year| {
            try writer.print("{}", .{year});
        }
        try writer.writeAll(")\r\n");
    }
};

test "custom format" {
    const john: Person = .{
        .name = "John Carmack",
        .birth_year = 1970,
        .death_year = null,
    };

    // automatically format it
    std.debug.print("{f}", .{john});
    try std.testing.expectFmt("John Carmack (1970-)\r\n", "{f}", .{john});

    const dennis: Person = .{
        .name = "Dennis Ritchie",
        .birth_year = 1941,
        .death_year = 2011,
    };

    std.debug.print("{f}", .{dennis});
    try std.testing.expectFmt("Dennis Ritchie (1941-2011)\r\n", "{f}", .{dennis});
}

// JSON
const Place = struct { lat: f64, long: f64 };
test "json parsing" {
    const allocator = std.testing.allocator;
    // very cool built in parser for json so you don't have to make it from scratch
    // althought i want to do it
    const parsed = try std.json.parseFromSlice(Place, allocator,
        \\{ "lat": 40.232332, "long": -74.232121 } 
    , .{});
    defer parsed.deinit();

    const place = parsed.value;

    try std.testing.expect(place.lat == 40.232332);
    try std.testing.expect(place.long == -74.232121);
}

test "json stringify" {
    const ttPlace: Place = .{
        .lat = 51.12312,
        .long = -21.2132,
    };

    const allocator = std.testing.allocator;
    var string = std.Io.Writer.Allocating.init(allocator);
    defer string.deinit();

    try string.writer.print("{f}", .{std.json.fmt(ttPlace, .{})});

    try std.testing.expectEqualStrings(
        \\{"lat":51.12312,"long":-21.2132}
    ,
        string.written(),
    );
}

test "json parsing with strings" {
    const allocator = std.testing.allocator;
    const User = struct { name: []u8, age: u8 };

    const parsed = try std.json.parseFromSlice(User, allocator,
        \\{"name":"idk","age":18}
    , .{});
    defer parsed.deinit();

    const user = parsed.value;

    try std.testing.expectEqualStrings("idk", user.name);
    try std.testing.expect(user.age == 18);
}
// random number

test "random numbers" {
    const io = std.testing.io;
    var prng: std.Random.Xoroshiro128 = .init(blk: {
        var buf: [8]u8 = undefined;
        io.random(&buf);
        const seed = std.mem.readInt(u64, &buf, .big);

        break :blk seed;
    });

    const rand = prng.random();

    const a = rand.float(f32);
    const b = rand.boolean();
    const c = rand.uintAtMost(u64, 2000000000000);
    const d = rand.intRangeAtMost(i64, -50_000_000, 100_000_000);

    std.debug.print("float prng: {d}\nbool: {any}\nuint: {d}\nintRange: {d}\n", .{ a, b, c, d });
}

test "crypto secure rng" {
    const io = std.testing.io;
    var buf: [32]u8 = undefined;
    try std.Io.randomSecure(io, &buf);

    var crypt = std.Random.DefaultCsprng.init(buf);

    const rand = crypt.random();
    std.debug.print("{d}\n", .{rand.float(f64)});
    std.debug.print("{d}\n", .{rand.intRangeAtMost(u8, 0, 100)});
    std.debug.print("{d}\n", .{rand.uintLessThan(u64, 222_222_222_222)});
}

// Threads

// this run in worker thread
fn ticker(step: u8) void {
    const io = std.testing.io;
    while (true) {
        std.Io.sleep(io, std.Io.Duration.fromSeconds(1), std.Io.Clock.real) catch unreachable;
        tick += @as(isize, step);
        std.debug.print("worker thread counter: {d}\n", .{tick});
        if (tick == 10) break;
    }
}
var tick: isize = 0;

test "threading" {
    const io = std.testing.io;
    var thread = try std.Thread.spawn(.{}, ticker, .{@as(u8, 1)});

    std.debug.print("tick: {d}\n", .{tick});
    try std.testing.expect(tick == 0);
    // this time to perfectly take tick when it has the value of 2
    // but in real scenario you wouldn't want to wait like this since it's so freaking slow
    // std.Io.sleep(io, std.Io.Duration.fromSeconds(2), std.Io.Clock.real) catch unreachable;

    var i: u8 = 0;
    while (i < 100) : (i += 1) {
        std.Io.sleep(io, std.Io.Duration.fromMilliseconds(100), std.Io.Clock.real) catch unreachable;
        std.debug.print("main thread counter: {d}\n", .{i});
    }
    thread.join();
    std.debug.print("tick: {d}\n", .{tick});
    try std.testing.expect(tick == 10);
}
