const std = @import("std");
const ArrayList = std.ArrayList;
const expect = std.testing.expect;

const PracticeDie = struct {
    val: usize = 1,
    max: usize = 100,

    fn roll(self: *PracticeDie) usize {
        const v = self.val;
        if (self.val == self.max) {
            self.val = 0;
        }
        self.val += 1;
        return v;
    }
};

test "sample" {
    var die = PracticeDie{};
    var p1_loc: usize = 4;
    var p2_loc: usize = 8;
    var p1_score: usize = 0;
    var p2_score: usize = 0;
    var total_rolls: usize = 0;

    while (true) {
        var p1_roll = (die.roll() + die.roll() + die.roll()) % 10;
        total_rolls += 3;
        p1_loc += p1_roll;
        if (p1_loc > 10) {
            p1_loc -= 10;
        }
        p1_score += p1_loc;
        if (p1_score >= 1000) {
            std.debug.print("p1 wins: {}\n", .{p2_score * total_rolls});
            break;
        }

        var p2_roll = (die.roll() + die.roll() + die.roll()) % 10;
        total_rolls += 3;
        p2_loc += p2_roll;
        if (p2_loc > 10) {
            p2_loc -= 10;
        }
        p2_score += p2_loc;
        if (p2_score >= 1000) {
            std.debug.print("p2 wins: {}\n", .{p1_score * total_rolls});
            break;
        }
    }
}

const Wins = struct {
    p1: usize = 0,
    p2: usize = 0,
};

pub fn equal(a: Wins, b: Wins) bool {
    if (a.p1 == b.p1 and a.p2 == b.p2) return true;
    return false;
}

pub fn addWins(current: Wins, next: Wins, mult: usize) Wins {
    return Wins{ .p1 = current.p1 + (next.p1 * mult), .p2 = current.p2 + (next.p2 * mult) };
}

const RollProb = struct {
    roll: usize,
    prob: usize,
};

const roll_probs = [7]RollProb{
    .{ .roll = 3, .prob = 1 },
    .{ .roll = 4, .prob = 3 },
    .{ .roll = 5, .prob = 6 },
    .{ .roll = 6, .prob = 7 },
    .{ .roll = 7, .prob = 6 },
    .{ .roll = 8, .prob = 3 },
    .{ .roll = 9, .prob = 1 },
};

pub fn dp(state: *[2][21][21][11][11]Wins, player: usize, sa: usize, sb: usize, pa: usize, pb: usize) Wins {
    //std.debug.print("player: {}, sa: {}, sb: {}, pa: {}, pb: {}\n", .{ player, sa, sb, pa, pb });

    // recursive base case
    if (sa >= 21) return Wins{ .p1 = 1, .p2 = 0 };
    if (sb >= 21) return Wins{ .p1 = 0, .p2 = 1 };

    // see if in cache
    if (!equal(state[player][sa][sb][pa][pb], Wins{ .p1 = 0, .p2 = 0 })) return state[player][sa][sb][pa][pb];
    // recursive base case
    if (sa >= 21) return Wins{ .p1 = 1, .p2 = 0 };
    if (sb >= 21) return Wins{ .p1 = 0, .p2 = 1 };

    var wins = Wins{ .p1 = 0, .p2 = 0 };

    for (roll_probs) |roll| {
        var n_player: usize = undefined;
        var n_sa: usize = undefined;
        var n_sb: usize = undefined;
        var n_pa: usize = undefined;
        var n_pb: usize = undefined;

        //player 2
        if (player == 1) {
            n_player = 0;

            n_pb = pb + roll.roll;
            if (n_pb > 10) {
                n_pb -= 10;
            }
            n_sb = sb + n_pb;

            // don't change p1
            n_sa = sa;
            n_pa = pa;
        } else { // player 1
            n_player = 1;

            n_pa = pa + roll.roll;
            if (n_pa > 10) {
                n_pa -= 10;
            }
            n_sa = sa + n_pa;

            // don't change p2
            n_sb = sb;
            n_pb = pb;
        }
        var sub_wins = dp(state, n_player, n_sa, n_sb, n_pa, n_pb);
        wins = addWins(wins, sub_wins, roll.prob);
    }

    state[player][sa][sb][pa][pb] = wins;
    return wins;
}

