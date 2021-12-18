const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

const Entry = struct {
    digits: ArrayList([]const u8),
    display: ArrayList([]const u8),
};

pub fn charToMask(char: u8) u7 {
    var mask: u7 = switch (char) {
        'a' => 0b0000001,
        'b' => 0b0000010,
        'c' => 0b0000100,
        'd' => 0b0001000,
        'e' => 0b0010000,
        'f' => 0b0100000,
        'g' => 0b1000000,
        else => unreachable,
    };

    return mask;
}

test "mask" {
    //std.debug.print("\nmask: {}\n", .{charToMask('a')});
    //std.debug.print("\nmask: {}\n", .{charToMask('b')});
    //std.debug.print("\nmask: {}\n", .{charToMask('c')});
    //std.debug.print("\nmask: {}\n", .{charToMask('d')});
    //std.debug.print("\nmask: {}\n", .{charToMask('e')});
    //std.debug.print("\nmask: {}\n", .{charToMask('f')});
    //std.debug.print("\nmask: {}\n", .{charToMask('g')});
}

//pub fn parse(reader: anytype) !ArrayList(Entry) {
//var count: usize = 0;

//var buf = try reader.readAllAlloc(test_allocator, 99999);
//defer test_allocator.free(buf);
//var trimmed = std.mem.trim(u8, buf, "\n"); // trailing newline

//var entries = ArrayList(Entry).init(test_allocator);

//var line_iter = std.mem.split(trimmed, "\n");
//while (line_iter.next()) |line| {
////     std.debug.print("LINE: {s}XXX\n", .{line});

//var digits = [_]u7{0} ** 10;
//var display = [_]u7{0} ** 4;
//var entry = try entries.addOne();

//// split in half
//var segment_iter = std.mem.split(line, " | ");

//var digit_raw = segment_iter.next().?;
//var digit_iter = std.mem.split(digit_raw, " ");
//var idx: usize = 0;
//while (digit_iter.next()) |digit| {
//// std.mem.copy(u8, entry.digits[idx][0..], digit);
////digits[idx] = digit[0..];
//idx += 1;
//}

//var display_raw = segment_iter.next().?;
//var display_iter = std.mem.split(display_raw, " ");
//idx = 0;
//while (display_iter.next()) |digit| {
////std.debug.print("digit: {s}X\n", .{digit});
//var mask: u7 = 0;
//for (digit) |byte| {
////std.debug.print("byte: {}\n", .{byte});
//mask |= charToMask(byte);
//}
//const pc = @popCount(u7, mask);
//if (pc == 2 or pc == 3 or pc == 4 or pc == 7) {
//count += 1;
//}

//idx += 1;
//}

////        for (entries.items[0].digits) |digit| {
////std.debug.print("digit: {s}\n", .{digit});
////        }
//}

//std.debug.print("popcount: {}\n", .{count});

////  for (entries.items[0].digits) |digit| {
////std.debug.print("digit2: {s}\n", .{digit});
////  }
//return entries;
//}

pub fn parse(buffer: []const u8) !ArrayList(Entry) {
    var entries = ArrayList(Entry).init(test_allocator);

    var trimmed = std.mem.trim(u8, buffer, "\n"); // trailing newline

    var line_iter = std.mem.split(trimmed, "\n");
    while (line_iter.next()) |line| {
        var digits = ArrayList([]const u8).init(test_allocator);
        var display = ArrayList([]const u8).init(test_allocator);

        //split in half
        var segment_iter = std.mem.split(line, " | ");

        var digit_iter = std.mem.split(segment_iter.next().?, " ");
        while (digit_iter.next()) |digit| {
            try digits.append(digit);
        }

        var display_iter = std.mem.split(segment_iter.next().?, " ");
        while (display_iter.next()) |raw| {
            try display.append(raw);
        }

        try entries.append(Entry{ .digits = digits, .display = display });
    }

    return entries;
}

test "part 1" {
    std.debug.print("\n", .{});

    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var buf = try file.reader().readAllAlloc(test_allocator, 999999);
    defer test_allocator.free(buf);

    var entries = try parse(buf);
    defer {
        for (entries.items) |entry| {
            entry.digits.deinit();
            entry.display.deinit();
        }
        entries.deinit();
    }

    var sum: usize = 0;
    for (entries.items) |entry| {
        std.debug.print("Start: {s}\n", .{entry.digits.items[0]});
        std.sort.sort([]const u8, entry.digits.items, {}, cmpByLen);
        std.debug.print("sorted: {any}\n", .{entry.digits.items});
        sum += try solve(entry.digits.items, entry.display.items);
    }
    std.debug.print("sum: {}\n", .{sum});
}

