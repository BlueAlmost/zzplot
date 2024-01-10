const std = @import("std");
const print = std.debug.print;

pub const genSignals = @import("genSignals.zig").genSignals;

pub const zzplot = @import("zzplot_import_name");
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

    // create two figure windows
    const fig1 = try Figure.init(allocator, shared, vg, .{
        .name = "First Window",
        .title_str = "First Figure",
        .col = Color.brighten(Color.green, 0.4),
        .xpos = 80,
        .ypos = 80,
        .wid = 700,
        .ht = 500,
    });

    const fig2 = try Figure.init(allocator, shared, vg, .{
        .name = "Second Window",
        .title_str = "Second Figure",
        .col = Color.brighten(Color.orange, 0.4),
        .xpos = 860,
        .ypos = 80,
        .wid = 700,
        .ht = 500,
    });

    const ax1 = try Axes.init(fig1, .{
        .title_str = "signal set 1",
        .draw_box = true,
        .box_bg_col = Color.brighten(Color.blue, 0.2),
        .xlabel_str = "time (ns)",
        .ylabel_str = "volts",
        .draw_grid = true,
    });

    const ax2 = try Axes.init(fig2, .{
        .title_str = "signal set 2",
        .draw_box = true,
        .box_bg_col = Color.brighten(Color.xkcd.tan_green, 0.7),
        .xlabel_str = "time (ms)",
        .ylabel_str = "amps",
        .draw_grid = true,
    });

    // u and v will be plotted on the first axes
    const plt_u = try Plot.init(ax1, .{
        .line_col = Color.orange,
        .line_width = 4,
    });

    const plt_v = try Plot.init(ax1, .{
        .line_col = Color.xkcd.light_lavendar,
        .line_width = 2,
    });

    // x and y will be plotted on the second axes
    const plt_x = try Plot.init(ax2, .{
        .line_col = Color.brighten(Color.xkcd.navy_blue, 0.3),
        .line_width = 2,
    });

    const plt_y = try Plot.init(ax2, .{
        .line_col = Color.brighten(Color.xkcd.brick_orange, 0.2),
        .line_width = 2,
    });

    // we can set axis limits based on values of data using set_limits
    // minMax will find min and max values over an arbitrary number of slices
    ax1.set_limits(minMax(f32, .{t}), minMax(f32, .{ u, v }), .{});
    ax2.set_limits(minMax(f32, .{t}), minMax(f32, .{ x, y }), .{});

    while ((fig1.live) or (fig2.live)) {
        fig1.begin();

        ax1.draw();
        plt_u.plot(t, u);
        plt_v.plot(t, v);

        fig1.end();

        fig2.begin();

        ax2.draw();
        plt_x.plot(t, x);
        plt_y.plot(t, y);

        fig2.end();
    }

    c.glfwTerminate();
}
