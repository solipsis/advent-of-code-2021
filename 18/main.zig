const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

//const Pair = struct {
//id: usize,
//left: ?*Pair,
//right: ?*Pair,
//left_val: ?isize,
//right_val: ?isize,
////parent: ?*Pair,
////depth: usize = 0,

//};

const Node = struct {
    id: usize = 0,
    left: ?*Node = null,
    right: ?*Node = null,
    parent: ?*Node = null,
    allocator: *Allocator,
    val: ?isize,

    fn init(self: *Node, id: usize, parent: ?*Node, allocator: *Allocator) void {
        self.left = null;
        self.right = null;
        self.parent = null;
        self.val = null;
        self.id = id;
        self.allocator = allocator;
    }
};

const Parser = struct {
    buffer: []const u8,
    idx: usize = 0,
    stack: ArrayList(*Node),
    allocator: *Allocator,
    next_id: usize = 0,
    root: *Node = undefined,

    fn parse(self: *Parser) !void {

        // root
        self.root = try self.allocator.create(Node);
        self.root.init(self.next_id, null, self.allocator);
        self.next_id += 1;
        //self.root.id = self.next_id;
        //self.root.left = null;
        //self.root.right = null;
        try self.stack.append(self.root);
        if (self.root.left) |left| {
            std.debug.print("Garbo\n", .{});
        }

        while (self.idx < self.buffer.len) {
            var tok = try self.read();
            // create node
            if (std.mem.eql(u8, tok, "[")) {
                var current_node = self.stack.items[self.stack.items.len - 1];

                std.debug.print("L_BRACKET\n", .{});
                var p = try self.allocator.create(Node);
                p.init(self.next_id, current_node, self.allocator);
                self.next_id += 1;
                //    p.id = self.next_id;
                //    p.left = null;
                //    p.right = null;
                //    p.val = -1;
                //    self.next_id += 1;

                // TODO: Why is current_node.left evaluating as true right from the beginning???????????
                // probably need to write INIT function for nodes

                // already have a left child so this must be right
                if (current_node.left) |left_pair| {
                    std.debug.print("add_right: \n", .{});
                    std.debug.print("lp: {}\n", .{left_pair});
                    current_node.right = p;
                }
                // else if (current_node.val) |val| { // same as above
                //     std.debug.print("add_right: {}\n", .{});
                //    current_node.right = p;
                else { // must be left side

                    std.debug.print("add_left: \n", .{});
                    current_node.left = p;
                }
                //  p.id = self.next_id;
                // self.next_id += 1;
                try self.stack.append(p);
                std.debug.print("root1: {}\n", .{self.root});
            } else if (std.mem.eql(u8, tok, "]")) {
                std.debug.print("R_BRACKET\n", .{});
                _ = self.stack.pop();
                std.debug.print("root2: {}\n", .{self.root});
            } else { // literal
                std.debug.print("LITERAL\n", .{});
                var current_node = self.stack.items[self.stack.items.len - 1];
                var literal = try self.allocator.create(Node);
                literal.init(self.next_id, current_node, self.allocator);
                self.next_id += 1;
                var val = try std.fmt.parseInt(isize, tok, 10);
                literal.val = val;
                // already have a left child so this must be right
                if (current_node.left) |_left_pair| {
                    current_node.right = literal;
                }
                //else if (current_node.val) |_val| { // same as above
                //    current_node.right = literal;
                // }
                else { // must be left side
                    current_node.left = literal;
                }
                std.debug.print("root3: {}\n", .{self.root});

                // don't append literals to stack
            }
        }

        std.debug.print("root: {}\n", .{self.root});

        //return null;
    }

    fn read(self: *Parser) ![]const u8 {
        if (self.buffer[self.idx] == '[') {
            self.idx += 1;
            return "[";
        }
        if (self.buffer[self.idx] == ']') {
            self.idx += 1;
            return "]";
        }
        // ignore and read next segment
        if (self.buffer[self.idx] == ',') {
            self.idx += 1;
            return self.read();
        }
        // read n-digit number
        var buf = try self.allocator.alloc(u8, 32); // should be enough?
        std.mem.set(u8, buf, 0);
        var len: usize = 0;

        while (self.buffer[self.idx] >= '0' and self.buffer[self.idx] <= '9') {
            buf[len] = self.buffer[self.idx];
            self.idx += 1;
            len += 1;
        }
        return buf[0..len];
    }
};

