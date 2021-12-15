const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

const Point = struct {
    x: isize,
    y: isize,
};

pub fn foldHorizontal(points: *AutoHashMap(Point, bool), fold_x: isize) !void {
    var to_add = ArrayList(Point).init(test_allocator);
    var to_remove = ArrayList(Point).init(test_allocator);
    defer to_add.deinit();
    defer to_remove.deinit();

    var point_it = points.iterator();
    while (point_it.next()) |point| {
        // translate point if right of the fold line
        if (point.key_ptr.*.x > fold_x) {
            const x = fold_x - (-fold_x + point.key_ptr.x);
            const y = point.key_ptr.y;
            try to_add.append(Point{ .x = x, .y = y });
            try to_remove.append(point.key_ptr.*);
        }
    }

    for (to_remove.items) |item| {
        _ = points.remove(item);
    }
    for (to_add.items) |item| {
        try points.put(item, true);
    }
}

pub fn foldVertical(points: *AutoHashMap(Point, bool), fold_y: isize) !void {
    var to_add = ArrayList(Point).init(test_allocator);
    var to_remove = ArrayList(Point).init(test_allocator);
    defer to_add.deinit();
    defer to_remove.deinit();

    var point_it = points.iterator();
    while (point_it.next()) |point| {
        // translate point if right of the fold line
        if (point.key_ptr.*.y > fold_y) {
            const x = point.key_ptr.x;
            const y = fold_y - (-fold_y + point.key_ptr.y);
            try to_add.append(Point{ .x = x, .y = y });
            try to_remove.append(point.key_ptr.*);
        }
    }

    for (to_remove.items) |item| {
        _ = points.remove(item);
    }
    for (to_add.items) |item| {
        try points.put(item, true);
    }
}

pub fn print(points: AutoHashMap(Point, bool)) !void {
    var point_it = points.iterator();
    var max_x: isize = -1;
    var max_y: isize = -1;

    while (point_it.next()) |point| {
        max_x = std.math.max(max_x, point.key_ptr.x);
        max_y = std.math.max(max_y, point.key_ptr.y);
    }
    const row_size = max_x + 1;
    const height = max_y + 1;

    var buf = try test_allocator.alloc(u8, @intCast(usize, row_size * height));
    std.mem.set(u8, buf, 0);
    defer test_allocator.free(buf);

    point_it = points.iterator();
    while (point_it.next()) |point| {
        buf[@intCast(usize, (point.key_ptr.y * row_size) + point.key_ptr.x)] = 1;
    }

    std.debug.print("-------------------------\n\n", .{});
    for (buf) |byte, idx| {
        if (byte == 1) {
            std.debug.print("{}", .{byte});
        } else {
            std.debug.print(" ", .{});
        }
        if ((idx + 1) % @intCast(usize, row_size) == 0) {
            std.debug.print("\n", .{});
        }
    }
    std.debug.print("\n", .{});
}

test "part 1" {
    std.debug.print("\n", .{});
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var paper = try parse(file.reader());
    defer paper.deinit();

    try foldHorizontal(&paper, 655);

    std.debug.print("Part 1: {}\n", .{paper.count()});

    try foldVertical(&paper, 447);

    try foldHorizontal(&paper, 327);
    try foldVertical(&paper, 223);
    try foldHorizontal(&paper, 163);
    try foldVertical(&paper, 111);
    try foldHorizontal(&paper, 81);

    try foldVertical(&paper, 55);
    try foldHorizontal(&paper, 40);
    try foldVertical(&paper, 27);
    try foldVertical(&paper, 13);
    try foldVertical(&paper, 6);

    point_it = paper.iterator();
    try print(paper);
}

test "sample 1" {
    std.debug.print("\n", .{});
    const input =
        \\6,10
        \\0,14
        \\9,10
        \\0,3
        \\10,4
        \\4,11
        \\6,0
        \\6,12
        \\4,1
        \\0,13
        \\10,12
        \\3,4
        \\3,0
        \\8,4
        \\1,10
        \\2,14
        \\8,10
        \\9,0
        \\
        \\fold along y=7
        \\fold along x=5
    ;
    var fbs = std.io.fixedBufferStream(input);
    var paper = try parse(fbs.reader());
    defer paper.deinit();

    var point_it = paper.iterator();
    while (point_it.next()) |entry| {
        std.debug.print("P: {any}\n", .{entry.key_ptr.*});
    }

    try foldVertical(&paper, 7);
    try foldHorizontal(&paper, 5);

    point_it = paper.iterator();
    while (point_it.next()) |entry| {
        std.debug.print("done: {any}\n", .{entry.key_ptr.*});
    }
    try print(paper);
}

pub fn parse(reader: anytype) !AutoHashMap(Point, bool) {
    var buf = try reader.readAllAlloc(test_allocator, 99999);
    defer test_allocator.free(buf);
    var trimmed = std.mem.trim(u8, buf, "\n");

    var points = AutoHashMap(Point, bool).init(test_allocator);

    var section_it = std.mem.split(trimmed, "\n\n");

    // first section is all the point data
    var line_it = std.mem.split(section_it.next().?, "\n");
    while (line_it.next()) |raw_line| {
        var point_it = std.mem.split(raw_line, ",");
        // exactly 2 integers per line
        var x = try std.fmt.parseInt(isize, point_it.next().?, 10);
        var y = try std.fmt.parseInt(isize, point_it.next().?, 10);

        try points.put(Point{ .x = x, .y = y }, true);
    }

    // 2nd section is fold data
    var fold_it = std.mem.split(section_it.next().?, "\n");
    while (fold_it.next()) |raw_fold| {
        std.debug.print("{s}\n", .{raw_fold});
    }

    return points;
}
