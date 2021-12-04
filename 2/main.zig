const std = @import("std");
const test_allocator = std.testing.allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

const Direction = enum { invalid, forward, down, up };

const Instruction = struct {
    dir: Direction,
    amt: isize,
};

pub fn parseInput(comptime T: type, f: fn ([]const u8) T, input: anytype) !ArrayList(T) {
    var buf: [1024]u8 = undefined;
    var list = ArrayList(T).init(test_allocator);
    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        //      std.debug.print("\nline: {s}\n", .{line});
        try list.append(f(line));
    }

    return list;
}

pub fn parseInstruction(str: []const u8) Instruction {
    // split at space
    if (std.mem.indexOf(u8, str, " ")) |idx| {
        const dirStr = str[0..idx];
        const numStr = str[(idx + 1)..];
        //std.debug.print("start: {s}\n", .{str[0..idx]});
        //std.debug.print("end: {s}\n", .{str[(idx + 1)..]});

        var i: isize = std.fmt.parseUnsigned(isize, numStr, 10) catch 999999999;

        const dir = std.meta.stringToEnum(Direction, dirStr) orelse Direction.invalid;

        return Instruction{
            .dir = dir,
            .amt = i,
        };
    }
    unreachable;
}

pub fn calculatePosition(ins: []Instruction) isize {
    var depth: isize = 0;
    var horizontal: isize = 0;

    for (ins) |i| {
        switch (i.dir) {
            Direction.forward => {
                horizontal = horizontal + i.amt;
            },
            Direction.up => {
                depth = depth - i.amt;
            },
            Direction.down => {
                depth = depth + i.amt;
            },
            Direction.invalid => {
                depth = -1;
            },
        }
    }
    return depth * horizontal;
}

pub fn blah(str: []const u8) []const u8 {
    return str[0..];
}

test "parse" {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buf_stream = std.io.bufferedReader(file.reader());
    var in_stream = buf_stream.reader();

    var list = try parseInput(Instruction, parseInstruction, in_stream);
    defer list.deinit();
    const product = calculatePosition(list.items);
    //   std.debug.print("\n{s}\n", .{list.items[0]});
    std.debug.print("\nproduct: {}\n", .{product});
}

pub fn calculatePosition2(ins: []Instruction) isize {
    var depth: isize = 0;
    var horizontal: isize = 0;
    var aim: isize = 0;

    for (ins) |i| {
        switch (i.dir) {
            Direction.forward => {
                horizontal += i.amt;
                depth += aim * i.amt;
            },
            Direction.up => {
                aim += i.amt;
            },
            Direction.down => {
                aim -= i.amt;
            },
            Direction.invalid => {
                depth = -1;
            },
        }
    }
    std.debug.print("depth: {}, horiz: {}, aim: {}\n", .{ depth, horizontal, aim });
    return depth * horizontal;
}

test "part2" {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buf_stream = std.io.bufferedReader(file.reader());
    var in_stream = buf_stream.reader();

    var list = try parseInput(Instruction, parseInstruction, in_stream);
    defer list.deinit();
    const product = calculatePosition2(list.items);
    //  std.debug.print("\n{s}\n", .{list.items[0]});
    std.debug.print("\npart2: {}\n", .{product});
}
