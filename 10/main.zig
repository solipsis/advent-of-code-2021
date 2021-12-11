const std = @import("std");
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

pub fn parse(reader: anytype) !usize {
    var buf = try reader.readAllAlloc(test_allocator, 99999);
    defer test_allocator.free(buf);
    var trimmed = std.mem.trim(u8, buf, "\n"); // file trailing newline

    var score: usize = 0;

    var complete_scores = ArrayList(usize).init(test_allocator);
    defer complete_scores.deinit();

    var row_it = std.mem.split(trimmed, "\n");
    outer: while (row_it.next()) |raw_row| {
        var stack = std.ArrayList(usize).init(test_allocator);
        defer stack.deinit();
        for (raw_row) |char, idx| {
            //       std.debug.print("stack_len: {}\n", .{stack.items.len});
            switch (char) {
                '{', '(', '[', '<' => {
                    try stack.append(char);
                },
                '}' => {
                    if (stack.pop() != '{') {
                        score += 1197;
                        continue :outer;
                    }
                },
                ')' => {
                    if (stack.pop() != '(') {
                        score += 3;
                        continue :outer;
                    }
                },
                ']' => {
                    if (stack.pop() != '[') {
                        score += 57;
                        continue :outer;
                    }
                },
                '>' => {
                    if (stack.pop() != '<') {
                        score += 25137;
                        continue :outer;
                    }
                },
                else => unreachable,
            }
        }

        var comp_score: usize = 0;

        while (stack.items.len > 0) {
            //        std.debug.print("len: {}\n", .{stack.items.len});
            //std.debug.print("{any}\n", .{stack.items});
            comp_score *= 5;
            switch (stack.pop()) {
                '{' => comp_score += 3,
                '(' => comp_score += 1,
                '[' => comp_score += 2,
                '<' => comp_score += 4,
                else => unreachable,
            }
        }
        try complete_scores.append(comp_score);
    }

    std.debug.print("\nscore: {}\n", .{score});
    std.sort.sort(usize, complete_scores.items, {}, cmpByValue);

    const mid: usize = @divFloor(complete_scores.items.len, 2);

    std.debug.print("complete: {}\n", .{complete_scores.items[mid]});

    return score;
}

fn cmpByValue(context: void, a: usize, b: usize) bool {
    return std.sort.asc(usize)(context, a, b);
}

test "sample 1" {
    const input =
        \\[({(<(())[]>[[{[]{<()<>>
        \\[(()[<>])]({[<{<<[]>>(
        \\{([(<{}[<>[]}>{[]{[(<()>
        \\(((({<>}<{<{<>}{[]{[]{}
        \\[[<[([]))<([[{}[[()]]]
        \\[{[{({}]{}}([{[{{{}}([]
        \\{<[[]]>}<{[{[{[]{()[[[]
        \\[<(<(<(<{}))><([]([]()
        \\<{([([[(<>()){}]>(<<{{
        \\<{([{{}}[<[[[<>{}]]]>[]]
    ;
    var fbs = std.io.fixedBufferStream(input);
    _ = try parse(fbs.reader());
}

test "part 1" {
    var file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();
    _ = try parse(file.reader());
}
