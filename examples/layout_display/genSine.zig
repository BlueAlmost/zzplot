const std = @import("std");
const math = std.math;

pub fn genSine(t: []f32, x: []f32) !void {
    const n_pts = t.len;

    var i: usize = 0;
    while (i < n_pts) : (i += 1) {
        t[i] = 4 * math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(n_pts));
        x[i] = 9.73 * math.sin(1.63 * t[i]);
    }
}
