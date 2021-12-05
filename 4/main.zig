const std = @import("std");
const test_allocator = std.testing.allocator;
const ArrayList = std.ArrayList;
const fixedBufferStream = std.io.fixedBufferStream;

const Board = struct {
    buf: [25]isize,
};

pub fn parse(input: anytype, nums: *ArrayList(usize), boards: *ArrayList(Board)) !void {
    var buf = try input.readAllAlloc(test_allocator, 9999999);
    defer test_allocator.free(buf);
    std.debug.print("{s}\n", .{buf});

    var section_it = std.mem.split(buf, "\n\n");

    // first chunk is number list
    if (section_it.next()) |chunk| {
        var num_it = std.mem.split(chunk, ",");
        while (num_it.next()) |num| {
            var i: usize = try std.fmt.parseUnsigned(usize, num, 10);
            try nums.append(i);
        }
    }

    for (nums.items) |num| {
        std.debug.print("nums: {}\n", .{num});
    }

    // later chunks are boards
    var idx: usize = 0;
    while (section_it.next()) |chunk| {
        var board_it = std.mem.tokenize(chunk, " \n");
        var board = try boards.addOne();

        while (board_it.next()) |num_str| {
            var i: isize = try std.fmt.parseInt(isize, num_str, 10);
            std.debug.print("i: {}\n", .{i});
            board.buf[idx] = i;
        }
    }

    std.debug.print("len: {}\n", .{boards.items.len});
}

test "sample1" {
    const input =
        \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
        \\
        \\22 13 17 11  0
        \\ 8  2 23  4 24
        \\21  9 14 16  7
        \\ 6 10  3 18  5
        \\ 1 12 20 15 19
        \\
        \\ 3 15  0  2 22
        \\ 9 18 13 17  5
        \\19  8  7 25 23
        \\20 11 10 24  4
        \\14 21 16 12  6
        \\
        \\14 21 17 24  4
        \\10 16 15  9 19
        \\18  8 23 26 20
        \\22 11 13  6  5
        \\ 2  0 12  3  7
    ;

    // var nums = ArrayList(u5).init(test_allocator);
    var nums = ArrayList(usize).init(test_allocator);
    var boards = ArrayList(Board).init(test_allocator);
    defer nums.deinit();
    defer boards.deinit();

    var fbs = fixedBufferStream(input);

    try parse(fbs.reader(), &nums, &boards);

    // TODO:
    // use making a board number negative as the flag for that number having been read
    // only 12 configurations to check for victory so shouldn't be terrible to hardcode
}
