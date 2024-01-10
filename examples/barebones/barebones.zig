const std = @import("std");
const print = std.debug.print;

pub const genSine = @import("genSine.zig").genSine;

pub const zzplot = @import("zzplot_import_name");
pub const nvg = zzplot.nanovg;

pub const Figure = zzplot.Figure;
pub const Axes = zzplot.Axes;
pub const Plot = zzplot.Plot;

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const shared = try zzplot.createShared();

    // generate data for plotting
    const n_pts = 500;
    const t: []f32 = try allocator.alloc(f32, n_pts);
    const x: []f32 = try allocator.alloc(f32, n_pts);
    try genSine(t, x);

    // nvg context creation goes after gladLoadGL
    const vg = try nvg.gl.init(allocator, .{
        .debug = true,
    });

    zzplot.Font.init(vg);
    // defer vg.deinit();  // DO NOT UNCOMMENT THIS LINE, WILL GIVE ERROR UPON EXIT

    const fig = try Figure.init(allocator, shared, vg, .{});
    const ax = try Axes.init(fig, .{});
    const plt = try Plot.init(ax, .{});

    ax.set_limits(.{ 0, 9 }, .{ -10, 10 }, .{});

    while (fig.live) {
        fig.begin();

        ax.draw();
        plt.plot(t, x);

        fig.end();
    }

    c.glfwTerminate();
}
