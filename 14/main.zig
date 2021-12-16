const std = @import("std");
const StringHashMap = std.StringHashMap;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

const Input = struct {
    template: []const u8,
    rules: StringHashMap(u8),
};

pub fn parse(buffer: []const u8) !Input {
    var rules = StringHashMap(u8).init(test_allocator);
    var section_it = std.mem.split(buffer, "\n\n");

    // first section is template
    var template = section_it.next().?;

    // remaining input is list of rules
    var line_it = std.mem.split(section_it.next().?, "\n");
    while (line_it.next()) |raw_line| {
        var rule_it = std.mem.split(raw_line, " -> ");
        var lhs = rule_it.next().?;
        var rhs = rule_it.next().?;
        try rules.put(lhs, rhs[0]);
    }

    return Input{ .template = template, .rules = rules };
}

pub fn expand(existing: *ArrayList(u8), rules: StringHashMap(u8)) !void {
    var arr = ArrayList(u8).init(test_allocator);
    defer arr.deinit();
    var idx: usize = 1;

    try arr.append(existing.items[0]);
    while (idx < existing.items.len) : (idx += 1) {
        if (rules.contains(existing.items[idx - 1 .. idx + 1])) {
            try arr.append(rules.get(existing.items[idx - 1 .. idx + 1]).?);
        }
        try arr.append(existing.items[idx]);
    }

    existing.clearRetainingCapacity();
    for (arr.items) |item| {
        try existing.append(item);
    }
}

