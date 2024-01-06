const std = @import("std");
const print = std.debug.print;
const math = std.math;

pub const Ticks = @This();
const Self = @This();

pub const Algo = enum {
    wilkinson,
    extended,
};

pub const Aes = struct {
    algo: Algo = Algo.extended,
    m_target: usize = 7,
    only_loose: bool = false,
};

// pub const Ticks = struct {

min: f32, // min tick value
max: f32, // max tick value
inc: f32, // tick increment
aes: Aes,

pub fn get(lim: [2]f32, aes: Aes) Ticks {
    switch (aes.algo) {
        .extended => {
            var tick = extended(lim[0], lim[1], aes);
            if (tick.min < lim[0]) tick.min = tick.min + tick.inc;
            if (tick.max > lim[1]) tick.max = tick.max - tick.inc;
            return tick;
        },

        .wilkinson => {
            var tick = wilkinson(lim[0], lim[1], aes);
            if (tick.min < lim[0]) tick.min = tick.min + tick.inc;
            if (tick.max > lim[1]) tick.max = tick.max - tick.inc;
            return tick;
        },
    }
}

pub fn display(self: *Self) void {
    var t: f32 = self.min;

    print("\n", .{});
    while (t <= self.max) : (t += self.inc) {
        print(" {d:6}", .{t});
    }
    print("\n", .{});
}

fn float(i: usize) f32 {
    return @as(f32, @floatFromInt(i));
}

fn simplicity(i: usize, j: usize, n: usize, l_min: f32, l_max: f32, l_step: f32) f32 {
    const eps = math.floatEps(f32) * 100;
    const quo: f32 = l_min / l_step;
    const rem: f32 = l_min - l_step * quo;
    const v: f32 = if (((rem < eps) or ((l_step - rem) < eps)) and (l_min <= 0) and (l_max >= 0)) 1 else 0;

    return 1 - (float(i) - 1) / (float(n) - 1) - float(j) + v;
}

fn simplicityMax(i: usize, j: usize, n: usize) f32 {
    const v: usize = 1;
    return 1 - (float(i) - 1) / (float(n) - 1) - float(j) + float(v);
}

fn coverage(d_min: f32, d_max: f32, l_min: f32, l_max: f32) f32 {
    const range: f32 = d_max - d_min;
    const dl_max: f32 = d_max - l_max;
    const dl_min: f32 = d_min - l_min;

    return 1 - 0.5 * (dl_max * dl_max + dl_min * dl_min) / (0.01 * range * range);
}

fn coverageMax(d_min: f32, d_max: f32, span: f32) f32 {
    const range: f32 = d_max - d_min;
    if (span > range) {
        const half: f32 = 0.5 * (span - range);

        return 1 - 0.5 * (half * half + half * half) / (0.1 * range * range);
    } else {
        return 1;
    }
}

fn density(k: usize, m_target: usize, d_min: f32, d_max: f32, l_min: f32, l_max: f32) f32 {
    const r: f32 = (float(k) - 1) / (l_max - l_min);
    const rt: f32 = (float(m_target) - 1) / (@max(l_max, d_max) - @min(d_min, l_min));

    return 2 - @max(r / rt, rt / r);
}

fn densityMax(k: usize, m_target: usize) f32 {
    if (k >= m_target) {
        return 2 - (float(k) - 1) / (float(m_target) - 1);
    } else {
        return 1;
    }
}

