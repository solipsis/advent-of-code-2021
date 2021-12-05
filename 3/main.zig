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

pub fn parseInputSample(input: anytype) !ArrayList(u5) {
    var buf: [1024]u8 = undefined;
    var list = ArrayList(u5).init(test_allocator);
    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var i: u5 = try std.fmt.parseUnsigned(u5, line, 2);
        std.debug.print("\n{}\n", .{i});
        try list.append(i);
        //std.debug.print("x{}\n", .{list.items[0]});
    }
    return list;
}

pub fn calcPowerSample(nums: []u5) !usize {
    var sums = [5]usize{ 0, 0, 0, 0, 0 };
    for (nums) |n| {
        var shift: u3 = 0;
        while (shift <= 4) {
            var bit: u64 = @as(u8, 1) << shift;

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

// for each item remaining in the list
// calc count of bit index
// while (idx < items.len) {
//   if (bit at bitindex not majority) {
//      swapRemove
//   }

pub fn filter(arr: *ArrayList(u5)) void {
    std.debug.print("Type: {s}\n", .{@TypeOf(arr)});
    _ = arr.swapRemove(1);
}

pub fn filterSample(samples: *ArrayList(u5), bitIdx: u3) !void {
    //samples.swapRemove(1);

    var ones: isize = 0;
    for (samples.items) |n| {
        var bit: u64 = @as(u8, 1) << bitIdx;

        if (bit & n != 0) {
            ones += 1;
        } else {
            ones -= 1;
        }
    }
    std.debug.print("sum: {}\n", .{ones});

    var target: usize = 0;
    if (ones >= 0) {
        target = 1;
    }

    std.debug.print("target: {}\n", .{target});
    outer: while (true) {
        for (samples.items) |item, idx| {
            var b: [5]u8 = undefined;
            _ = try bufPrint(&b, "{b:0>5}", .{item});
            std.debug.print("{s}: {}\n", .{ b, item });

            // var bit: u64 = @as(u8, 1) << bitIdx;
            if ((item >> bitIdx) & 1 != target) {
                //   if ((bit & item) != target) {
                _ = samples.swapRemove(idx);
                std.debug.print("deleting: {}\n", .{item});
                continue :outer;
            }
        }
        break :outer;
    }
}

pub fn calcOxygenSample(starting: *ArrayList(u5)) !usize {
    var bitIdx: isize = 4;
    while (bitIdx >= 0) {
        std.debug.print("{s}\n", .{"FFFFFFFFFFF"});
        try filterSample(starting, @intCast(u3, bitIdx));
        for (starting.items) |rem| {
            std.debug.print("rem: {}\n", .{rem});
        }
        bitIdx -= 1;
    }

    return 0;
}

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
    var list = try parseInputSample(fbs.reader());
    defer list.deinit();
    for (list.items) |i| {
        std.debug.print("items: {}\n", .{i});
    }
    //  var power = try calcPowerSample(list.items);
    // try expect(power == 198);
    _ = try calcOxygenSample(&list);
}

test "part1" {
    //  var file = try std.fs.cwd().openFile("input.txt", .{});
    //defer file.close();
    //var buf_stream = std.io.bufferedReader(file.reader());
    //var list = try parseInput(buf_stream.reader());
    //defer list.deinit();
    //const power = try calcPower(list.items);
    //  std.debug.print("Part 1: {}\n", .{power});
}
