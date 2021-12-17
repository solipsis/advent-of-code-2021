const std = @import("std");
const ArrayList = std.ArrayList;
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

const Packet = struct {
    version: u3,
    packet_type: u3,
    val: u64,
    sub_packets: ArrayList(Packet),

    fn deinit(self: Packet) void {
        for (self.sub_packets.items) |sub| {
            sub.deinit();
        }
        self.sub_packets.deinit();
    }
};

pub fn cleanup_packet(p: Packet) void {
    for (p.sub_packets.items) |packet| {
        cleanup_packet(packet);
    }
    p.sub_packets.deinit();
}

const ParserError = error{OutOfMemory} || std.fmt.ParseIntError;

const Parser = struct {
    buf: []const u8,
    idx: usize,

    fn parsePacket(self: *Parser) ParserError!Packet {
        std.debug.print("parsePacket\n", .{});
        var version: u3 = try self.readu3();
        var packet_type: u3 = try self.readu3();
        var sub_packets = ArrayList(Packet).init(test_allocator);

        // Literal
        if (packet_type == 4) {
            const i = try self.parseLiteral();
            std.debug.print("literal_val: {}\n", .{i});
            return Packet{ .version = version, .packet_type = packet_type, .val = i, .sub_packets = sub_packets };
        }

        var length_type_id = try self.readBit();
        if (length_type_id == 0) {
            var sub_packet_bit_length = try self.readu15();
            var bit_target = self.idx + sub_packet_bit_length;
            std.debug.print("sub_packet_bit_length: {}\n", .{sub_packet_bit_length});

            while (self.idx < bit_target) {
                std.debug.print("idx: {}\n", .{self.idx});
                std.debug.print("parse_subpacket\n", .{});
                try sub_packets.append(try self.parsePacket());
            }
        }

        return Packet{ .version = version, .packet_type = packet_type, .val = 0, .sub_packets = sub_packets };
    }

    fn parseLiteral(self: *Parser) !u64 {
        std.debug.print("parseLiteral\n", .{});
        var literal = ArrayList(u8).init(test_allocator);
        defer literal.deinit();

        var last_segment = false;
        while (!last_segment) {
            const flag = try self.readBit();
            if (flag == 0) {
                last_segment = true;
            }

            try literal.appendSlice(self.buf[self.idx .. self.idx + 4]);
            self.idx += 4;
        }

        var i: u64 = try std.fmt.parseUnsigned(u64, literal.items, 2);
        return i;
    }

    fn parseType(self: *Parser) !u3 {}

    fn readBit(self: *Parser) !u1 {
        var i: u1 = try std.fmt.parseUnsigned(u1, self.buf[self.idx .. self.idx + 1], 2);
        self.idx += 1;
        return i;
    }

    fn readu3(self: *Parser) !u3 {
        var i: u3 = try std.fmt.parseInt(u3, self.buf[self.idx .. self.idx + 3], 2);
        self.idx += 3;
        return i;
    }

    fn readu4(self: *Parser) !u4 {
        var i: u4 = try std.fmt.parseUnsigned(u4, self.buf[self.idx .. self.idx + 4], 2);
        self.idx += 4;
        return i;
    }

    fn readu11(self: *Parser) !u11 {
        var i: u11 = try std.fmt.parseUnsigned(u11, self.buf[self.idx .. self.idx + 11], 2);
        self.idx += 11;
        return i;
    }

    fn readu15(self: *Parser) !u15 {
        var i: u15 = try std.fmt.parseUnsigned(u15, self.buf[self.idx .. self.idx + 15], 2);
        self.idx += 15;
        return i;
    }
};

test "literal" {
    std.debug.print("\n", .{});
    const input = "110100101111111000101000";
    var parser = Parser{ .buf = input, .idx = 0 };
    var packet = try parser.parsePacket();
    try expect(packet.val == 2021);
}

test "sub literal" {
    std.debug.print("\n", .{});
    const input = "00111000000000000110111101000101001010010001001000000000";
    var parser = Parser{ .buf = input, .idx = 0 };
    var packet = try parser.parsePacket();
    //defer cleanup_packet(packet);
    defer packet.deinit();
    try expect(packet.sub_packets.items.len == 2);
    try expect(packet.sub_packets.items[0].val == 10);
    try expect(packet.sub_packets.items[1].val == 20);
}

//const input = std.mem.trim(u8, @embedFile("../input/day16.txt"), " \n");

