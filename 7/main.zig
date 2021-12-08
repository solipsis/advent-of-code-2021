const std = @import("std");
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

pub fn parse(reader: anytype) !ArrayList(isize) {
    var buf = try reader.readAllAlloc(test_allocator, 99999);
    defer test_allocator.free(buf);
    var trimmed = std.mem.trim(u8, buf, "\n"); // trailing newline

    var nums = ArrayList(isize).init(test_allocator);
    var num_it = std.mem.split(trimmed, ",");
    while (num_it.next()) |raw_num| {
        var i = try std.fmt.parseInt(isize, raw_num, 10);
        try nums.append(i);
    }

    return nums;
}

test "sample 1" {
    const input = "16,1,2,0,4,2,7,1,2,14";
    var fbs = std.io.fixedBufferStream(input);

    var nums = try parse(fbs.reader());
    defer nums.deinit();
    //std.debug.print("nums: {any}\n", .{nums.items});

    var min: isize = 9999999;
    var min_base: isize = -1;
    var base: isize = 0;
    while (base < 1000) : (base += 1) {
        //  std.debug.print("\n-------------\nbase: {}\n", .{base});
        var sum: isize = 0;
        for (nums.items) |num| {
            //std.debug.print("num: {}, base: {}: rawdiff: {}\n", .{ num, base, num - base });
            var diff = try std.math.absInt(num - base);
            //std.debug.print("diff: {}\n", .{num});
            sum += diff;
        }
        if (sum < min) {
            min = sum;
            min_base = base;
        }
        min = std.math.min(sum, min);
    }
    try expect(min == 37);
    std.debug.print(
        "sample 1: {} : min_base {}\n",
        .{ min, min_base },
    );

    // part 2
    min = 99999999;
    min_base = -1;
    base = 0;
    while (base < 1000) : (base += 1) {
        var sum: isize = 0;
        for (nums.items) |num| {
            const diff = try std.math.absInt(num - base);
            const cost: isize = @divExact(diff * (diff + 1), @as(isize, 2));
            sum += cost;
        }
        if (sum < min) {
            min = sum;
            min_base = base;
        }
    }
    std.debug.print(
        "sample 2: {} : min_base {}\n",
        .{ min, min_base },
    );
}

test "part 1" {
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var nums = try parse(file.reader());
    defer nums.deinit();
    //std.debug.print("nums: {any}\n", .{nums.items});

    var min: isize = 9999999;
    var min_base: isize = -1;
    var base: isize = 0;
    while (base < 1000) : (base += 1) {
        var sum: isize = 0;
        for (nums.items) |num| {
            var diff = try std.math.absInt(num - base);
            sum += diff;
        }
        if (sum < min) {
            min = sum;
            min_base = base;
        }
        min = std.math.min(sum, min);
    }
    std.debug.print(
        "part 1: {} : min_base {}\n",
        .{ min, min_base },
    );

    // part 2
    min = 99999999;
    min_base = -1;
    base = 0;
    while (base < 1000) : (base += 1) {
        var sum: isize = 0;
        for (nums.items) |num| {
            const diff = try std.math.absInt(num - base);
            const cost: isize = @divExact(diff * (diff + 1), @as(isize, 2));
            sum += cost;
        }
        if (sum < min) {
            min = sum;
            min_base = base;
        }
    }
    std.debug.print(
        "part 2: {} : min_base {}\n",
        .{ min, min_base },
    );
}
