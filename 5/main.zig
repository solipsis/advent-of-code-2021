const std = @import("std");
const test_allocator = std.testing.allocator;
const ArrayList = std.ArrayList;
const fixedBufferStream = std.io.fixedBufferStream;

const Line = struct {
    x1: isize,
    x2: isize,
    y1: isize,
    y2: isize,
};

const Point = struct {
    x: isize,
    y: isize,
};

pub fn parse(reader: anytype) !ArrayList(Line) {
    var buf = try reader.readAllAlloc(test_allocator, 999999);
    defer test_allocator.free(buf);

    var Lines = ArrayList(Line).init(test_allocator);
    var line_it = std.mem.split(buf, "\n");
    while (line_it.next()) |raw_line| {
        if (raw_line.len == 0) {
            continue;
        }
        // std.debug.print("raw_line: {s}\n", .{raw_line});
        // std.debug.print("raw_hex: {x}\n", .{raw_line[0]});
        var point_it = std.mem.tokenize(raw_line, ",-> ");
        // should be exactly 4 points
        var x1 = try std.fmt.parseInt(isize, point_it.next().?, 10);
        var y1 = try std.fmt.parseInt(isize, point_it.next().?, 10);
        var x2 = try std.fmt.parseInt(isize, point_it.next().?, 10);
        var y2 = try std.fmt.parseInt(isize, point_it.next().?, 10);

        var line = try Lines.addOne();
        line.x1 = x1;
        line.x2 = x2;
        line.y1 = y1;
        line.y2 = y2;

        // std.debug.print("line: {}\n", .{line});
    }

    return Lines;
}

pub fn calc_overlap(lines: []Line, include_diagonals: bool) !isize {
    var point_map = std.AutoHashMap(Point, isize).init(test_allocator);
    defer point_map.deinit();

    for (lines) |line| {
        var p1 = Point{ .x = line.x1, .y = line.y1 };
        var p2 = Point{ .x = line.x2, .y = line.y2 };

        if (p1.x == p2.x) {
            //            std.debug.print("x: {} {}\n", .{ p1, p2 });
            var start = std.math.min(p1.y, p2.y);
            var end = std.math.max(p1.y, p2.y);

            while (start <= end) : (start += 1) {
                var current = Point{ .x = p1.x, .y = start };
                const existing = try point_map.getOrPutValue(current, 0);
                try point_map.put(current, existing.value_ptr.* + 1);
            }
        } else if (p1.y == p2.y) {
            //std.debug.print("y: {} {}\n", .{ p1, p2 });
            var start = std.math.min(p1.x, p2.x);
            var end = std.math.max(p1.x, p2.x);

            while (start <= end) : (start += 1) {
                var current = Point{ .x = start, .y = p1.y };
                const existing = try point_map.getOrPutValue(current, 0);
                try point_map.put(current, existing.value_ptr.* + 1);
            }
        } else if (include_diagonals) {
            //std.debug.print("diagonal {} {}\n", .{ p1, p2 });
            var xmod: isize = 1;
            var ymod: isize = 1;
            if (p1.x > p2.x) {
                xmod = -1;
            }
            if (p1.y > p2.y) {
                ymod = -1;
            }

            var new = Point{ .x = p1.x, .y = p1.y };
            while (new.x != p2.x) {
                //std.debug.print("put {}\n", .{new});
                const existing = try point_map.getOrPutValue(new, 0);
                try point_map.put(new, existing.value_ptr.* + 1);
                new.x += xmod;
                new.y += ymod;
            }
            // 1 final point at the destination
            const existing = try point_map.getOrPutValue(new, 0);
            try point_map.put(new, existing.value_ptr.* + 1);
        }
    }

    var sum: isize = 0;
    var map_iter = point_map.iterator();
    while (map_iter.next()) |entry| {
        if (entry.value_ptr.* >= 2) {
            sum += 1;
        }
    }

    return sum;
}

test "sample1" {
    const input =
        \\0,9 -> 5,9
        \\8,0 -> 0,8
        \\9,4 -> 3,4
        \\2,2 -> 2,1
        \\7,0 -> 7,4
        \\6,4 -> 2,0
        \\0,9 -> 2,9
        \\3,4 -> 1,4
        \\0,0 -> 8,8
        \\5,5 -> 8,2
    ;

    var fbs = fixedBufferStream(input);
    var lines = try parse(fbs.reader());
    defer lines.deinit();
    std.debug.print("num_lines: {}\n", .{lines.items.len});

    var sum = try calc_overlap(lines.items, false);
    std.debug.print("sample 1: {}\n", .{sum});

    var sum2 = try calc_overlap(lines.items, true);
    std.debug.print("sample 2: {}\n", .{sum2});
}

test "part 1" {
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var lines = try parse(file.reader());
    defer lines.deinit();

    var sum = try calc_overlap(lines.items, false);
    std.debug.print("part 1: {}\n", .{sum});
    var sum2 = try calc_overlap(lines.items, true);
    std.debug.print("part 2: {}\n", .{sum2});
    //std.debug.print("sample 1: {}\n", .{sum});
}