const ParserError = error{OutOfMemory} || std.fmt.ParseIntError || error{DivisionByZero};

fn inOrder(n: *Node, res: *ArrayList(*Node)) ParserError!void {
    if (n.left) |left| {
        try inOrder(left, res);
    }
    try res.append(n);
    if (n.right) |right| {
        try inOrder(right, res);
    }
}

fn split(n: *Node) !void {
    var l_val = try std.math.divFloor(isize, n.val.?, 2);
    var r_val = try std.math.divCeil(isize, n.val.?, 2);

    // convert from literal node to pair
    n.val = null;

    var left = try n.allocator.create(Node);
    left.init(99999, n, n.allocator);
    left.val = l_val;
    var right = try n.allocator.create(Node);
    right.init(999999, n, n.allocator);
    right.val = r_val;

    n.left = left;
    n.right = right;
}

fn explode(parent: *Node, inOrderTree: ArrayList(*Node)) void {
    var lhs = parent.left.?;
    var rhs = parent.right.?;
    // find idx of target in inOrder
    var idx: usize = 0;
    for (inOrderTree.items) |item, i| {
        if (item.id == parent.id) {
            idx = i;
            break;
        }
    }

    // update first literal to the left
    var ctr: isize = @intCast(isize, idx);
    while (ctr >= 0) : (ctr -= 1) {
        if (inOrderTree.items[@intCast(usize, ctr)].id == lhs.id) {
            continue;
        }
        if (inOrderTree.items[@intCast(usize, ctr)].val) |val| {
            inOrderTree.items[@intCast(usize, ctr)].val.? += lhs.val.?;
            break;
        }
    }
    // update first literal to the right
    ctr = @intCast(isize, idx);
    while (ctr < inOrderTree.items.len) : (ctr += 1) {
        if (inOrderTree.items[@intCast(usize, ctr)].id == rhs.id) {
            continue;
        }
        if (inOrderTree.items[@intCast(usize, ctr)].val) |val| {
            inOrderTree.items[@intCast(usize, ctr)].val.? += rhs.val.?;
            break;
        }
    }
    // turn parent into a literal node
    parent.left = null;
    parent.right = null;
    parent.val = 0;
}

fn reduce_explode(n: *Node, depth: usize, inOrderTree: ArrayList(*Node)) bool {
    //  std.debug.print("depth: {}: {any}\n\n", .{ depth, n });
    if (depth == 4 and n.val == null) {
        //     std.debug.print("exploding... {any}\n", .{n});
        explode(n, inOrderTree);
        return true;
    }
    if (n.left) |left| {
        if (reduce_explode(left, depth + 1, inOrderTree)) {
            return true; // exit if we found an action to do
        }
    }
    if (n.right) |right| {
        if (reduce_explode(right, depth + 1, inOrderTree)) {
            return true; // exit if we found an action to do
        }
    }
    return false;
}

fn reduce_split(n: *Node) ParserError!bool {

    // in-order traversal looking for first val >= 10
    if (n.left) |left| {
        if (try reduce_split(left)) {
            return true;
        }
    }
    if (n.val) |val| {
        if (val >= 10) {
            try split(n);
            return true;
        }
    }
    if (n.right) |right| {
        if (try reduce_split(right)) {
            return true;
        }
    }
    return false;
}

//pub fn printNode(n: *Node) void {
////std.debug.print("n: {}\n", .{n});
//if (n.left) |left| {
//std.debug.print("[", .{});
//print(left);
//}
//if (n.right) |right| {
//std.debug.print(",", .{});
//print(right);
//std.debug.print("]", .{});
//}
//if (n.val) |val| {
//std.debug.print("{}", .{val});
//}
//}

