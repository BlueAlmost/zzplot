const std = @import("std");

const Self = @This();

idx: usize = 0, // index of oldest sample in circular buffer

phi0: f32 = 0, // phase of oscillator at time of sample generation
phi1: f32 = 0, // phase of oscillator at time of sample generation
phi2: f32 = 0, // phase of oscillator at time of sample generation
phi3: f32 = 0, // phase of oscillator at time of sample generation

delta_phi0: f32 = undefined, // phase increment
delta_phi1: f32 = undefined, // phase increment
delta_phi2: f32 = undefined, // phase increment
delta_phi3: f32 = undefined, // phase increment

circ_buff: []f32 = undefined, // cirular buffer

pub fn init(allocator: std.mem.Allocator, len: usize, delta_phi0: f32, delta_phi1: f32, delta_phi2: f32, delta_phi3: f32) !Self {
    const circ_buff = try allocator.alloc(f32, len);
    @memset(circ_buff, 0.0);

    return Self{ .delta_phi0 = delta_phi0, .delta_phi1 = delta_phi1, .delta_phi2 = delta_phi2, .delta_phi3 = delta_phi3, .circ_buff = circ_buff };
}

pub fn next(self: *Self) void {

    // generates next value of oscillator output
    // replacing the oldest value of the circular buffer

    // upon returning, the idx points to the oldest sample
    // in the buffer

    self.circ_buff[self.idx] = @sin(self.phi0) + (0.53 + 0.1 * self.delta_phi0) * @sin(self.phi1) - 0.321 * @sin(self.phi2) + 0.18 * @sin(self.phi3);

    self.idx = @mod(self.idx + 1, self.circ_buff.len);
    self.phi0 += self.delta_phi0 + 0.002 * self.phi1;
    self.phi1 += self.delta_phi1;
    self.phi2 += self.delta_phi2 - 0.001 * self.phi3;
    self.phi3 += self.delta_phi3;
}

pub fn read(self: *Self, x: []f32) void {

    // reads out the contents of the circular buffer
    // in chronological order, storing in slice x

    var i: usize = 0;
    while (i < self.circ_buff.len) : (i += 1) {
        x[i] = self.circ_buff[@mod(i + self.idx, self.circ_buff.len)];
    }
}