pub fn efficient_calc(template: []const u8, reps: usize, rules: StringHashMap(u8)) !usize {
    var counts = StringHashMap(usize).init(test_allocator);
    defer counts.deinit();

    var rule_it = rules.iterator();
    while (rule_it.next()) |rule| {
        try counts.put(rule.key_ptr.*, 0);
    }

    const left_edge = template[0];
    const right_edge = template[template.len - 1];

    var idx: usize = 1;
    while (idx < template.len) : (idx += 1) {
        var key = template[idx - 1 .. idx + 1];
        try counts.put(key, counts.get(key).? + 1);
    }

    //

    var ctr: usize = 0;
    while (ctr < reps) : (ctr += 1) {
        // create copy of current values
        var counts_cpy = StringHashMap(usize).init(test_allocator);
        defer counts_cpy.deinit();
        var count_it = counts.iterator();
        while (count_it.next()) |entry| {
            try counts_cpy.put(entry.key_ptr.*, entry.value_ptr.*);
        }

        // iterate over previous values and update map
        var cpy_it = counts_cpy.iterator();
        while (cpy_it.next()) |copy| {
            const key = copy.key_ptr.*;
            const val = copy.value_ptr.*;

            // XY -= count XY
            // XZ += count XY
            // ZY += count ZY

            try counts.put(key, counts.get(key).? - val);
            const xz_key = [2]u8{ key[0], rules.get(key).? };
            const zy_key = [2]u8{ rules.get(key).?, key[1] };
            try counts.put(xz_key[0..], counts.get(xz_key[0..]).? + val);
            try counts.put(zy_key[0..], counts.get(zy_key[0..]).? + val);
        }

        count_it = counts.iterator();
        while (count_it.next()) |entry| {
            std.debug.print("after: {s} : {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
    }

    // counts. Sum all letters from all keys
    // subtract ends
    // divide everything else by 2 because it is double counted
    var sums = AutoHashMap(u8, usize).init(test_allocator);
    defer sums.deinit();
    var count_it = counts.iterator();
    while (count_it.next()) |entry| {
        const key = entry.key_ptr.*;
        const val = entry.value_ptr.*;

        var lhs = try sums.getOrPutValue(key[0], 0);
        var rhs = try sums.getOrPutValue(key[1], 0);
        lhs.value_ptr.* += val;
        rhs.value_ptr.* += val;
    }
    sums.getPtr(left_edge).?.* -= 1;
    sums.getPtr(right_edge).?.* -= 1;

    // divide each entry by 2
    var sums_it = sums.iterator();
    while (sums_it.next()) |entry| {
        if (entry.value_ptr.* % 2 != 0) {
            std.debug.print("WHYYYYY\n", .{});
        }
        entry.value_ptr.* = @divExact(entry.value_ptr.*, 2);
    }
    // re-add adges
    sums.getPtr(left_edge).?.* += 1;
    sums.getPtr(right_edge).?.* += 1;

    sums_it = sums.iterator();
    var min: usize = 999999999999;
    var max: usize = 0;
    while (sums_it.next()) |entry| {
        min = std.math.min(min, entry.value_ptr.*);
        max = std.math.max(max, entry.value_ptr.*);
        std.debug.print("count: {c} : {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    return max - min;
}

// NNCB    || N: 2 C: 1 B: 1
// NN NC CB || NN: 1 NC: 1: CB: 1 Left: N Right: B
// 3N + 2C + B  subtract edges
// 2N + 2C . Div by 2
// 1N + 1C + 1N + B
//
// want: 2n 2c 2b 1h

// NC CN NB BC CH HB
// NBCCNBBBCBHCB
// NB BC CC CN NB BB BB BC CB BH HC CB

pub fn calc(str: []const u8) !void {
    const buf = try test_allocator.alloc(usize, 256);
    std.mem.set(usize, buf, 0);
    defer test_allocator.free(buf);

    for (str) |byte| {
        buf[byte] += 1;
    }

    var min: usize = 99999999999;
    var max: usize = 0;
    var max_idx: usize = 0;
    var min_idx: usize = 0;
    for (buf) |byte_count, idx| {
        max = std.math.max(max, byte_count);
        max_idx = idx;
        if (byte_count > 0) {
            min = std.math.min(min, byte_count);
            min_idx = idx;
        }
    }

    std.debug.print("res: {}\n", .{max - min});
}

test "sample 1" {
    std.debug.print("\n", .{});
    const input =
        \\NNCB
        \\
        \\CH -> B
        \\HH -> N
        \\CB -> H
        \\NH -> C
        \\HB -> C
        \\HC -> B
        \\HN -> C
        \\NN -> C
        \\BH -> H
        \\NC -> B
        \\NB -> B
        \\BN -> B
        \\BB -> N
        \\BC -> B
        \\CC -> N
        \\CN -> C
    ;
    var fbs = std.io.fixedBufferStream(input);
    var buf = try fbs.reader().readAllAlloc(test_allocator, 999999);
    defer test_allocator.free(buf);
    var trimmed = std.mem.trim(u8, buf, "\n"); // file trailing newline

    var in = try parse(trimmed);
    defer in.rules.deinit();

    var rule_it = in.rules.iterator();
    while (rule_it.next()) |entry| {
        std.debug.print("rule: {s} : {c}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    var template = ArrayList(u8).init(test_allocator);
    defer template.deinit();
    try template.appendSlice(in.template);

    var done = try efficient_calc(template.items, 40, in.rules);
    std.debug.print("sample 2: {}\n", .{done});

    //var ctr: usize = 0;
    //while (ctr < 10) : (ctr += 1) {
    //try expand(&template, in.rules);
    //std.debug.print("res: {s}\n", .{template.items});
    //}
    //try calc(template.items);
}

test "part 1" {
    std.debug.print("\n", .{});
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var buf = try file.reader().readAllAlloc(test_allocator, 999999);
    defer test_allocator.free(buf);
    var trimmed = std.mem.trim(u8, buf, "\n"); // file trailing newline

    var in = try parse(trimmed);
    defer in.rules.deinit();

    var rule_it = in.rules.iterator();
    while (rule_it.next()) |entry| {
        // std.debug.print("rule: {s} : {c}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    var template = ArrayList(u8).init(test_allocator);
    defer template.deinit();
    try template.appendSlice(in.template);

    _ = try efficient_calc(template.items, 1, in.rules);

    //   var ctr: usize = 0;
    //while (ctr < 40) : (ctr += 1) {
    //std.debug.print("{}\n", .{ctr});
    //std.debug.print("{}\n", .{template.items.len});
    //try expand(&template, in.rules);
    //// std.debug.print("res: {s}\n", .{template.items});
    //}
    //   try calc(template.items);
}
