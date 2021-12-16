const std = @import("std");
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

const Grid = struct {
    width: usize,
    risk: ArrayList(usize),
};

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

const INF = 999999999;

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

    //   for (initial_cost) |val, idx| {
    //std.debug.print("{},", .{val});
    //if ((idx + 1) % grid.width == 0) {
    //std.debug.print("\n", .{});
    //}
    //   }
}
