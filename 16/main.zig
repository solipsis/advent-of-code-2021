const std = @import("std");
const ArrayList = std.ArrayList;
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

const Packet = struct {
    version: u3,
    packet_type: u3,
    val: u64,
    sub_packets: ArrayList(Packet),
};

const Parser = struct {
    buf: []const u8,
    idx: usize,

    fn parsePacket(self: *Parser) !Packet {
        var version: u3 = try self.readu3();
        var packet_type: u3 = try self.readu3();

        // Literal
        if (packetType == 4) {
            const i = try self.parseLiteral();
            return Packet{ .version = version, .packet_type = packet_type, .val = i, .sub_packets = undefined };
        }

        var length_t

        return undefined;
    }

    //   fn parseHeader(self: *Parser) !u3 {
    //  }

    fn parseLiteral(self: *Parser) !u64 {
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

    fn readu4(self: *Parser) !u4 {
        var i: u4 = try std.fmt.parseUnsigned(u4, self.buf[self.idx .. self.idx + 4], 2);
        self.idx += 4;
        return i;
    }

    fn readu3(self: *Parser) !u3 {
        var i: u3 = try std.fmt.parseInt(u3, self.buf[self.idx .. self.idx + 3], 2);
        self.idx += 3;
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

//const input = std.mem.trim(u8, @embedFile("../input/day16.txt"), " \n");