// pub fn extended(d_min: f32, d_max: f32, m_target: usize, only_loose: bool) Ticks {
pub fn extended(d_min: f32, d_max: f32, aes: Aes) Ticks {
    const m_target = aes.m_target;
    const only_loose = aes.only_loose;

    // Ref: "An Extension of Wilkinson's Algorithm for Positioning
    // Ticks Labels on Axes", Talbot, Lin, Hanrahan.

    // const only_loose: bool = false;  // if true, the extreme labels will be outside the data range
    const Q = [_]f32{ 1, 5, 2, 2.5, 4, 3 };
    const w = [_]f32{ 0.25, 0.2, 0.5, 0.05 };
    const MaxIter = 1000;

    // const eps = math.epsilon(f32)*100;
    const eps = math.floatEps(f32) * 100;

    if (((d_max - d_min) < eps) or ((d_max - d_min) > math.sqrt(math.floatMax(f32)))) {
        // if too close or too far apart, generate equally spaced steps
        const t_delta: f32 = (d_max - d_min) / float(m_target);
        return Ticks{
            .min = d_min,
            .max = d_max,
            .inc = t_delta,
            .aes = aes,

            // .algo = Algo.extended,
        };
    }

    var l_min_best: f32 = undefined;
    var l_max_best: f32 = undefined;
    var l_step_best: f32 = undefined;

    var score_best: f32 = -2;

    var score: f32 = undefined;
    var sm: f32 = undefined;

    var j: usize = 1;

    while (j < MaxIter) {
        for (Q, 0..) |q, i| {
            sm = simplicityMax(i, j, Q.len);

            if (w[0] * sm + w[1] + w[2] + w[3] < score_best) {
                j = MaxIter;
                break;
            }

            var k: usize = 2;
            while (k < MaxIter) {
                const dm = densityMax(k, m_target);

                if (w[0] * sm + w[1] + w[2] * dm + w[3] < score_best) {
                    break;
                }

                const delta: f32 = (d_max - d_min) / (float(k) + 1) / float(j) / q;
                var z: f32 = @ceil(@log10(delta));

                while (z < MaxIter) {
                    const step: f32 = float(j) * q * math.pow(f32, 10, z);

                    const cm = coverageMax(d_min, d_max, step * (float(k) - 1));

                    if (w[0] * sm + w[1] * cm + w[2] * dm + w[3] < score_best) {
                        break;
                    }

                    const tmp: f32 = @floor(d_max / step) * float(j) - (float(k) - 1.0) * float(j);
                    const min_start: i32 = @as(i32, @intFromFloat(tmp));
                    const max_start: i32 = @as(i32, @intFromFloat(@ceil(d_min / step))) * @as(i32, @intCast(j));

                    if (min_start <= max_start) {
                        var start: i32 = min_start;
                        while (start <= max_start) : (start += 1) {
                            const l_min: f32 = @as(f32, @floatFromInt(start)) * step / float(j);
                            const l_max: f32 = l_min + step * (float(k) - 1);
                            const l_step: f32 = step;

                            const s = simplicity(i, j, Q.len, l_min, l_max, l_step);

                            const c = coverage(d_min, d_max, l_min, l_max);

                            const g = density(k, m_target, d_min, d_max, l_min, l_max);

                            // legibility not used (set to 1)

                            score = s * w[0] + c * w[1] + g * w[2] + w[3];

                            if ((score > score_best) and (!only_loose or ((l_min <= d_min) and (l_max >= d_max)))) {
                                l_min_best = l_min;
                                l_max_best = l_max;
                                l_step_best = l_step;

                                score_best = score;
                            }
                        }
                    }
                    z += 1;
                }
                k += 1;
            }
        }
        j += 1;
    }

    return Ticks{
        .min = l_min_best,
        .max = l_max_best,
        .inc = l_step_best,
        .aes = aes,

        // .algo = Algo.extended,
    };
}

pub fn wilkinson(d_min: f32, d_max: f32, aes: Aes) Ticks {
    const m_target = aes.m_target;

    // Wilkinson's Algorithm.  See "Grammar of Graphics", page 107.
    // code here based on R's "labeling" library

    // const Q = [_]f32{1, 1.5, 2, 2.5, 3, 4, 5, 6, 7, 8, 9, 10};

    const Q = [_]f32{ 10, 1, 5, 2, 2.5, 3, 4, 1.5, 7, 6, 8, 9 };
    const m_min: usize = @max(m_target / 2, 2);
    const m_max: usize = 6 * m_target;
    const d_range: f32 = d_max - d_min;
    const cov_min: f32 = 0.8; // "R labeling package" uses 0.8

    // scoring three components (simplicity, granularity, coverage)
    var simp: f32 = undefined;
    var gran: f32 = undefined;
    var cov: f32 = undefined;

    var t_min_best: f32 = undefined;
    var t_max_best: f32 = undefined;
    var t_delta_best: f32 = undefined;

    var score_best: f32 = 0;

    var k: usize = m_min;
    while (k <= m_max) : (k += 1) {
        gran = 1 - @abs(float(k) - float(m_target)) / float(m_target);

        const delta: f32 = d_range / (float(k) - 1);
        const base: f32 = @floor(@log10(delta));
        const d_base: f32 = math.pow(f32, 10, base);
        var v: usize = undefined;

        for (Q, 0..) |q, i| {
            const t_delta: f32 = q * d_base;
            const t_min: f32 = @floor(d_min / t_delta) * t_delta;
            const t_max: f32 = t_min + (float(k) - 1) * t_delta;

            if ((t_min <= d_min) and (t_max >= d_max)) {
                if ((t_min <= 0) and (t_max >= 0)) v = 1 else v = 0;

                simp = 1 - float(i) / float(Q.len) + float(v) / float(Q.len);
                cov = (d_max - d_min) / (t_max - t_min);

                const score: f32 = gran + simp + cov;

                if ((cov > cov_min) and (score > score_best)) {
                    t_min_best = t_min;
                    t_max_best = t_max;
                    t_delta_best = t_delta;

                    score_best = score;
                }
            }
        }
    }

    return Ticks{
        .min = t_min_best,
        .max = t_max_best,
        .inc = t_delta_best,
        .aes = aes,
    };
}

