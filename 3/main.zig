const std = @import("std");
const bufPrint = std.fmt.bufPrint;
const test_allocator = std.testing.allocator;
const ArrayList = std.ArrayList;
const fixedBufferStream = std.io.fixedBufferStream;
const expect = std.testing.expect;

pub fn parseInput(input: anytype) !ArrayList(u5) {
    var buf: [1024]u8 = undefined;
    var list = ArrayList(u5).init(test_allocator);
    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var i: u5 = try std.fmt.parseUnsigned(u5, line, 2);
        try list.append(i);
    }
    return list;
}

//pub fn arrToNum() {
//}

pub fn calcPower(nums: []u5) !usize {
    var sums = [5]usize{ 0, 0, 0, 0, 0 };
    for (nums) |n| {
        var shift: u3 = 0;
        while (shift < 5) {
            var bit: u64 = @intCast(u8, 1) << shift;

            if (bit & n != 0) {
                sums[4 - shift] += 1;
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
    var res = [5]usize{ 0, 0, 0, 0, 0 };

    for (sums) |sum, idx| {
        if (sum > nums.len / 2) {
            res[idx] = 1;
        }
        std.debug.print("{}", .{res[idx]});
    }
    var b: [5]u8 = undefined;
    _ = try bufPrint(&b, "{}{}{}{}{}", .{ res[0], res[1], res[2], res[3], res[4] });
    var slice = b[0..];

    std.debug.print("\n{s}\n", .{slice});

    const gamma = try std.fmt.parseUnsigned(u5, slice, 2);
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
    const power = try calcPower(list.items);
    try expect(power == 198);
}
