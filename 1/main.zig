const std = @import("std");
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

pub fn fileToList(file: std.fs.File) !ArrayList(usize) {
    var list = ArrayList(usize).init(test_allocator);
    return list;
}

test "ftl" {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    var list = try fileToList(file);
}

test "read file" {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buf_stream = std.io.bufferedReader(file.reader());
    var in_stream = buf_stream.reader();
    var buf: [1024]u8 = undefined;

    var list = ArrayList(usize).init(test_allocator);
    defer list.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // std.debug.print("\ntest: {s}\n", .{line});
        var i = try std.fmt.parseUnsigned(usize, line, 10);
        // std.debug.print("\nint: {}\n", .{i});
        try list.append(i);
    }

    var prev = list.items[0];
    var incCount: usize = 0;
    for (list.items) |val| {
        if (val > prev) {
            incCount += 1;
        }
        prev = val;
        //std.debug.print("\nfor: {}\n", .{val});
    }
    std.debug.print("\nfinal: {}\n", .{incCount});
}

test "window" {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buf_stream = std.io.bufferedReader(file.reader());
    var in_stream = buf_stream.reader();
    var buf: [1024]u8 = undefined;

    var list = ArrayList(usize).init(test_allocator);
    defer list.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var i = try std.fmt.parseUnsigned(usize, line, 10);
        try list.append(i);
    }

    var prev = list.items[0] + list.items[1] + list.items[2];
    var incCount: usize = 0;
    var idx: usize = 3;
    while (idx < list.items.len) {
        var newWindow = list.items[idx] + list.items[idx - 1] + list.items[idx - 2];
        if (newWindow > prev) {
            incCount += 1;
        }
        prev = newWindow;
        // std.debug.print("\nfor: {}\n", .{prev});
        idx += 1;
    }
    std.debug.print("\nwindow: {}\n", .{incCount});
}