test "sample 2" {
    std.debug.print("\n", .{});
    var state = [_][21][21][11][11]Wins{[_][21][11][11]Wins{[_][11][11]Wins{[_][11]Wins{[_]Wins{Wins{ .p1 = 0, .p2 = 0 }} ** 11} ** 11} ** 21} ** 21} ** 2;

    var wins = dp(&state, 0, 0, 0, 4, 8);
    std.debug.print("Sample 2: {any}\n", .{wins});
    try expect(std.math.max(wins.p1, wins.p2) == 444356092776315);
}

test "part 2" {
    std.debug.print("\n", .{});

    //const state = [_][21][10][10]Wins{[_][10][10]Wins{[_][10]Wins{[_]Wins{Wins{ .p1 = 0, .p2 = 0 }} ** 10} ** 10} ** 21} ** 21;
    var state = [_][21][21][11][11]Wins{[_][21][11][11]Wins{[_][11][11]Wins{[_][11]Wins{[_]Wins{Wins{ .p1 = 0, .p2 = 0 }} ** 11} ** 11} ** 21} ** 21} ** 2;

    var wins = dp(&state, 0, 0, 0, 7, 9);
    std.debug.print("Part 2: {any}\n", .{std.math.max(wins.p1, wins.p2)});

    // wins [scoreA] / [scoreB] / [posA] / [posB]
    //  = 1*[posA+3]
    //  + 3*[scoreA+4]
    //  + 6*[scoreA+5]
    //  + 7*[scoreA+6]
    //  + 6*[scoreA+7]
    //  + 3*[scoreA+8]
    //  + 1*[scoreA+9]
    //  THIS IS ACTUALLY JUST PROBABILITY
    //
    //var sum: usize = 0;
    //var scoreA: usize = 0;
    //while (scoreA < 21) : (scoreA += 1) {
    //var scoreB: usize = 0;
    //while (scoreB < 21) : (scoreB += 1) {
    //var posA: usize = 0;
    //while (posA < 10) : (posA += 1) { // +1 for all vals
    //var posB: usize = 0;
    //while (posB < 10) : (posB += 1) {
    //sum += 1;
    //}
    //}
    //}
    //}
    //std.debug.print("sum: {}\n", .{sum});

    //std.debug.print("\n{any}\n", .{state});

    // var a: usize = 0;
    //while (a < 21) : (a += 1) {
    //var b: usize = 0;
    //while (b < 21) : (b += 1) {
    //var c: usize = 0;
    //while (c < 10) : (c += 1) {
    //std.mem.set(usize, state[a][b][c], 0);
    //}
    //std.mem.set(usize, state[a][b], 0);
    //}
    //std.mem.set(usize, state[a], 0);
    // }

    //  a = 0;
    //while (a < 21) : (a += 1) {
    //b = 0;
    //while (b < 21) : (b += 1) {
    //c = 0;
    //while (c < 10) : (c += 1) {
    //std.debug.print("\n{any}", .{state[a][b][c]});
    //}
    //}
    //  }
}

// state
// scoreA / scoreB / posA / posB

test "part 1" {
    var die = PracticeDie{};
    var p1_loc: usize = 7;
    var p2_loc: usize = 9;
    var p1_score: usize = 0;
    var p2_score: usize = 0;
    var total_rolls: usize = 0;

    while (true) {
        var p1_roll = (die.roll() + die.roll() + die.roll()) % 10;
        total_rolls += 3;
        p1_loc += p1_roll;
        if (p1_loc > 10) {
            p1_loc -= 10;
        }
        p1_score += p1_loc;
        if (p1_score >= 1000) {
            std.debug.print("p1 wins: {}\n", .{p2_score * total_rolls});
            break;
        }

        var p2_roll = (die.roll() + die.roll() + die.roll()) % 10;
        total_rolls += 3;
        p2_loc += p2_roll;
        if (p2_loc > 10) {
            p2_loc -= 10;
        }
        p2_score += p2_loc;
        if (p2_score >= 1000) {
            std.debug.print("p2 wins: {}\n", .{p1_score * total_rolls});
            break;
        }
    }
}