// 0 -> 0, 2, 3, 5, 6, 7, 8, 9
// 1 -> 0, 4, 5, 6, 8, 9
// 2 -> 0, 1, 2, 3, 4, 7, 8, 9
// 3 -> 2, 3, 4, 5, 6, 8, 9
// 4 -> 0, 2, 6, 8
// 5 -> 0, 1, 3, 4, 5, 6, 7, 8, 9
// 6 -> 0, 2, 3, 5, 6, 8, 9

//  00
// 1  2
// 1  2
//  33
// 4  5
// 4  5
//  66

pub fn intersect(set: *AutoHashMap(u8, void), vals: []const u8) void {
    for (vals) |byte| {
        _ = set.remove(byte);
    }
}

pub fn retain(set: *AutoHashMap(u8, void), vals: []const u8) void {
    var keys = set.keyIterator();
    while (keys.next()) |key| {
        var keep = false;
        for (vals) |byte| {
            if (byte == key.*) {
                keep = true;
            }
        }
        // Todo: can I do this while iterating?
        if (!keep) {
            _ = set.remove(key.*);
        }
    }
}

// remove all entries in b from a
pub fn intersectSet(a: *AutoHashMap(u8, void), b: *AutoHashMap(u8, void)) void {
    var keys = b.keyIterator();
    while (keys.next()) |key| {
        _ = a.remove(key.*);
    }
}

//pub fn retainSet(

//pub fn oops(sets: []AutoHashMap(u8, void)) bool {
//for (sets) |set| {
//if (sets.count == 0) {
//unreachable;
//}
//}
//}

pub fn getLast(set: *AutoHashMap(u8, void)) u8 {
    var last_key_it = set.keyIterator();
    var last_key = [1]u8{last_key_it.next().?.*};
    return last_key[0];
}

pub fn contains(digit_str: []const u8, needle: u8) bool {
    //  std.debug.print("Contains: digit_str: {s}, needle: {c}\n", .{ digit_str, needle });
    for (digit_str) |byte| {
        if (byte == needle) {
            //         std.debug.print("Contains: {any}\n", .{true});
            return true;
        }
    }
    //std.debug.print("Contains: {any}\n", .{false});
    return false;
}

pub fn printSets(sets: [7]AutoHashMap(u8, void)) void {
    std.debug.print("----------------------\nPrintSets\n", .{});

    var idx: usize = 0;
    while (idx < 7) : (idx += 1) {
        std.debug.print("set[{}]: ", .{idx});
        var set_it = sets[idx].keyIterator();
        while (set_it.next()) |key_byte| {
            std.debug.print("{c}", .{key_byte.*});
        }
        std.debug.print("\n", .{});
    }
}

pub fn getLastStr(set: *AutoHashMap(u8, void)) []const u8 {
    var last_key_it = set.keyIterator();
    var last_key = [1]u8{last_key_it.next().?.*};
    var blah = last_key[0..];

    std.debug.print("Last_string: {s}\n", .{blah});
    // std.debug.print("bool: {any}\n", .{std.mem.containsAtLeast(u8, "abcdeg", 1, blah)});
    //
    return blah;
}

