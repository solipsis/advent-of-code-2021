const std = @import("std");
const test_allocator = std.testing.allocator;
const ArrayList = std.ArrayList;
const fixedBufferStream = std.io.fixedBufferStream;

const Board = struct {
    buf: [25]isize,
};

pub fn parse(input: anytype, nums: *ArrayList(isize), boards: *ArrayList(Board)) !void {
    var buf = try input.readAllAlloc(test_allocator, 9999999);
    defer test_allocator.free(buf);
    std.debug.print("{s}\n", .{buf});

    var section_it = std.mem.split(buf, "\n\n");

    // first chunk is number list
    if (section_it.next()) |chunk| {
        var num_it = std.mem.split(chunk, ",");
        while (num_it.next()) |num| {
            var i: isize = try std.fmt.parseInt(isize, num, 10);
            try nums.append(i);
        }
    }

    for (nums.items) |num| {
        std.debug.print("nums: {}\n", .{num});
    }

    // later chunks are boards
    while (section_it.next()) |chunk| {
        var idx: usize = 0;
        var board_it = std.mem.tokenize(chunk, " \n");
        var board = try boards.addOne();

        while (board_it.next()) |num_str| {
            var i: isize = try std.fmt.parseInt(isize, num_str, 10);
            //   std.debug.print("i: {}\n", .{i});
            board.buf[idx] = i;
            idx += 1;
        }
    }

    std.debug.print("len: {}\n", .{boards.items.len});
}

pub fn draw_num(boards: *ArrayList(Board), num: isize) ?usize {
    const needle = [_]isize{num};
    for (boards.items) |*board, board_idx| {
        if (std.mem.indexOfPos(isize, board.buf[0..], 0, needle[0..])) |idx| {
            board.buf[idx] *= -1;
            std.debug.print("found: {} at {}\n", .{ num, idx });
            if (check_victory(board.buf)) {
                return board_idx;
            }
        }
    }
    return null;
}

pub fn check_victory(board: [25]isize) bool {
    const v1 = [_]usize{ 0, 5, 10, 15, 20 };
    const v2 = [_]usize{ 1, 6, 11, 16, 21 };
    const v3 = [_]usize{ 2, 7, 12, 17, 22 };
    const v4 = [_]usize{ 3, 8, 13, 18, 23 };
    const v5 = [_]usize{ 4, 9, 14, 19, 24 };

    const h1 = [_]usize{ 0, 1, 2, 3, 4 };
    const h2 = [_]usize{ 5, 6, 7, 8, 9 };
    const h3 = [_]usize{ 10, 11, 12, 13, 14 };
    const h4 = [_]usize{ 15, 16, 17, 18, 19 };
    const h5 = [_]usize{ 20, 21, 22, 23, 24 };

    //  const d1 = [_]usize{ 0, 6, 12, 18, 24 };
    //  const d2 = [_]usize{ 20, 16, 12, 8, 4 };

    const all_conditions = [_][5]usize{ v1, v2, v3, v4, v5, h1, h2, h3, h4, h5 };

    // TODO; Didn't account for value of zero. Hope it doesn't matter
    for (all_conditions) |cond| {
        var pass = true;
        for (cond) |idx| {
            if (board[idx] > 0) {
                pass = false;
            }
        }
        if (pass) {
            return true;
        }
    }
    return false;
}

pub fn sum_unmarked(board: [25]isize) isize {
    var sum: isize = 0;
    for (board) |num| {
        if (num > 0) {
            sum += num;
        }
    }
    return sum;
}

test "find" {
    const needle = [_]isize{1};
    const arr = [_]isize{ 0, 3, 2, 1 };
    if (std.mem.indexOfPos(isize, arr[0..], 0, needle[0..])) |idx| {
        std.debug.print("\n\nfound1: {}\n\n", .{idx});
    }
}

pub fn print_board(board: [25]isize) void {
    std.debug.print("\n----------------\n", .{});
    var idx: usize = 0;
    while (idx < 25) {
        for (board[idx .. idx + 5]) |num| {
            std.debug.print("{},", .{num});
        }
        std.debug.print("\n", .{});
        idx += 5;
    }
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
    var nums = ArrayList(isize).init(test_allocator);
    var boards = ArrayList(Board).init(test_allocator);
    defer nums.deinit();
    defer boards.deinit();

    var fbs = fixedBufferStream(input);

    try parse(fbs.reader(), &nums, &boards);
    //_ = draw_num(&boards, 5);

    var winning_number: isize = -1;
    for (nums.items) |num| {
        if (draw_num(&boards, num)) |idx| {
            winning_number = num;
            std.debug.print("winning_number: {}\n", .{winning_number});
            var sum = sum_unmarked(boards.items[idx].buf);
            std.debug.print("sum: {}\n", .{sum});

            // std.debug.print("Done: {}\n", .{idx});
            // print_board(boards.items[idx].buf);
            var product: isize = num * sum_unmarked(boards.items[idx].buf);

            std.debug.print("Part 1: {}\n", .{product});

            break;
        }
    }
}

test "part1" {
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var nums = ArrayList(isize).init(test_allocator);
    var boards = ArrayList(Board).init(test_allocator);
    defer nums.deinit();
    defer boards.deinit();

    var buf_stream = std.io.bufferedReader(file.reader());
    try parse(buf_stream.reader(), &nums, &boards);

    var winning_number: isize = -1;
    for (nums.items) |num| {
        if (draw_num(&boards, num)) |idx| {
            winning_number = num;
            std.debug.print("winning_number: {}\n", .{winning_number});
            var sum = sum_unmarked(boards.items[idx].buf);
            std.debug.print("sum: {}\n", .{sum});

            // std.debug.print("Done: {}\n", .{idx});
            // print_board(boards.items[idx].buf);
            var product: isize = num * sum_unmarked(boards.items[idx].buf);

            std.debug.print("Part 1: {}\n", .{product});

            break;
        }
    }
}
