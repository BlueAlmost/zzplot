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
        .border_px_top = 120,
        .border_px_bot = 55,
        .border_px_left = 80,
        .border_px_right = 45,
        .col = Color.brighten(Color.blue, 0.8),
    });

    var ax = try Axes.init(fig, .{
        .border_px_top = 70,
        .border_px_bot = 50,
        .border_px_left = 120,
        .border_px_right = 90,
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
        .ylabel_str = "volts",
    });

    var plt = try Plot.init(ax, .{});

    ax.set_limits(.{ 0, 9 }, .{ -10, 10 }, .{});

    while (fig.live and 0 == c.glfwWindowShouldClose(@ptrCast(fig.window))) {
        const fs = 24;
        const lw = 5;
        const ms = 55;

        fig.begin();

        const fig_top = 1.0 - @as(f32, @floatFromInt(fig.aes.border_px_top.?)) / fig.aes.ht;
        const fig_bot = @as(f32, @floatFromInt(fig.aes.border_px_bot.?)) / fig.aes.ht;
        const fig_left = @as(f32, @floatFromInt(fig.aes.border_px_left.?)) / fig.aes.wid;
        const fig_right = 1.0 - @as(f32, @floatFromInt(fig.aes.border_px_right.?)) / fig.aes.wid;

        fig.text(3.4 * fig_left, 0.5 * fig_bot, .{ .str = "fig.border_px_bot (constant # pixels)", .font_size = fs, .col = Color.blue, .alignment = .{ .vertical = .middle } });

        fig.lineSegment(.{ 3.3 * fig_left, 3.3 * fig_left }, .{ 0.0, fig_bot }, .{
            .line_col = Color.blue,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.blue,
            .marker_size = ms,
        });

        fig.text(0.5 * fig_left, 3.3 * fig_bot, .{ .str = "fig.border_px_left", .font_size = fs, .col = Color.blue, .rotation = -std.math.pi / 2.0, .alignment = .{ .vertical = .middle } });

        fig.lineSegment(.{ 0, fig_left }, .{ 3.2 * fig_bot, 3.2 * fig_bot }, .{
            .line_col = Color.blue,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.blue,
            .marker_size = ms,
        });

        fig.text(0.81 * fig_right, 0.5 * (1 + fig_top), .{ .str = "fig.border_px_top", .font_size = fs, .col = Color.blue, .alignment = .{ .horizontal = .right, .vertical = .middle } });

        fig.lineSegment(.{ 0.82 * fig_right, 0.82 * fig_right }, .{ fig_top, 1.0 }, .{
            .line_col = Color.blue,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.blue,
            .marker_size = ms,
        });

        fig.text(0.5 * (1 + fig_right), 0.76 * (fig_top), .{ .str = "fig.border_px_right", .font_size = fs, .col = Color.blue, .rotation = std.math.pi / 2.0, .alignment = .{ .horizontal = .left, .vertical = .middle } });

        fig.lineSegment(.{ fig_right, 1.0 }, .{ 0.79 * fig_top, 0.79 * fig_top }, .{
            .line_col = Color.blue,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.blue,
            .marker_size = ms,
        });

        ax.draw();
        plt.plot(t, x);

        const ax_left = @as(f32, @floatFromInt(fig.aes.border_px_left.? + ax.aes.border_px_left.?)) / fig.aes.wid;
        const ax_bot = @as(f32, @floatFromInt(fig.aes.border_px_bot.? + ax.aes.border_px_bot.?)) / fig.aes.ht;

        fig.text(1.15 * ax_left, 0.5 * (ax_bot + fig_bot), .{ .str = "axes.border_px_bot (constant # pixels)", .font_size = fs, .col = Color.orange, .alignment = .{ .vertical = .middle } });

        fig.lineSegment(.{ 1.1 * ax_left, 1.1 * ax_left }, .{ fig_bot, ax_bot }, .{
            .line_col = Color.orange,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.orange,
            .marker_size = ms,
        });

        fig.text(0.5 * (fig_left + ax_left), 1.3 * ax_bot, .{ .str = "axes.border_px_left", .font_size = fs, .col = Color.orange, .rotation = -std.math.pi / 2.0, .alignment = .{ .vertical = .middle } });
        fig.lineSegment(.{ fig_left, ax_left }, .{ 1.25 * ax_bot, 1.25 * ax_bot }, .{
            .line_col = Color.orange,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.orange,
            .marker_size = ms,
        });

        const ax_top = 1.0 - @as(f32, @floatFromInt(fig.aes.border_px_top.? + ax.aes.border_px_top.?)) / fig.aes.ht;
        const ax_right = 1.0 - @as(f32, @floatFromInt(fig.aes.border_px_right.? + ax.aes.border_px_right.?)) / fig.aes.wid;

        fig.text(0.95 * (ax_right), 0.5 * (ax_top + fig_top), .{ .str = "axes.border_px_top", .font_size = fs, .col = Color.orange, .alignment = .{ .horizontal = .right, .vertical = .middle } });

        fig.lineSegment(.{ 0.97 * ax_right, 0.97 * ax_right }, .{ ax_top, fig_top }, .{
            .line_col = Color.orange,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.orange,
            .marker_size = ms,
        });

        fig.text(0.5 * (ax_right + fig_right), 0.94 * ax_top, .{ .str = "axes.border_px_right", .font_size = fs, .col = Color.orange, .rotation = std.math.pi / 2.0, .alignment = .{ .vertical = .middle } });

        fig.lineSegment(.{ ax_right, fig_right }, .{ 0.96 * ax_top, 0.96 * ax_top }, .{
            .line_col = Color.orange,
            .line_width = lw,
            .marker = PlotAes.Marker.diamondFilled,
            .marker_col = Color.orange,
            .marker_size = ms,
        });

        fig.end();
    }
    c.glfwTerminate();
}
