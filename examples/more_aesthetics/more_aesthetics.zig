const std = @import("std");
const print = std.debug.print;

pub const genSine = @import("genSine.zig").genSine;

pub const zzplot = @import("zzplot_import_name");
pub const nvg = zzplot.nanovg;

pub const Figure = zzplot.Figure;
pub const Axes = zzplot.Axes;
pub const Plot = zzplot.Plot;

pub const Color = zzplot.Color;
pub const Marker = zzplot.PlotAes.Marker;

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
    const n_pts = 120;
    const t: []f32 = try allocator.alloc(f32, n_pts);
    const x: []f32 = try allocator.alloc(f32, n_pts);
    try genSine(t, x);

    // nvg context creation goes after gladLoadGL
    const vg = try nvg.gl.init(allocator, .{
        .debug = true,
    });

    zzplot.Font.init(vg);
    // defer vg.deinit();  // DO NOT UNCOMMENT THIS LINE, WILL GIVE ERROR UPON EXIT

    const fig = try Figure.init(allocator, shared, vg, .{
        .col = Color.brighten(Color.xkcd.steel_grey, 0.7),
        .wid = 900,
        .ht = 760,
        .title_str = "Coloring and aesthetics options example",
        .title_col = Color.xkcd.prussian_blue,
    });

    const ax = try Axes.init(fig, .{
        .draw_border = true,
        .border_fg_col = Color.orange,
        .border_line_width = 7,
        .border_bg_col = Color.xkcd.ivory,

        .draw_box = true,
        .box_line_width = 7,
        .box_fg_col = Color.xkcd.darker_blue,
        .box_bg_col = Color.xkcd.off_blue,

        .draw_grid = true,
        .grid_col = Color.xkcd.silver,

        .ticks_col = Color.xkcd.faded_red,
        .ticks_line_width = 4,
        .ticks_len_px = 15,
        .ticks_grid_space_px = 6,
        .title_str = "sine wave",
        .title_font_size = 22,
        .title_col = Color.orange,
        .xlabel_str = "time",
        .ylabel_str = "volts",
        .label_col = Color.purple,
        .label_font_size = 22,
    });

    const plt = try Plot.init(ax, .{
        // .line_col = Color.opacity(Color.xkcd.light_teal, 0.5),
        .line_col = Color.opacity(Color.xkcd.hunter_green, 0.5),
        .line_width = 12,
        .marker = Marker.circleFilled,
        .marker_col = Color.white,
        .marker_size = 20,
    });

    ax.set_limits(.{ 0, 9 }, .{ -10, 10 }, .{});

    while (fig.live) {
        fig.begin();

        ax.draw();
        plt.plot(t, x);

        fig.end();
    }

    c.glfwTerminate();
}
