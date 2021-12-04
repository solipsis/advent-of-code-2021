const std = @import("std");
const bufPrint = std.fmt.bufPrint;
const test_allocator = std.testing.allocator;
const ArrayList = std.ArrayList;
const fixedBufferStream = std.io.fixedBufferStream;
const expect = std.testing.expect;

pub fn parseInput(input: anytype) !ArrayList(u12) {
    var buf: [1024]u8 = undefined;
    var list = ArrayList(u12).init(test_allocator);
    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var i: u12 = try std.fmt.parseUnsigned(u12, line, 2);
        try list.append(i);
    }
    return list;
}

//pub fn arrToNum() {
//}

pub fn calcPower(nums: []u12) !usize {
    var sums = [12]usize{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    for (nums) |n| {
        var shift: u6 = 0;
        while (shift < 12) {
            var bit: u64 = @as(u64, 1) << shift;

            if (bit & n != 0) {
                sums[11 - shift] += 1;
            }
            //std.debug.print("bit: {}\n", .{bit & n});
            shift += 1;
        }
    }

    std.debug.print("{s}\n", .{"**********"});
    for (sums) |sum| {
        std.debug.print("{}, ", .{sum});
    }

    std.debug.print("{s}\n", .{"--------------"});
    var res = [12]usize{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    for (sums) |sum, idx| {
        if (sum > nums.len / 2) {
            res[idx] = 1;
        }
        std.debug.print("{}", .{res[idx]});
    }
    var b: [12]u8 = undefined;
    _ = try bufPrint(&b, "{}{}{}{}{}{}{}{}{}{}{}{}", .{ res[0], res[1], res[2], res[3], res[4], res[5], res[6], res[7], res[8], res[9], res[10], res[11] });
    var slice = b[0..];

    std.debug.print("\n{s}\n", .{slice});

    const gamma = try std.fmt.parseUnsigned(u12, slice, 2);
    std.debug.print("gamma: {}\n", .{gamma});
    const epsilon = ~gamma;
    std.debug.print("epsilon: {}\n", .{epsilon});

    return @as(usize, gamma) * @as(usize, epsilon);
}

test "sample1" {
    const input =
        \\00100
        \\11110
        \\10110
        \\10111
        \\10101
        \\01111
        \\00111
        \\11100
        \\10000
        \\11001
        \\00010
        \\01010
    ;
    var fbs = fixedBufferStream(input);
    var list = try parseInput(fbs.reader());
    defer list.deinit();
    for (list.items) |i| {
        std.debug.print("{}\n", .{i});
    }
    // const power = try calcPower(list.items);
    // try expect(power == 198);
}

test "part1" {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buf_stream = std.io.bufferedReader(file.reader());
    var list = try parseInput(buf_stream.reader());
    defer list.deinit();
    const power = try calcPower(list.items);
    std.debug.print("Part 1: {}\n", .{power});
}
