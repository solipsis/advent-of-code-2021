const std = @import("std");
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

const Entry = struct {
    digits: [10]u7,
    display: [4]u7,
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

pub fn parse(reader: anytype) !ArrayList(Entry) {
    var count: usize = 0;

    var buf = try reader.readAllAlloc(test_allocator, 99999);
    defer test_allocator.free(buf);
    var trimmed = std.mem.trim(u8, buf, "\n"); // trailing newline

    var entries = ArrayList(Entry).init(test_allocator);

    var line_iter = std.mem.split(trimmed, "\n");
    while (line_iter.next()) |line| {
        std.debug.print("LINE: {s}XXX\n", .{line});

        var digits = [_]u7{0} ** 10;
        var display = [_]u7{0} ** 4;
        var entry = try entries.addOne();

        // split in half
        var segment_iter = std.mem.split(line, " | ");

        var digit_raw = segment_iter.next().?;
        var digit_iter = std.mem.split(digit_raw, " ");
        var idx: usize = 0;
        while (digit_iter.next()) |digit| {
            // std.mem.copy(u8, entry.digits[idx][0..], digit);
            //digits[idx] = digit[0..];
            idx += 1;
        }

        var display_raw = segment_iter.next().?;
        var display_iter = std.mem.split(display_raw, " ");
        idx = 0;
        while (display_iter.next()) |digit| {
            //std.debug.print("digit: {s}X\n", .{digit});
            var mask: u7 = 0;
            for (digit) |byte| {
                //std.debug.print("byte: {}\n", .{byte});
                mask |= charToMask(byte);
            }
            const pc = @popCount(u7, mask);
            if (pc == 2 or pc == 3 or pc == 4 or pc == 7) {
                count += 1;
            }

            idx += 1;
        }

        //        for (entries.items[0].digits) |digit| {
        //std.debug.print("digit: {s}\n", .{digit});
        //        }
    }

    std.debug.print("popcount: {}\n", .{count});

    //  for (entries.items[0].digits) |digit| {
    //std.debug.print("digit2: {s}\n", .{digit});
    //  }
    return entries;
}

pub fn blah() []const u8 {
    return "hello";
}

test "strings" {
    var dav = blah();
    std.debug.print("Dave: {s}\n", .{dav});
}

test "part 1" {
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();

    var entries = try parse(file.reader());
    defer entries.deinit();
}

test "sample 1" {
    //const input = "acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf";
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
    var fbs = std.io.fixedBufferStream(input);
    var entries = try parse(fbs.reader());
    defer entries.deinit();

    //for (entries.items[0].display) |digit| {
    //std.debug.print("display: {s}\n", .{digit});
    //}

    //    for (entries.items[0].digits) |digit| {
    //std.debug.print("digit3 {s}\n", .{digit});
    //}

    //std.debug.print("\nentries: digits: {any}, display: {any}\n", .{ entries.items[0].digits, entries.items[0].display });
}
