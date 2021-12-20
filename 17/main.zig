const std = @import("std");
const expect = std.testing.expect;

const Probe = struct {
    x: isize,
    y: isize,
    x_vel: isize,
    y_vel: isize,
    max_y: isize,

    fn step(self: *Probe) void {
        self.x += self.x_vel;
        self.y += self.y_vel;
        self.max_y = std.math.max(self.max_y, self.y);
        if (self.x_vel > 0) {
            self.x_vel -= 1;
        } else if (self.x_vel < 0) {
            self.x_vel += 1;
        }
        self.y_vel -= 1;
    }
};

test "sample 1" {
    std.debug.print("\n", .{});
    var min_target_x: isize = 235;
    var max_target_x: isize = 259;

    var min_target_y: isize = -118;
    var max_target_y: isize = -62;
    //
    var z = Probe{ .x = 0, .y = 0, .x_vel = 6, .y_vel = 9, .max_y = -10000 };
    var ctr: usize = 0;
    while (ctr < 20) : (ctr += 1) {
        z.step();
        std.debug.print("x: {}, y: {}, max: {}\n", .{ z.x, z.y, z.max_y });
    }

    //   var min_target_x: isize = 20;
    //var max_target_x: isize = 30;

    //var min_target_y: isize = -10;
    //   var max_target_y: isize = -5;
    //
    var hit_count: usize = 0;

    var max_y: isize = -1000;
    var x: isize = 0;
    while (x < 300) : (x += 1) {
        var y: isize = -500;
        while (y < 500) : (y += 1) {
            var p = Probe{ .x = 0, .y = 0, .x_vel = x, .y_vel = y, .max_y = -10000 };
            while (true) {
                p.step();
                if (p.x >= min_target_x and p.x <= max_target_x and p.y >= min_target_y and p.y <= max_target_y) {
                    max_y = std.math.max(max_y, p.max_y);
                    hit_count += 1;
                    break;
                }

                if (p.x > max_target_x) {
                    break;
                }
                if (p.x < min_target_x and p.x_vel == 0) {
                    break;
                }
                if (p.y < min_target_y) {
                    break;
                }
            }
        }
    }

    std.debug.print("max: {}\n", .{max_y});
    std.debug.print("hit_count: {}\n", .{hit_count});
}
