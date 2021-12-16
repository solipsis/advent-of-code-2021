const std = @import("std");
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

const Grid = struct {
    width: usize,
    risk: ArrayList(usize),
};

const INF = 999999999;

pub fn hyper_grid(orig: Grid) !Grid {
    var hyper_buf = try test_allocator.alloc(usize, orig.risk.items.len * 25);
    std.mem.set(usize, hyper_buf, 0);
    defer test_allocator.free(hyper_buf);

    var hyper_width = orig.width * 5;

    //var col_offset: usize = 0;
    //var row_offset: usize = 0;

    var hyper_row: usize = 0;
    while (hyper_row < 5) : (hyper_row += 1) {
        var hyper_col: usize = 0;
        while (hyper_col < 5) : (hyper_col += 1) {
            for (orig.risk.items) |item, idx| {
                var sub_col: usize = idx % orig.width;
                var sub_row: usize = @divFloor(idx, orig.width);

                var hyper_row_offset = hyper_row * hyper_width * (orig.risk.items.len / orig.width);
                var hyper_col_offset = hyper_col * orig.width;
                var hyper_idx = hyper_row_offset + hyper_col_offset + (sub_row * hyper_width) + sub_col;
                //std.debug.print("orig: {}, h_row: {}, h_col: {}\n", .{ orig.risk.items[idx], hyper_row, hyper_col });
                //std.debug.print("add: {}, mod: {}\n", .{ orig.risk.items[idx] + hyper_row + hyper_col, (orig.risk.items[idx] + hyper_row + hyper_col) % 9 });
                var adjusted_val = (orig.risk.items[idx] + hyper_row + hyper_col);
                if (adjusted_val > 9) {
                    adjusted_val -= 9;
                }
                //if (adjusted_val == 0) {
                //adjusted_val = 1;
                //}
                hyper_buf[hyper_idx] = adjusted_val;
            }
        }
    }

    var hyper_arr = ArrayList(usize).init(test_allocator);
    try hyper_arr.appendSlice(hyper_buf);

    return Grid{ .width = hyper_width, .risk = hyper_arr };
}

pub fn update(risk: []usize, width: usize, cost: []usize, idx: usize) void {
    // create cost grid same size as risk // TODO: initialize outside of this
    // initialize all vals to inifity except top left to 0

    const prev_cost = cost[idx];

    // special case for initial value
    if (idx == 0) {
        cost[idx] = 0;
    }

    // update costs to reach this cell from adjacent
    var row = @divFloor(idx, width);
    var col = idx % width;
    if (row >= 1) { // above
        cost[idx] = std.math.min(cost[idx], cost[idx - width] + risk[idx]);
    }
    if (row != (risk.len / width) - 1) { //below
        cost[idx] = std.math.min(cost[idx], cost[idx + width] + risk[idx]);
    }
    if (col > 0) { // left
        cost[idx] = std.math.min(cost[idx], cost[idx - 1] + risk[idx]);
    }
    if (col != width - 1) { // right
        cost[idx] = std.math.min(cost[idx], cost[idx + 1] + risk[idx]);
    }

    // if the cost of this cell changed, update all adjacent
    if (cost[idx] != prev_cost) {
        if (row >= 1) { // above
            update(risk, width, cost, idx - width);
        }
        if (row != (risk.len / width) - 1) { //below
            update(risk, width, cost, idx + width);
        }
        if (col > 0) { // left
            update(risk, width, cost, idx - 1);
        }
        if (col != width - 1) { // right
            update(risk, width, cost, idx + 1);
        }
    }
}

test "part 1" {
    std.debug.print("\n", .{});
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var grid = try parse(file.reader());
    defer grid.risk.deinit();

    var initial_cost = try test_allocator.alloc(usize, grid.risk.items.len);
    defer test_allocator.free(initial_cost);
    std.mem.set(usize, initial_cost, INF);

    update(grid.risk.items, grid.width, initial_cost, 0);
    std.debug.print("Part 1: {}\n", .{initial_cost[initial_cost.len - 1]});

    var hyper = try hyper_grid(grid);
    defer hyper.risk.deinit();

    var hyper_initial_cost = try test_allocator.alloc(usize, hyper.risk.items.len);
    defer test_allocator.free(hyper_initial_cost);
    std.mem.set(usize, hyper_initial_cost, INF);

    //update(hyper.risk.items, hyper.width, hyper_initial_cost, 0);
    //std.debug.print("Part 2: {}\n", .{hyper_initial_cost[hyper_initial_cost.len - 1]});
}

test "sample 1" {
    std.debug.print("\n", .{});
    const input =
        \\1163751742
        \\1381373672
        \\2136511328
        \\3694931569
        \\7463417111
        \\1319128137
        \\1359912421
        \\3125421639
        \\1293138521
        \\2311944581
    ;
    var fbs = std.io.fixedBufferStream(input);

    var grid = try parse(fbs.reader());
    defer grid.risk.deinit();

    var initial_cost = try test_allocator.alloc(usize, grid.risk.items.len);
    defer test_allocator.free(initial_cost);
    std.mem.set(usize, initial_cost, INF);

    //   for (grid.risk.items) |val, idx| {
    //std.debug.print("{}", .{val});
    //if ((idx + 1) % grid.width == 0) {
    //std.debug.print("\n", .{});
    //}
    //   }

    update(grid.risk.items, grid.width, initial_cost, 0);
    try expect(initial_cost[initial_cost.len - 1] == 40);
    std.debug.print("Sample 1: {}\n", .{initial_cost[initial_cost.len - 1]});

    var hyper = try hyper_grid(grid);
    defer hyper.risk.deinit();

    var hyper_initial_cost = try test_allocator.alloc(usize, hyper.risk.items.len);
    defer test_allocator.free(hyper_initial_cost);
    std.mem.set(usize, hyper_initial_cost, INF);

    for (hyper.risk.items) |val, idx| {
        std.debug.print("{}", .{val});
        if ((idx + 1) % hyper.width == 0) {
            //std.debug.print("idx: {}\n", .{idx});
            std.debug.print("\n", .{});
        }
    }
    //std.debug.print("\nsize: {}\n", .{hyper.risk.items.len});
    //std.debug.print("\nwidth: {}\n", .{hyper.width});

    update(hyper.risk.items, hyper.width, hyper_initial_cost, 0);
    std.debug.print("Sample 2: {}\n", .{hyper_initial_cost[hyper_initial_cost.len - 1]});

    //   for (initial_cost) |val, idx| {
    //std.debug.print("{},", .{val});
    //if ((idx + 1) % grid.width == 0) {
    //std.debug.print("\n", .{});
    //}
    //   }
}

pub fn parse(reader: anytype) !Grid {
    var buf = try reader.readAllAlloc(test_allocator, 999999);
    defer test_allocator.free(buf);
    var trimmed = std.mem.trim(u8, buf, "\n");

    var risk = ArrayList(usize).init(test_allocator);
    var width: usize = 0;

    var line_it = std.mem.split(trimmed, "\n");
    while (line_it.next()) |line| {
        width = line.len;
        for (line) |byte| {
            var i: usize = try std.fmt.charToDigit(byte, 10);
            try risk.append(i);
        }
    }

    return Grid{ .width = width, .risk = risk };
}
