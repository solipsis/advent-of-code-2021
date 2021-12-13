pub fn parse(buffer: []const u8) !StringHashMap(*ArrayList([]const u8)) {
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
        // Add to eachothers lists
        try map.get(lhs).?.*.append(rhs);
        try map.get(rhs).?.*.append(lhs);

        std.debug.print("lhs: key {s} : {*}\n", .{ lhs, map.get(lhs).? });
        std.debug.print("rhs: key {s} : {*}\n", .{ rhs, map.get(rhs).? });
    }
    return map;
}
