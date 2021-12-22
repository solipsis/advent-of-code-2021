const std = @import("std");
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const Point = struct {
    x: isize,
    y: isize,
};

const Grid = struct {
    enhance: []const u8,
    grid: AutoHashMap(Point, bool),
};

pub fn enhance(grid: *Grid, assume_unknown: bool, allocator: *Allocator) !void {
    var to_add = ArrayList(Point).init(allocator);
    //var to_remove = ArrayList(Point).init(allocator);

    //std.debug.print("Priint Points 2222\n------------------------\n", .{});
    //printPoints(grid.*);

    //std.debug.print("Priint Points 33333\n------------------------\n", .{});
    //var dave_it = grid.grid.keyIterator();
    //while (dave_it.next()) |k| {
    //    std.debug.print("{any}\n", .{k});
    // }

    var key_it = grid.grid.keyIterator();
    // Add all adjacent points
    while (key_it.next()) |p| {
        //    std.debug.print("adjacent: {any}\n", .{p.*});
        var x_mod: isize = -1;
        while (x_mod <= 1) : (x_mod += 1) {
            var y_mod: isize = -1;
            while (y_mod <= 1) : (y_mod += 1) {
                //if (!grid.grid.contains(Point{ .x = p.x + x_mod, .y = p.y + y_mod })) {
                //           std.debug.print("x: {}, y: {}, x+: {}, y+: {}\n", .{ p.x, p.y, p.x + x_mod, p.y + y_mod });
                var blah = Point{ .x = p.x + x_mod, .y = p.y + y_mod };
                //          std.debug.print("blah: {any}\n", .{blah});
                //            _ = try grid.grid.getOrPutValue(blah, false);
                // grid.grid.put(
                if (!grid.grid.contains(blah)) {
                    std.debug.print("adding: {any}\n", .{blah});
                    try to_add.append(blah);
                }
            }
        }
    }
    for (to_add.items) |item| {
        try grid.grid.put(item, false);
    }

    // NEED TO MAKE COPY BEFORE MODIFYING....
    std.debug.print("ADD Count: {}\n", .{grid.grid.count()});

    var prev_state = try grid.grid.clone();

    key_it = prev_state.keyIterator();
    while (key_it.next()) |point| {
        // std.debug.print("x: {}, y: {}\n", .{ point.x, point.y });
        // above
        var above = [3]u8{ '0', '0', '0' };
        if (prev_state.get(Point{ .x = point.x - 1, .y = point.y - 1 })) |light| {
            if (light) {
                above[0] = '1';
            }
        } else {
            if (assume_unknown) {
                above[0] = '1';
            }
        }
        if (prev_state.get(Point{ .x = point.x, .y = point.y - 1 })) |light| {
            if (light) {
                above[1] = '1';
            }
        }
        if (prev_state.get(Point{ .x = point.x + 1, .y = point.y - 1 })) |light| {
            if (light) {
                above[2] = '1';
            }
        }

        // middle
        var middle = [3]u8{ '0', '0', '0' };
        if (prev_state.get(Point{ .x = point.x - 1, .y = point.y })) |light| {
            if (light) {
                middle[0] = '1';
            }
        }
        if (prev_state.get(Point{ .x = point.x, .y = point.y })) |light| {
            if (light) {
                middle[1] = '1';
            }
        }
        if (prev_state.get(Point{ .x = point.x + 1, .y = point.y })) |light| {
            if (light) {
                middle[2] = '1';
            }
        }

        // below
        var below = [3]u8{ '0', '0', '0' };
        if (prev_state.get(Point{ .x = point.x - 1, .y = point.y + 1 })) |light| {
            if (light) {
                below[0] = '1';
            }
        }
        if (prev_state.get(Point{ .x = point.x, .y = point.y + 1 })) |light| {
            if (light) {
                below[1] = '1';
            }
        }
        if (prev_state.get(Point{ .x = point.x + 1, .y = point.y + 1 })) |light| {
            if (light) {
                below[2] = '1';
            }
        }

        var num_buf = [9]u8{ '0', '0', '0', '0', '0', '0', '0', '0', '0' };
        var idx: usize = 0;
        while (idx < 3) : (idx += 1) {
            num_buf[idx] = above[idx];
        }
        while (idx < 6) : (idx += 1) {
            num_buf[idx] = middle[idx % 3];
        }
        while (idx < 9) : (idx += 1) {
            num_buf[idx] = below[idx % 3];
        }

        var enhance_id = try std.fmt.parseUnsigned(usize, num_buf[0..], 2);
        //std.debug.print("{s}\n", .{num_buf[0..]});
        std.debug.print("enhance: {}, alg: {c}\n", .{ enhance_id, grid.enhance[enhance_id] });
        if (grid.enhance[enhance_id] == '#') {
            try grid.grid.put(point.*, true);
        } else {
            std.debug.print("False Point: x: {}, y: {}\n", .{ point.x, point.y });
            try grid.grid.put(point.*, false);
        }
    }
}