pub fn solve(digits: [][]const u8, display_digits: [][]const u8) !usize {
    var sets = [_]AutoHashMap(u8, void){undefined} ** 7;
    for (sets) |set, idx| {
        sets[idx] = AutoHashMap(u8, void).init(test_allocator);
        try sets[idx].put('a', {});
        try sets[idx].put('b', {});
        try sets[idx].put('c', {});
        try sets[idx].put('d', {});
        try sets[idx].put('e', {});
        try sets[idx].put('f', {});
        try sets[idx].put('g', {});
    }
    defer {
        for (sets) |set, idx| {
            sets[idx].deinit();
        }
    }

    for (digits) |digit| {
        // one only uses lines 2 / 5
        if (digit.len == 2) {
            intersect(&sets[0], digit);
            intersect(&sets[1], digit);
            intersect(&sets[3], digit);
            intersect(&sets[4], digit);
            intersect(&sets[6], digit);
            retain(&sets[2], digit);
            retain(&sets[5], digit);
            std.debug.print("After 1\n", .{});
            printSets(sets);
        }
        // seven uses 0 / 2 / 5
        if (digit.len == 3) {
            intersect(&sets[1], digit);
            intersect(&sets[3], digit);
            intersect(&sets[4], digit);
            intersect(&sets[6], digit);
            retain(&sets[0], digit);

            // slot 0 is the character in 1 but not 7
            intersectSet(&sets[0], &sets[2]);
            intersectSet(&sets[0], &sets[5]);
            std.debug.print("After 7\n", .{});
            printSets(sets);
        }
        // 4 uses 1 / 2 / 3 /5
        if (digit.len == 4) {
            intersect(&sets[0], digit);
            intersect(&sets[4], digit);
            intersect(&sets[6], digit);
        }

        // see what letter is missing
        // missing letter at 2 / 3 / 4
        if (digit.len == 6) {
            var missing = AutoHashMap(u8, void).init(test_allocator);
            defer missing.deinit();
            try missing.put('a', {});
            try missing.put('b', {});
            try missing.put('c', {});
            try missing.put('d', {});
            try missing.put('e', {});
            try missing.put('f', {});
            try missing.put('g', {});

            for (digit) |byte| {
                _ = missing.remove(byte);
            }
            var mis_val = missing.keyIterator().next().?.*;
            std.debug.print("missing: {c}\n", .{mis_val});
            intersect(&sets[0], &[1]u8{mis_val});
            intersect(&sets[1], &[1]u8{mis_val});
            intersect(&sets[5], &[1]u8{mis_val});
            intersect(&sets[6], &[1]u8{mis_val});
        }

        // propagate any sets with onl 1 item
        {
            var idx: usize = 0;
            while (idx < 7) : (idx += 1) {
                if (sets[idx].count() == 1) {
                    var ctr: usize = 0;
                    while (ctr < 7) : (ctr += 1) {
                        if (ctr == idx) {
                            continue;
                        }
                        var val = sets[idx].keyIterator().next().?.*;
                        _ = sets[ctr].remove(val);
                    }
                }
            }
        }
    }

    {
        std.debug.print("\n----------------------\nFirst Segment\n", .{});

        var idx: usize = 0;
        while (idx < 7) : (idx += 1) {
            std.debug.print("set[{}]: ", .{idx});
            var set_it = sets[idx].keyIterator();
            while (set_it.next()) |key_byte| {
                std.debug.print("{c}", .{key_byte.*});
            }
            std.debug.print("\n", .{});
        }
    }

    //  for (digits) |digit| {
    //if (digit.len == 6) {
    //// if we don't don't have 1 of the digits in from 2 / 5
    //// then this number is six and the missing digit is 2
    //var dig_key_it = sets[2].keyIterator();
    //var possible = [2]u8{ dig_key_it.next().?.*, dig_key_it.next().?.* };

    //var a = dig_key_it.next().?.*;
    //var contains_a = false;
    //for (digit) |char| {
    //if (char == a) {
    //contains_a = true;
    //}
    //}
    //var b = dig_key_it.next().?.*;
    //var contains_b = false;
    //for (digit) |char| {
    //if (char == b) {
    //contains_b = true;
    //}
    //}

    //if (contains_a and contains_b) {
    //continue;
    //}
    //// a must be 2
    //if (!contains_a) {
    ////std.debug.print("a: {c}, b: {c}\n", a);
    //_ = sets[2].remove(b);
    //_ = sets[5].remove(a);
    //}
    //if (!contains_b) {
    ////std.debug.print("a: {c}, b: {c}\n");
    //_ = sets[2].remove(a);
    //_ = sets[5].remove(b);
    //}
    //}
    //}

    // 4 and 6 are leftover from the 3 above unique cases
    //var key_it = sets[4].keyIterator();
    //var key = [2]u8{ key_it.next().?.*, key_it.next().?.* };
    ////std.debug.print("key: {s}\n", .{key[0..]});
    //intersect(&sets[0], key[0..]);
    //intersect(&sets[1], key[0..]);
    //intersect(&sets[2], key[0..]);
    //intersect(&sets[3], key[0..]);
    //intersect(&sets[5], key[0..]);

    // 1 and 3 leftover
    //  key_it = sets[1].keyIterator();
    //key = [2]u8{ key_it.next().?.*, key_it.next().?.* };
    //std.debug.print("key: {s}\n", .{key[0..]});
    //intersect(&sets[0], key[0..]);
    //intersect(&sets[2], key[0..]);
    //intersect(&sets[4], key[0..]);
    //intersect(&sets[5], key[0..]);
    //  intersect(&sets[6], key[0..]);

    // 0 is determined
    var last_key_it = sets[0].keyIterator();
    var last_key = [1]u8{last_key_it.next().?.*};
    intersect(&sets[1], last_key[0..]);
    intersect(&sets[2], last_key[0..]);
    intersect(&sets[3], last_key[0..]);
    intersect(&sets[4], last_key[0..]);
    intersect(&sets[5], last_key[0..]);
    intersect(&sets[6], last_key[0..]);

    //  last_key_it = sets[2].keyIterator();
    //  last_key = [1]u8{last_key_it.next().?.*};
    //  intersect(&sets[5], last_key[0..]);

    {
        var idx: usize = 0;
        while (idx < 7) : (idx += 1) {
            if (sets[idx].count() == 1) {
                var ctr: usize = 0;
                while (ctr < 7) : (ctr += 1) {
                    if (ctr == idx) {
                        continue;
                    }
                    var val = sets[idx].keyIterator().next().?.*;
                    _ = sets[ctr].remove(val);
                }
            }
        }
    }

    {
        var idx: usize = 0;
        while (idx < 7) : (idx += 1) {
            std.debug.print("set[{}]: ", .{idx});
            var set_it = sets[idx].keyIterator();
            while (set_it.next()) |key_byte| {
                std.debug.print("{c}", .{key_byte.*});
            }
            std.debug.print("\n", .{});
        }
    }

    var out = [4]u8{ 0, 0, 0, 0 };
    for (display_digits) |display_digit, idx| {
        std.debug.print("display_digit: {s}\n", .{display_digit});
        if (display_digit.len == 2) {
            out[idx] = '1';
            continue;
        }
        if (display_digit.len == 3) {
            out[idx] = '7';
            continue;
        }
        if (display_digit.len == 4) {
            out[idx] = '4';
            continue;
        }
        if (display_digit.len == 7) {
            out[idx] = '8';
            continue;
        }

        if (display_digit.len == 6) {
            var contains_2 = contains(display_digit, getLast(&sets[2]));
            var contains_4 = contains(display_digit, getLast(&sets[4]));
            if (contains_2 and contains_4) {
                out[idx] = '0';
                continue;
            } else if (contains_2) {
                out[idx] = '9';
                continue;
            } else if (contains_4) {
                out[idx] = '6';
                continue;
            } else {
                unreachable;
            }
            // zero

            // six
            // nine
        } else {
            var contains_1 = contains(display_digit, getLast(&sets[1]));
            //var contains_debug = std.mem.containsAtLeast(u8, "cdfeb", 1, getLastStr(&sets[1]));
            //var needle = getLastStr(&sets[1]);
            //std.debug.print("Contains1: {any}, digit: {s}, needle: {s}, debug: {any}\n", .{ contains_1, display_digit, getLastStr(&sets[1]), contains_debug });
            //std.debug.print("debug2: {any}, needle: {s}\n", .{ std.mem.containsAtLeast(u8, "cdfeb", 1, needle), needle });
            if (contains_1) {
                out[idx] = '5';
                continue;
            }
            var contains_4 = contains(display_digit, getLast(&sets[4]));
            if (contains_4) {
                out[idx] = '2';
                continue;
            } else {
                out[idx] = '3';
                continue;
            }

            // var contains_
            // 2
            // 3
            // 5
        }
    }
    std.debug.print("Out: {s}\n", .{out});
    return try std.fmt.parseUnsigned(usize, out[0..], 10);
}

