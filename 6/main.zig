const std = @import("std");
const test_allocator = std.testing.allocator;
const fixedBufferStream = std.io.fixedBufferStream;
const expect = std.testing.expect;

pub fn parse(reader: anytype) ![9]isize {
    var buf = try reader.readAllAlloc(test_allocator, 999999);
    defer test_allocator.free(buf);
    var trimmed = std.mem.trim(u8, buf, "\n");

    var out = [_]isize{0} ** 9;

    var num_it = std.mem.split(trimmed, ",");
    while (num_it.next()) |raw_num| {
        var i = try std.fmt.parseInt(usize, raw_num, 10);
        out[i] += 1;
    }

    return out;
}

pub fn simulate_day(state: [9]isize) [9]isize {
    var copy = [9]isize{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    //std.mem.copy(isize, copy, state);

    copy[0] = state[1];
    copy[1] = state[2];
    copy[2] = state[3];
    copy[3] = state[4];
    copy[4] = state[5];
    copy[5] = state[6];
    copy[6] = state[7] + state[0];
    copy[7] = state[8];
    copy[8] = state[0];

    return copy;
}

pub fn count_fish(state: [9]isize) isize {
    var sum: isize = 0;
    for (state) |val| {
        sum += val;
    }
    return sum;
}

test "sample 1" {
    const input = "3,4,3,1,2";
    var fbs = fixedBufferStream(input);

    var state = try parse(fbs.reader());

    std.debug.print("start: {any}\n", .{state});
    var i: usize = 0;
    while (i < 80) : (i += 1) {
        state = simulate_day(state);
        //    std.debug.print("state: {any}\n", .{state});
    }

    const count = count_fish(state);
    std.debug.print("count: {}\n", .{count});
    try expect(count == 5934);
}

test "part 1" {
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var state = try parse(file.reader());

    std.debug.print("start: {any}\n", .{state});
    var i: usize = 0;
    while (i < 80) : (i += 1) {
        state = simulate_day(state);
        //    std.debug.print("state: {any}\n", .{state});
    }

    const count = count_fish(state);
    std.debug.print("count: {}\n", .{count});
}
