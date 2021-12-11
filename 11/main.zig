const std = @import("std");
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

const Grid = struct {
    cells: ArrayList(isize),
    row_width: usize,
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

pub fn step(grid: Grid) usize {
    var octos = grid.cells.items;
    var activated = [_]bool{false} ** 100;

    // increase energy level of all by 1
    for (octos) |octo, idx| {
        octos[idx] += 1;
    }

    var new_flashes: bool = true;
    var num_flashes: usize = 0;
    while (new_flashes) {
        new_flashes = false;
        for (octos) |octo, idx| {
            if (activated[idx]) {
                continue;
            }

            var row = @divFloor(idx, grid.row_width);
            var col = idx % grid.row_width;
            if (octos[idx] > 9) {
                num_flashes += 1;
                // Flash
                activated[idx] = true;
                new_flashes = true;

                // above
                if (row >= 1) {
                    //left
                    if (col > 0) {
                        octos[idx - grid.row_width - 1] += 1;
                    }
                    //center
                    octos[idx - grid.row_width] += 1;
                    //right
                    if (col != grid.row_width - 1) {
                        octos[idx - grid.row_width + 1] += 1;
                    }
                }
                // center
                if (col > 0) {
                    octos[idx - 1] += 1;
                }
                if (col != grid.row_width - 1) {
                    octos[idx + 1] += 1;
                }

                // below
                if (row != (octos.len / grid.row_width) - 1) {
                    //left
                    if (col > 0) {
                        octos[idx + grid.row_width - 1] += 1;
                    }
                    //center
                    octos[idx + grid.row_width] += 1;
                    //right
                    if (col != grid.row_width - 1) {
                        octos[idx + grid.row_width + 1] += 1;
                    }
                }
            }
        }
    }

    // set all flashed ones to 0
    for (octos) |octo, idx| {
        if (activated[idx]) {
            octos[idx] = 0;
        }
    }

    var ctr: usize = 0;

    //    std.debug.print("--------------------\n", .{});
    while (ctr < 10) : (ctr += 1) {
        for (octos[ctr * 10 .. (ctr + 1) * 10]) |octo| {
            //           std.debug.print("{}", .{octo});
        }
        //       std.debug.print("\n", .{});
    }

    return num_flashes;
}

test "sample 1" {
    const input =
        \\5483143223
        \\2745854711
        \\5264556173
        \\6141336146
        \\6357385478
        \\4167524645
        \\2176841721
        \\6882881134
        \\4846848554
        \\5283751526
    ;
    var fbs = std.io.fixedBufferStream(input);
    var grid = try parse(fbs.reader());
    defer grid.cells.deinit();
    var num_flashes: usize = 0;

    var ctr: usize = 0;
    while (ctr < 100) : (ctr += 1) {
        num_flashes += step(grid);
    }
    std.debug.print("{}\n", .{num_flashes});
}

test "part 1" {
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var grid = try parse(file.reader());
    defer grid.cells.deinit();
    var num_flashes: usize = 0;

    var ctr: usize = 0;
    while (ctr < 100) : (ctr += 1) {
        const flashes: usize = step(grid);
        if (flashes == 100) {
            std.debug.print("Part 2 Early: {}\n", .{ctr});
        }
        num_flashes += flashes;
    }
    std.debug.print("{}\n", .{num_flashes});

    // 2211

    // 211 too high
    while (true) : (ctr += 1) {
        std.debug.print("{}\n", .{ctr});

        if (step(grid) == 100) {
            break;
        }
    }
    std.debug.print("Part 2: {}\n", .{ctr + 1}); // add one for zero base
}
