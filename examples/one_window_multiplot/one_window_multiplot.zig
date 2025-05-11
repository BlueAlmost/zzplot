const std = @import("std");
const print = std.debug.print;

pub const genSignals = @import("genSignals.zig").genSignals;

pub const zzplot = @import("zzplot");
pub const nvg = zzplot.nanovg;

pub const Figure = zzplot.Figure;
pub const Axes = zzplot.Axes;
pub const Plot = zzplot.Plot;
pub const Color = zzplot.Color;

pub const minMax = zzplot.minMax;

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // generate data to plot
    const n_pts = 500;
    const t: []f32 = try allocator.alloc(f32, n_pts);
    const u: []f32 = try allocator.alloc(f32, n_pts);
    const v: []f32 = try allocator.alloc(f32, n_pts);
    const x: []f32 = try allocator.alloc(f32, n_pts);
    const y: []f32 = try allocator.alloc(f32, n_pts);
    try genSignals(t, u, v, x, y);

    // needed for when using multiple windows
    const shared = try zzplot.createShared();

    // nvg context creation goes after gladLoadGL
    const vg = try nvg.gl.init(allocator, .{
        .debug = true,
    });

    zzplot.Font.init(vg);
    // defer vg.deinit();  // DO NOT UNCOMMENT THIS LINE, WILL GIVE ERROR UPON EXIT

    // create figure with two sets of axes
    var fig = try Figure.init(allocator, shared, vg, .{
        .title_str = "Mulitple plots on multiple axes, with custom aesthetics",
        .xpos = 80,
        .ypos = 80,
        .wid = 960,
        .ht = 900,
        .disp_fps = true,
    });

    var ax1 = try Axes.init(fig, .{
        .ypos = 0.4,
        .ht = 0.6,
        .title_str = "signal set 1",
        .xlabel_str = "time (ns)",
        .ylabel_str = "volts",
        .draw_grid = true,
    });

    var ax2 = try Axes.init(fig, .{
        .ht = 0.4,
        .title_str = "signal set 2",
        .xlabel_str = "time (ms)",
        .ylabel_str = "amps",
    });

    // u and v will be plotted on the first axes
    var plt_u = try Plot.init(ax1, .{ .line_col = Color.opacity(Color.blue, 0.5), .line_width = 8 });

    var plt_v = try Plot.init(ax1, .{ .line_col = Color.opacity(Color.orange, 0.7) });

    // x and y will be plotted on the second axes
    var plt_x = try Plot.init(ax2, .{ .line_col = Color.opacity(Color.green, 0.7) });

    var plt_y = try Plot.init(ax2, .{ .line_col = Color.opacity(Color.purple, 0.7) });

    // we can set axis limits based on values of data using set_limits
    // minMax will find min and max values over an arbitrary number of slices
    ax1.set_limits(minMax(f32, .{t}), minMax(f32, .{ u, v }), .{});

    // the final argument of set_limits allows use of custom tick computation methods
    // here, setting m_targets allows denser ticks
    ax2.set_limits(minMax(f32, .{t}), minMax(f32, .{ x, y }), .{ .m_target = 18 });

    while (fig.live and 0 == c.glfwWindowShouldClose(@ptrCast(fig.window))) {
        fig.begin();

        ax1.draw();
        plt_u.plot(t, u);
        plt_v.plot(t, v);

        ax2.draw();
        plt_x.plot(t, x);
        plt_y.plot(t, y);

        fig.end();
    }

    c.glfwTerminate();
}