test {
    const d_min: f32 = 11123;
    const d_max: f32 = 13553;
    const m_target: usize = 7;
    const only_loose: bool = false;

    const ticks = Ticks.extended(d_min, d_max, m_target, only_loose);

    try std.testing.expectEqual(ticks.min, 11000);
    try std.testing.expectEqual(ticks.max, 13500);
    try std.testing.expectEqual(ticks.inc, 500);
}

test {
    const d_min: f32 = -123;
    const d_max: f32 = 553;
    const m_target: usize = 7;
    const only_loose: bool = false;

    var ticks = Ticks.extended(d_min, d_max, m_target, only_loose);

    ticks.display();

    try std.testing.expectEqual(ticks.min, -100);
    try std.testing.expectEqual(ticks.max, 500);
    try std.testing.expectEqual(ticks.inc, 100);
}

test {
    const d_min: f32 = -1023;
    const d_max: f32 = 553;
    const m_target: usize = 7;
    const only_loose: bool = false;

    var ticks = Ticks.extended(d_min, d_max, m_target, only_loose);

    ticks.display();

    try std.testing.expectEqual(ticks.min, -1000);
    try std.testing.expectEqual(ticks.max, 500);
    try std.testing.expectEqual(ticks.inc, 250);
}

test {
    const d_min: f32 = -1023;
    const d_max: f32 = 553;
    const m_target: usize = 7;
    const only_loose: bool = true;

    var ticks = Ticks.extended(d_min, d_max, m_target, only_loose);

    ticks.display();

    try std.testing.expectEqual(ticks.min, -1200);
    try std.testing.expectEqual(ticks.max, 600);
    try std.testing.expectEqual(ticks.inc, 300);
}

test {
    const d_min: f32 = 11123;
    const d_max: f32 = 13553;
    const m_target: usize = 7;

    const ticks = Ticks.wilkinson(d_min, d_max, m_target);

    try std.testing.expectEqual(ticks.min, 11000);
    try std.testing.expectEqual(ticks.max, 14000);
    try std.testing.expectEqual(ticks.inc, 500);
}

test {
    const d_min: f32 = -123;
    const d_max: f32 = 553;
    const m_target: usize = 11;

    var ticks = Ticks.wilkinson(d_min, d_max, m_target);
    ticks.display();

    try std.testing.expectEqual(ticks.min, -200);
    try std.testing.expectEqual(ticks.max, 600);
    try std.testing.expectEqual(ticks.inc, 100);
}

test {
    const d_min: f32 = -123;
    const d_max: f32 = 553;
    const m_target: usize = 3;

    var ticks = Ticks.wilkinson(d_min, d_max, m_target);
    ticks.display();

    try std.testing.expectEqual(ticks.min, -200);
    try std.testing.expectEqual(ticks.max, 600);
    try std.testing.expectEqual(ticks.inc, 200);
}

test {
    const d_min: f32 = 723;
    const d_max: f32 = 1503;
    const m_target: usize = 5;

    var ticks = Ticks.wilkinson(d_min, d_max, m_target);
    ticks.display();

    try std.testing.expectEqual(ticks.min, 700);
    try std.testing.expectEqual(ticks.max, 1600);
    try std.testing.expectEqual(ticks.inc, 100);
}