pub fn debug(grid: Grid) void {
    var y: isize = -3;
    while (y < 10) : (y += 1) {
        var x: isize = -3;
        while (x < 10) : (x += 1) {
            var p = Point{ .x = x, .y = y };
            if (grid.grid.contains(p) and grid.grid.get(p).?) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

pub fn printPoints(grid: Grid) void {
    var key_it = grid.grid.keyIterator();
    while (key_it.next()) |k| {
        std.debug.print("{any}\n", .{k});
    }
}

pub fn trueCount(grid: Grid) usize {
    var sum: usize = 0;
    var point_it = grid.grid.iterator();
    while (point_it.next()) |p| {
        if (p.value_ptr.*) {
            sum += 1;
        }
    }
    return sum;
}

pub fn parse(buffer: []const u8, allocator: *Allocator) !Grid {
    var section_it = std.mem.split(buffer, "\n\n");

    var point_map = AutoHashMap(Point, bool).init(allocator);

    // first segment is enhancement string
    var enhancement_algo = section_it.next().?;

    var image_line_it = std.mem.split(section_it.next().?, "\n");
    var y_idx: isize = 0;
    while (image_line_it.next()) |line| {
        for (line) |byte, x_idx| {
            if (byte == '#') {
                var p = Point{ .x = @intCast(isize, x_idx), .y = @intCast(isize, y_idx) };
                std.debug.print("{any}\n", .{p});
                try point_map.put(p, true);
            } else {
                var p = Point{ .x = @intCast(isize, x_idx), .y = @intCast(isize, y_idx) };
                //try point_map.put(p, false);
            }
        }
        y_idx += 1;
    }

    return Grid{
        .enhance = enhancement_algo,
        .grid = point_map,
    };
}

test "part 1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = std.mem.trim(u8, @embedFile("./input.txt"), "\n");
    var grid = try parse(input, &arena.allocator);
    try enhance(&grid, &arena.allocator);
    try enhance(&grid, &arena.allocator);
    std.debug.print("true count: {}\n", .{trueCount(grid)});
    // 5938 too high
}

test "sample" {
    std.debug.print("\n", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input =
        \\..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..###..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#..#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#......#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#.....####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.......##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#
        \\
        \\#..#.
        \\#....
        \\##..#
        \\..#..
        \\..###
    ;

    var grid = try parse(input, &arena.allocator);
    std.debug.print("algo len: {}\n", .{grid.enhance.len});
    std.debug.print("point count: {}\n", .{grid.grid.count()});
    std.debug.print("true count: {}\n", .{trueCount(grid)});

    //   std.debug.print("Priint Points\n------------------------\n", .{});
    //  printPoints(grid);

    debug(grid);
    try enhance(&grid, &arena.allocator);
    debug(grid);
    std.debug.print("true count: {}\n", .{trueCount(grid)});
    std.debug.print("point count: {}\n", .{grid.grid.count()});
    try enhance(&grid, &arena.allocator);
    debug(grid);
    std.debug.print("point count: {}\n", .{grid.grid.count()});
    std.debug.print("true count: {}\n", .{trueCount(grid)});
    //  try enhance(&grid, &arena.allocator);
    //  std.debug.print("point count: {}\n", .{grid.grid.count()});
    //  std.debug.print("true count: {}\n", .{trueCount(grid)});
}
