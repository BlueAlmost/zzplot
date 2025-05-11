const std = @import("std");
const print = std.debug.print;

pub const genSine = @import("genSine.zig").genSine;

pub const zzplot = @import("zzplot_import_name");
pub const nvg = zzplot.nanovg;

pub const Figure = zzplot.Figure;
pub const Axes = zzplot.Axes;
pub const Plot = zzplot.Plot;
pub const PlotAes = zzplot.PlotAes;
pub const Color = zzplot.Color;

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

    var fig = try Figure.init(allocator, shared, vg, .{
        .title_str = "layout guide information",
        .grid = true,
        .border_px = 60,
        .col = Color.brighten(Color.blue, 0.8),
    });

    var ax = try Axes.init(fig, .{
        .border_px = 75,
        .draw_border = true,
        .border_line_width = 3,
        .border_fg_col = Color.orange,
        .border_bg_col = Color.brighten(Color.orange, 0.85),
        .draw_box = true,
        .box_line_width = 3,
        .box_fg_col = Color.green,
        .box_bg_col = Color.brighten(Color.green, 0.85),
        .title_str = "sine wave",
        .xlabel_str = "time",
        .xlabel_offset = 27,
        .ylabel_str = "volts",
    });

    var plt = try Plot.init(ax, .{});

    ax.set_limits(.{ 0, 9 }, .{ -10, 10 }, .{});

    while (fig.live and 0 == c.glfwWindowShouldClose(@ptrCast(fig.window))) {
        const fs = 24;
        const lw = 5;
        const ms = 55;

        fig.begin();

        const fig_top = 1.0 - @as(f32, @floatFromInt(fig.aes.border_px)) / fig.aes.ht;
        const fig_right = 1.0 - @as(f32, @floatFromInt(fig.aes.border_px)) / fig.aes.wid;

        const fig_left = @as(f32, @floatFromInt(fig.aes.border_px)) / fig.aes.wid;
        const fig_bot = @as(f32, @floatFromInt(fig.aes.border_px)) / fig.aes.ht;

        fig.text(1.1 * fig_left, 0.5 * fig_bot, .{ .str = "fig.border_px (constant # pixels)", .font_size = fs, .col = Color.blue, .alignment = .{ .vertical = .middle } });

        fig.lineSegment(.{ fig_left, fig_left }, .{ 0.0, fig_bot }, .{
            .line_col = Color.blue,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.blue,
            .marker_size = ms,
        });

        fig.lineSegment(.{ 0, fig_left }, .{ fig_bot, fig_bot }, .{
            .line_col = Color.blue,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.blue,
            .marker_size = ms,
        });

        // #######################################################################

        ax.draw();
        plt.plot(t, x);

        // #######################################################################

        const ax_top = 1.0 - @as(f32, @floatFromInt(fig.aes.border_px + ax.aes.border_px)) / fig.aes.ht;
        const ax_bot = @as(f32, @floatFromInt(fig.aes.border_px + ax.aes.border_px)) / fig.aes.ht;
        const ax_right = 1.0 - @as(f32, @floatFromInt(fig.aes.border_px + ax.aes.border_px)) / fig.aes.wid;

        fig.text(0.99 * (ax_right), 0.5 * (ax_top + fig_top), .{ .str = "axes.border_px", .font_size = fs, .col = Color.orange, .alignment = .{ .horizontal = .right, .vertical = .middle } });

        fig.lineSegment(.{ ax_right, ax_right }, .{ ax_top, fig_top }, .{
            .line_col = Color.orange,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.orange,
            .marker_size = ms,
        });

        fig.lineSegment(.{ ax_right, fig_right }, .{ ax_top, ax_top }, .{
            .line_col = Color.orange,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.orange,
            .marker_size = ms,
        });

        fig.text(0.46, 0.40 * (ax_bot + fig_bot), .{ .str = "xlabel_offset", .font_size = 0.7 * fs, .col = Color.brighten(Color.black, 0.6), .alignment = .{ .horizontal = .right, .vertical = .middle } });

        fig.lineSegment(.{ 0.47, 0.47 }, .{ 0.465 * (ax_bot + fig_bot), fig_bot }, .{
            .line_col = Color.brighten(Color.black, 0.6),
            .line_width = 0.6 * lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.brighten(Color.black, 0.6),
            .marker_size = 0.3 * ms,
        });

        fig.end();
    }

    c.glfwTerminate();
}