pub fn cmpByLen(context: void, a: []const u8, b: []const u8) bool {
    return a.len < b.len;
}

test "sample 1" {
    std.debug.print("\n", .{});
    const input =
        \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
        \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
        \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
        \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
        \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
        \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
        \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
        \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
        \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
        \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
    ;

    //const input = "edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc";
    //const input = "acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf";

    //const input = "fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb";
    var fbs = std.io.fixedBufferStream(input);
    var buf = try fbs.reader().readAllAlloc(test_allocator, 999999);
    defer test_allocator.free(buf);

    var entries = try parse(buf);
    defer {
        for (entries.items) |entry| {
            entry.digits.deinit();
            entry.display.deinit();
        }
        entries.deinit();
    }

    var sum: usize = 0;
    for (entries.items) |entry| {
        std.debug.print("Start: {s}\n", .{entry.digits.items[0]});
        std.sort.sort([]const u8, entry.digits.items, {}, cmpByLen);
        std.debug.print("sorted: {any}\n", .{entry.digits.items});
        sum += try solve(entry.digits.items, entry.display.items);
    }
    std.debug.print("sum: {}\n", .{sum});

    //  for (entries.items[0].display) |digit| {
    //    std.debug.print("display: {}\n", .{digit});
    //  }

    //    for (entries.items[0].digits) |digit| {
    //std.debug.print("digit3 {s}\n", .{digit});
    //}

    //std.debug.print("\nentries: digits: {any}, display: {any}\n", .{ entries.items[0].digits, entries.items[0].display });
}
