const std = @import("std");
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

const Grid = struct {
    cells: ArrayList(isize),
    row_width: usize,
};

const LowPoint = struct {
    row: usize,
    col: usize,
    val: usize,
    idx: usize,
};

pub fn parse(reader: anytype) !Grid {
    var buf = try reader.readAllAlloc(test_allocator, 99999);
    defer test_allocator.free(buf);
    var trimmed = std.mem.trim(u8, buf, "\n"); // file trailing newline

    var row_width: usize = 0;
    var cells = ArrayList(isize).init(test_allocator);
    var row_it = std.mem.split(trimmed, "\n");
    while (row_it.next()) |raw_row| {
        if (row_width == 0) {
            row_width = raw_row.len;
        }

        for (raw_row) |num| {
            var i = try std.fmt.charToDigit(num, 10);
            try cells.append(i);
        }
    }

    const grid = Grid{
        .cells = cells,
        .row_width = row_width,
    };
    return grid;
}

pub fn calcRisk(points: []LowPoint) usize {
    var risk: usize = 0;
    for (points) |p| {
        risk += p.val + 1;
    }
    return risk;
}

fn cmpByValue(context: void, a: usize, b: usize) bool {
    return std.sort.asc(usize)(context, a, b);
}

pub fn largestBasin(grid: Grid, points: []LowPoint) !usize {
    var visit_buf = [_]bool{false} ** 10000;
    var visited = visit_buf[0..grid.cells.items.len];
    // for each low_point, visit and floodfill and check against current max
    var basins = ArrayList(usize).init(test_allocator);
    defer basins.deinit();

    for (points) |point| {
        const basin = visit(grid, point.idx, visited);
        try basins.append(basin);
    }

    std.sort.sort(usize, basins.items, {}, cmpByValue);
    std.debug.print("basins: {any}\n", .{basins.items});

    // multiply three largest
    return basins.items[basins.items.len - 1] * basins.items[basins.items.len - 2] * basins.items[basins.items.len - 3];
}

pub fn visit(grid: Grid, idx: usize, visited: []bool) usize {

    // visit adjacent if unvisited and value is 1 higher than this value, and not 9
    // Not 100% positive about the 1 higher rule but seems true from samples
    // Remember edgecase about Height 9
    // make sure visited is properly edited inplace
    //

    const row_width = grid.row_width;
    var row = @divFloor(idx, row_width);
    var col = idx % row_width;
    var items = grid.cells.items;
    var item = items[idx];
    var basin_size: usize = 1;

    // bail if this cell already visited
    if (visited[idx]) {
        return 0;
    }
    // height 9 never counts as basin
    if (item == 9) {
        return 0;
    }

    // mark node as visited
    visited[idx] = true;

    // above
    if (row >= 1) {
        var above_idx = idx - row_width;
        //if (items[above_idx] == item + 1) {
        basin_size += visit(grid, above_idx, visited);
        //}
    }
    // below
    if (row != (items.len / row_width) - 1) {
        var below_idx = idx + row_width;
        //  if (items[below_idx] == item + 1) {
        basin_size += visit(grid, below_idx, visited);
        // }
    }
    // left
    if (col > 0) {
        var left_idx = idx - 1;
        //if (items[left_idx] == item + 1) {
        basin_size += visit(grid, left_idx, visited);
        //}
    }
    // right
    if (col != row_width - 1) {
        var right_idx = idx + 1;
        //if (items[right_idx] == item + 1) {
        basin_size += visit(grid, right_idx, visited);
        //}
    }

    return basin_size;
}

pub fn calcLowPoints(grid: Grid) !ArrayList(LowPoint) {
    const items = grid.cells.items;
    const row_width = grid.row_width;
    var low_points = ArrayList(LowPoint).init(test_allocator);

    var risk: usize = 0;
    var low_count: usize = 0;
    var idx: usize = 0;
    while (idx < items.len) : (idx += 1) {
        var row = @divFloor(idx, grid.row_width);
        var col = idx % grid.row_width;
        var item = items[idx];

        var num_adjacent: usize = 0;

        var is_low = true;
        // above
        if (row >= 1) {
            num_adjacent += 1;
            if (item >= items[idx - row_width]) {
                is_low = false;
            }
        }
        // below
        if (row != (items.len / row_width) - 1) {
            num_adjacent += 1;
            if (item >= items[idx + row_width]) {
                is_low = false;
            }
        }
        // left
        if (col > 0) {
            num_adjacent += 1;
            if (item >= items[idx - 1]) {
                is_low = false;
            }
        }
        // right
        if (col != row_width - 1) {
            num_adjacent += 1;
            if (item >= items[idx + 1]) {
                is_low = false;
            }
        }
        //std.debug.print("row: {}, col: {}, num_adjacent: {}\n", .{ row, col, num_adjacent });
        if (is_low) {
            //std.debug.print("LOW ----- row: {}, col: {}, val: {}\n", .{ row, col, item });
            low_count += 1;
            risk += @intCast(usize, item) + 1;

            try low_points.append(LowPoint{ .row = row, .col = col, .val = @intCast(usize, item), .idx = idx });
        }
    }

    return low_points;
}

test "sample 1" {
    const input =
        \\2199943210
        \\3987894921
        \\9856789892
        \\8767896789
        \\9899965678
    ;
    var fbs = std.io.fixedBufferStream(input);

    var grid = try parse(fbs.reader());
    defer grid.cells.deinit();
    std.debug.print("\nrow_width: {}\n", .{grid.row_width});

    var row: usize = 0;
    while (row * grid.row_width < grid.cells.items.len) : (row += 1) {
        std.debug.print("{any}\n", .{grid.cells.items[row * grid.row_width .. (row + 1) * grid.row_width]});
    }

    var low_points = try calcLowPoints(grid);
    defer low_points.deinit();

    std.debug.print("Sample 1: {}\n", .{calcRisk(low_points.items)});
    std.debug.print("Sample 2: {}\n", .{largestBasin(grid, low_points.items)});
}

test "part 1" {
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var grid = try parse(file.reader());
    defer grid.cells.deinit();
    std.debug.print("\nrow_width: {}\n", .{grid.row_width});

    var low_points = try calcLowPoints(grid);
    defer low_points.deinit();

    const risk = calcRisk(low_points.items);
    std.debug.print("Part 1: {}\n", .{risk});
    std.debug.print("Part 2: {}\n", .{largestBasin(grid, low_points.items)});
}
