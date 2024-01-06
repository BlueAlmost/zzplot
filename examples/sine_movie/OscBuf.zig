const std = @import("std");

const Self = @This();

idx: usize = 0, // index of oldest sample in circular buffer
phi: f32 = 0, // phase of oscillator at time of sample generation
delta_phi: f32 = undefined, // phase increment
circ_buff: []f32 = undefined, // cirular buffer

pub fn init(allocator: std.mem.Allocator, len: usize, delta_phi: f32) !Self {
    const circ_buff = try allocator.alloc(f32, len);
    @memset(circ_buff, 0.0);

    return Self{ .delta_phi = delta_phi, .circ_buff = circ_buff };
}

pub fn next(self: *Self) void {

    // generates next value of oscillator output
    // replacing the oldest value of the circular buffer

    // upon returning, the idx points to the oldest sample
    // in the buffer

    self.circ_buff[self.idx] = @sin(self.phi);
    self.idx = @mod(self.idx + 1, self.circ_buff.len);
    self.phi += self.delta_phi;
}

pub fn read(self: *Self, x: []f32) void {

    // reads out the contents of the circular buffer
    // in chronological order, storing in slice x

    var i: usize = 0;
    while (i < self.circ_buff.len) : (i += 1) {
        x[i] = self.circ_buff[@mod(i + self.idx, self.circ_buff.len)];
    }
}
