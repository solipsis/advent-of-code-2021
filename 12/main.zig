const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const BufMap = std.BufMap;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

pub fn parse(buffer: []const u8) !StringHashMap(ArrayList([]const u8)) {
    //var list = ArrayList(ArrayList([]const u8).init(test_allocator);

    var map = StringHashMap(ArrayList([]const u8)).init(test_allocator);
    var row_it = std.mem.split(buffer, "\n");
    while (row_it.next()) |raw_row| {
        var entry_it = std.mem.split(raw_row, "-");
        var lhs: []const u8 = try map.allocator.dupe(u8, entry_it.next().?);
        var rhs: []const u8 = try map.allocator.dupe(u8, entry_it.next().?);

        std.debug.print("------------------------\n", .{});
        std.debug.print("Raw_lhs: {s}\n", .{lhs});
        std.debug.print("Raw_rhs: {s}\n", .{rhs});

        if (!map.contains(lhs)) {
            try map.put(lhs, ArrayList([]const u8).init(test_allocator));
        }
        if (!map.contains(rhs)) {
            try map.put(rhs, ArrayList([]const u8).init(test_allocator));
        }

        // std.debug.print("lhs_arr: {any}\n", .{map.get(lhs).?});
        //std.debug.print("lhs_arr: {any}\n", .{map.get(rhs).?});
        std.debug.print("pre-append: lhs: {s} : {any} \n", .{ lhs, map.get(lhs).?.items });
        std.debug.print("pre-append: rhs: {s} : {any} \n", .{ rhs, map.get(rhs).?.items });
        try map.getPtr(lhs).?.append(rhs);
        try map.getPtr(rhs).?.append(lhs);
        std.debug.print("lhs: {s} : {any} \n", .{ lhs, map.get(lhs).?.items });
        std.debug.print("rhs: {s} : {any} \n", .{ rhs, map.get(rhs).?.items });

        //  std.debug.print("lhs: {s}, rhs: {s}\n", .{ lhs, rhs });
        //  std.debug.print("lhs2: {}, rhs2: {}\n", .{ map.get(lhs).?.items.len, map.get(rhs).?.items.len });
        //        map.put(lhs:
    }

    var map_it = map.iterator();
    //while (map_it.next()) |entry| {
    //   std.debug.print("entry: {s}\n", .{entry.key_ptr.*});
    //  std.debug.print("blah: {any}\n", .{entry.value_ptr.*});
    //  for (entry.value_ptr.*.*.items) |item| {
    //     std.debug.print("| {any}, ", .{item});
    // }
    // std.debug.print("\n", .{});
    //std.debug.print("entry: {s}, {any}\n", .{ entry.key_ptr.*, entry.value_ptr.*.items });
    //  entry.value_ptr.deinit();
    //}

    return map;
}

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
    defer m.deinit();

    var map_it = m.iterator();
    while (map_it.next()) |entry| {
        std.debug.print("entry: {s}\n", .{entry.key_ptr.*});
        // std.debug.print("val: {any}\n", .{entry.value_ptr.*});
        for (entry.value_ptr.*.items) |item| {
            std.debug.print("| {s}, ", .{item});
        }
        std.debug.print("\n", .{});
    }
    //std.debug.print("entry: {s}, {any}\n", .{ entry.key_ptr.*, entry.value_ptr.*.items });
    //  entry.value_ptr.deinit();
    //  }

    // for (map.entries) {

    //}
}

pub fn parse2(buffer: []const u8) !StringHashMap(*ArrayList([]const u8)) {
    var map = StringHashMap(*ArrayList([]const u8)).init(test_allocator);
    var row_it = std.mem.split(buffer, "\n");
    while (row_it.next()) |raw_row| {
        var entry_it = std.mem.split(raw_row, "-");
        var lhs: []const u8 = try map.allocator.dupe(u8, entry_it.next().?);
        var rhs: []const u8 = try map.allocator.dupe(u8, entry_it.next().?);

        // allocate new list for key if it is a new key
        if (!map.contains(lhs)) {
            var new_arr = ArrayList([]const u8).init(test_allocator);
            try map.put(lhs, &new_arr);
        }
        if (!map.contains(rhs)) {
            var new_arr = ArrayList([]const u8).init(test_allocator);
            try map.put(rhs, &new_arr);
        }
        try map.get(lhs).?.*.append(rhs);
        try map.get(rhs).?.*.append(lhs);

        std.debug.print("lhs: key: {s}  {*}\n", .{ lhs, map.get(lhs).? });
        std.debug.print("rhs: key: {s}  {*}\n", .{ rhs, map.get(rhs).? });
    }
    return map;
}
