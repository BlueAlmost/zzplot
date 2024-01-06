const std = @import("std");
const print = std.debug.print;

const OscBuff = @import("OscBuf.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const phase_inc: f32 = 0.01;
    const len: usize = 10;

    var osc = try OscBuff.init(allocator, len, phase_inc);
    var output = try allocator.alloc(f32, len);

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        osc.next();
        osc.read(output);

        print("output: ", .{});
        for (output) |out| {
            print("{d:6.3} ", .{out});
        }
        print("\n", .{});
        print("\n", .{});
    }
}
