const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const BufMap = std.BufMap;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

pub fn parse(buffer: []const u8) !StringHashMap(ArrayList([]const u8)) {
    var map = StringHashMap(ArrayList([]const u8)).init(test_allocator);
    var row_it = std.mem.split(buffer, "\n");
    while (row_it.next()) |raw_row| {
        var entry_it = std.mem.split(raw_row, "-");
        var lhs: []const u8 = entry_it.next().?;
        var rhs: []const u8 = entry_it.next().?;

        //        std.debug.print("------------------------\n", .{});
        //       std.debug.print("Raw_lhs: {s}\n", .{lhs});
        //      std.debug.print("Raw_rhs: {s}\n", .{rhs});

        if (!map.contains(lhs)) {
            try map.put(lhs, ArrayList([]const u8).init(test_allocator));
        }
        if (!map.contains(rhs)) {
            try map.put(rhs, ArrayList([]const u8).init(test_allocator));
        }

        // std.debug.print("lhs_arr: {any}\n", .{map.get(lhs).?});
        //std.debug.print("lhs_arr: {any}\n", .{map.get(rhs).?});
        //     std.debug.print("pre-append: lhs: {s} : {any} \n", .{ lhs, map.get(lhs).?.items });
        //     std.debug.print("pre-append: rhs: {s} : {any} \n", .{ rhs, map.get(rhs).?.items });
        try map.getPtr(lhs).?.append(rhs);
        try map.getPtr(rhs).?.append(lhs);
        //    std.debug.print("lhs: {s} : {any} \n", .{ lhs, map.get(lhs).?.items });
        //   std.debug.print("rhs: {s} : {any} \n", .{ rhs, map.get(rhs).?.items });

    }

    return map;
}

pub fn isLowercase(str: []const u8) bool {
    for (str) |byte| {
        if (byte >= 'A' and byte <= 'Z') {
            return false;
        }
    }
    return true;
}

pub fn explore(caves: StringHashMap(ArrayList([]const u8)), cur_path: *ArrayList([]const u8)) AllocationError!usize {

    // if at "end" print out path, then pop() and return
    if (std.mem.eql(u8, cur_path.items[cur_path.items.len - 1], "end")) {
        return 1;
    }

    var complete_paths: usize = 0;
    var last: []const u8 = cur_path.items[cur_path.items.len - 1];
    outer: for (caves.get(last).?.items) |neighbor| {
        std.debug.print("visiting: {s}\n", .{neighbor});
        // don't visit lowercase twice
        if (isLowercase(neighbor)) {
            for (cur_path.items) |item| {
                if (std.mem.eql(u8, item, neighbor)) {
                    continue :outer;
                }
            }
        }
        try cur_path.append(neighbor);
        complete_paths += try explore(caves, cur_path);
        _ = cur_path.pop();
    }

    // for each connected cave in caves.get(cur)
    // if lowercase and cur_path contains it already skip
    // explore(connected)
    // pop()
    //
    // shouldn't need to worry about freeing path strings because they are tied to buffer
    // still need to deinit ArrayList from main

    return complete_paths;
}

const AllocationError = error{
    OutOfMemory,
};

test "sample 1" {
    std.debug.print("\n", .{});
    const input =
        \\start-A
        \\start-b
        \\A-c
        \\A-b
        \\b-d
        \\A-end
        \\b-end
    ;
    var fbs = std.io.fixedBufferStream(input);
    var buf = try fbs.reader().readAllAlloc(test_allocator, 999999);
    defer test_allocator.free(buf);
    var trimmed = std.mem.trim(u8, buf, "\n"); // file trailing newline

    var m = try parse(trimmed);
    defer {
        var it = m.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.*.deinit();
        }
        m.deinit();
    }

    var map_it = m.iterator();
    while (map_it.next()) |entry| {
        std.debug.print("entry: {s}\n", .{entry.key_ptr.*});
        for (entry.value_ptr.*.items) |item| {
            std.debug.print("| {s}, ", .{item});
        }
        std.debug.print("\n", .{});
    }

    var cur_path = ArrayList([]const u8).init(test_allocator);
    defer cur_path.deinit();

    try cur_path.append("start");
    var num_paths = try explore(m, &cur_path);
    std.debug.print("sample 1: {}\n", .{num_paths});
}
