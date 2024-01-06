const std = @import("std");
const math = std.math;

pub fn genSignals(t: []f32, u: []f32, v: []f32, x: []f32, y: []f32) !void {
    const n_pts = t.len;

    var i: usize = 0;
    while (i < n_pts) : (i += 1) {
        t[i] = math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(n_pts));

        u[i] = 9.7 * math.sin(10.6 * t[i] - 0.3);
        v[i] = 7.3 * t[i] * math.sin(3.1 * t[i] + 1.2);
        x[i] = 4.3 * math.sin(10.6 * t[i] + 0.3);
        y[i] = 0.06 * (2.1 * math.sin(18.6 * t[i] - 0.2) * 3.2 * x[i] * x[i]);
    }
}