pub fn print(n: *Node) void {
    //std.debug.print("n: {}\n", .{n});
    if (n.left) |left| {
        std.debug.print("[", .{});
        print(left);
    }
    if (n.right) |right| {
        std.debug.print(",", .{});
        print(right);
        std.debug.print("]", .{});
    }
    if (n.val) |val| {
        std.debug.print("{}", .{val});
    }
}

//pub fn explode(p: *Pair) void {
//   const left = p.left_val.?;
// find first regular to left

// find first regular to right

//}
//
pub fn reduce(n: *Node, allocator: *Allocator) !void {
    while (true) {
        var inOrderNodes = ArrayList(*Node).init(allocator);
        defer inOrderNodes.deinit();
        try inOrder(n, &inOrderNodes);

        if (reduce_explode(n, 0, inOrderNodes)) {
            std.debug.print("explode\n", .{});
            continue;
        }
        if (try reduce_split(n)) {
            std.debug.print("split\n", .{});
            continue;
        }
        break;
    }
}

test "blah" {
    std.debug.print("\n-------------------------\n", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    //var buf = "[1,2]";
    //var buf = "[[1,2],3]";
    //var buf = "[9,[8,7]]";
    //var buf = "[[1,9],[8,5]]";
    //var buf = "[[[[1,2],[3,4]],[[5,6],[7,8]]],9]";
    //var buf = "[[[9,[3,8]],[[0,9],6]],[[[3,7],[4,9]],3]]";
    //var buf = "[[[[1,3],[5,3]],[[1,3],[8,7]]],[[[4,9],[6,9]],[[8,2],[7,3]]]]";
    //var buf = "[[[[[9,8],1],2],3],4]";
    //var buf = "[[6,[5,[4,[3,2]]]],1]";
    //var buf = "[[3,[2,[1,[7,3]]]],[6,[5,[4,[3,2]]]]]";
    //var buf = "[[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]";
    //var buf = "[[[[0,7],4],[15,[0,13]]],[1,1]]";
    var buf = "[[[[[4,3],4],4],[7,[[8,4],9]]],[1,1]]";

    // The subitem depth calc is not quite right
    // explode should trigger at only [3,2] not also at [4
    //var buf = "[7,[6,[5,[4,[3,2]]]]";

    var stack = ArrayList(*Node).init(&arena.allocator);
    //try alloc_stuff(&arena.allocator);
    var parser = Parser{ .allocator = &arena.allocator, .buffer = buf, .idx = 0, .stack = stack, .next_id = 0 };
    _ = try parser.parse();

    std.debug.print("root_id: {}\n", .{parser.root.id});
    print(parser.root.left.?);
    std.debug.print("\n", .{});

    var inOrderNodes = ArrayList(*Node).init(&arena.allocator);
    try inOrder(parser.root.left.?, &inOrderNodes);
    for (inOrderNodes.items) |n| {
        if (n.val) |val| {
            std.debug.print("{},", .{val});
        }
    }
    std.debug.print("\n", .{});

    std.debug.print("reducing...\n", .{});
    try reduce(parser.root.left.?, &arena.allocator);
    print(parser.root.left.?);
    std.debug.print("\n", .{});

    //_ = reduce_explode(parser.root.left.?, 0, inOrderNodes);
    // _ = try reduce_split(parser.root.left.?);
    //std.debug.print("\n", .{});
    //print(parser.root.left.?);
    //std.debug.print("\n", .{});
    //_ = try reduce_split(parser.root.left.?);
    //print(parser.root.left.?);
    //std.debug.print("\n", .{});
    //_ = try reduce_explode(parser.root.left.?);
    //print(parser.root.left.?);
    // std.debug.print("\n", .{});
}

pub fn alloc_stuff(allocator: *Allocator) !void {
    _ = try allocator.alloc(u8, 100);
}
