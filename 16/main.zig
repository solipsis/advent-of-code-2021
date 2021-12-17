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
        } else {
            var num_sub_packets = try self.readu11();
            while (num_sub_packets > 0) : (num_sub_packets -= 1) {
                try sub_packets.append(try self.parsePacket());
            }
        }

        var val: u64 = 0;
        switch (packet_type) {
            0 => { // sum
                for (packet.sub_packets.items) |sub| {
                    val += sub.val;
                }
            },
            1 => { // product
                val = 1;
                for (packet.sub_packets.items) |sub| {
                    val *= sub.val;
                }
            },
            2 => { // min
                val = 99999999;
                for (packet.sub_packets.items) |sub| {
                    val = @min(val, sub.val);
                }
            },
        }

        return Packet{ .version = version, .packet_type = packet_type, .val = val, .sub_packets = sub_packets };
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

pub fn hexToBinary(hex: []const u8) ![]const u8 {
    var bytes_buf = try test_allocator.alloc(u8, hex.len / 2);
    defer test_allocator.free(bytes_buf);
    _ = try std.fmt.hexToBytes(bytes_buf, hex);

    var buf = try test_allocator.alloc(u8, bytes_buf.len * 8);
    var idx: usize = 0;
    for (bytes_buf) |byte| {
        _ = try std.fmt.bufPrint(buf[idx .. idx + 8], "{b:0>8}", .{byte});
        idx += 8;
    }

    return buf;
}

test "hexConvert" {
    std.debug.print("\n", .{});
    const input = "D2FE28";
    var bin = try hexToBinary(input);
    defer {
        test_allocator.free(bin);
    }

    std.debug.print("bin: {s}\n", .{bin});
}

test "literal" {
    std.debug.print("\n", .{});
    const input = "110100101111111000101000";
    var parser = Parser{ .buf = input, .idx = 0 };
    var packet = try parser.parsePacket();
    try expect(packet.val == 2021);
}

test "sub bit literal" {
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

test "sub num literal" {
    std.debug.print("\n", .{});
    const input = "11101110000000001101010000001100100000100011000001100000";
    var parser = Parser{ .buf = input, .idx = 0 };
    var packet = try parser.parsePacket();
    //defer cleanup_packet(packet);
    defer packet.deinit();
    try expect(packet.sub_packets.items.len == 3);
    try expect(packet.sub_packets.items[0].val == 1);
    try expect(packet.sub_packets.items[1].val == 2);
    try expect(packet.sub_packets.items[2].val == 3);
}

pub fn sumVersions(p: Packet) u64 {
    var sum: u64 = @intCast(u64, p.version);
    for (p.sub_packets.items) |sub| {
        sum += sumVersions(sub);
    }
    return sum;
}

test "part 1" {
    const input = "2056FA18025A00A4F52AB13FAB6CDA779E1B2012DB003301006A35C7D882200C43289F07A5A192D200C1BC011969BA4A485E63D8FE4CC80480C00D500010F8991E23A8803104A3C425967260020E551DC01D98B5FEF33D5C044C0928053296CDAFCB8D4BDAA611F256DE7B945220080244BE59EE7D0A5D0E6545C0268A7126564732552F003194400B10031C00C002819C00B50034400A70039C009401A114009201500C00B00100D00354300254008200609000D39BB5868C01E9A649C5D9C4A8CC6016CC9B4229F3399629A0C3005E797A5040C016A00DD40010B8E508615000213112294749B8D67EC45F63A980233D8BCF1DC44FAC017914993D42C9000282CB9D4A776233B4BF361F2F9F6659CE5764EB9A3E9007ED3B7B6896C0159F9D1EE76B3FFEF4B8FCF3B88019316E51DA181802B400A8CFCC127E60935D7B10078C01F8B50B20E1803D1FA21C6F300661AC678946008C918E002A72A0F27D82DB802B239A63BAEEA9C6395D98A001A9234EA620026D1AE5CA60A900A4B335A4F815C01A800021B1AE2E4441006A0A47686AE01449CB5534929FF567B9587C6A214C6212ACBF53F9A8E7D3CFF0B136FD061401091719BC5330E5474000D887B24162013CC7EDDCDD8E5E77E53AF128B1276D0F980292DA0CD004A7798EEEC672A7A6008C953F8BD7F781ED00395317AF0726E3402100625F3D9CB18B546E2FC9C65D1C20020E4C36460392F7683004A77DB3DB00527B5A85E06F253442014A00010A8F9106108002190B61E4750004262BC7587E801674EB0CCF1025716A054AD47080467A00B864AD2D4B193E92B4B52C64F27BFB05200C165A38DDF8D5A009C9C2463030802879EB55AB8010396069C413005FC01098EDD0A63B742852402B74DF7FDFE8368037700043E2FC2C8CA00087C518990C0C015C00542726C13936392A4633D8F1802532E5801E84FDF34FCA1487D367EF9A7E50A43E90";
    var bin = try hexToBinary(input);
    defer {
        test_allocator.free(bin);
    }

    var parser = Parser{ .buf = bin, .idx = 0 };
    var packet = try parser.parsePacket();
    defer packet.deinit();
    var sum_versions = sumVersions(packet);
    std.debug.print("part 1: {}\n", .{sum_versions});
}

//const input = std.mem.trim(u8, @embedFile("../input/day16.txt"), " \n");
//

