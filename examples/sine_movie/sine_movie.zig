const std = @import("std");
const print = std.debug.print;

pub const genSine = @import("genSine.zig").genSine;

pub const zzplot = @import("zzplot_import_name");
pub const nvg = zzplot.nanovg;

pub const Figure = zzplot.Figure;
pub const Axes = zzplot.Axes;
pub const Plot = zzplot.Plot;
pub const Color = zzplot.Color;

pub const OscBuf = @import("OscBuf.zig");
pub const Osc4Buf = @import("Osc4Buf.zig");

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
    var t: []f32 = try allocator.alloc(f32, n_pts);
    for (t, 0..) |_, i| {
        t[i] = @as(f32, @floatFromInt(i));
    }
    const x: []f32 = try allocator.alloc(f32, n_pts);
    // var osc = try OscBuf.init(allocator, n_pts, 0.03);
    var osc = try Osc4Buf.init(allocator, n_pts, 0.03, 0.14, 0.213, 0.01);

    // nvg context creation goes after gladLoadGL
    const vg = try nvg.gl.init(allocator, .{
        .antialias = true,
        .stencil_strokes = true, //false=faster, true=better quality
        .debug = true,
    });

    zzplot.Font.init(vg);
    // defer vg.deinit();  // DO NOT UNCOMMENT THIS LINE, WILL GIVE ERROR UPON EXIT

    var fig = try Figure.init(allocator, shared, vg, .{
        .disp_fps = true,
        .col = Color.brighten(Color.xkcd.steel_grey, 0.7),
    });

    var ax = try Axes.init(fig, .{
        .draw_border = true,
        .border_fg_col = Color.brighten(Color.xkcd.stormy_blue, -0.6),
        .border_line_width = 5,
        .border_bg_col = Color.brighten(Color.xkcd.steel_grey, -0.4),

        .draw_box = true,
        .box_line_width = 7,
        .box_fg_col = Color.brighten(Color.xkcd.darker_blue, -0.8),
        .box_bg_col = Color.black,

        .draw_grid = true,
        .grid_col = Color.xkcd.silver,
    });

    var plt = try Plot.init(ax, .{
        .line_width = 3,
        .line_col = Color.opacity(Color.xkcd.light_neon_green, 0.5),
    });

    ax.set_limits(.{ 0, n_pts - 1 }, .{ -3, 3 }, .{});

    while (fig.live) {
        fig.begin();

        ax.draw();

        osc.next();
        osc.next();
        osc.next();
        osc.read(x);
        plt.plot(t, x);

        fig.end();
    }

    c.glfwTerminate();
}
