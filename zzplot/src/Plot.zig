const std = @import("std");
const zzplot = @import("zzplot_import_name");
const nvg = @import("nanovg");

const Allocator = std.mem.Allocator;
const print = std.debug.print;

pub const Color = zzplot.Color;
pub const Axes = zzplot.Axes;

const float = zzplot.float;
const isInt = zzplot.isInt;
const cpToUTF8 = zzplot.cpToUTF8;

pub const Aes = @import("PlotAesthetic.zig");
const TextAes = zzplot.TextAes;

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub const Plot = struct {
    const Self = @This();

    allocator: Allocator = undefined,
    axes: *Axes = undefined,
    window: ?*c.GLFWwindow = null,
    vg: nvg = undefined,

    aes: Aes,

    pub fn init(axes: *Axes, aes: Aes) !*Plot {
        var plt = try axes.allocator.create(Plot);

        plt.allocator = axes.allocator;
        plt.axes = axes;
        plt.window = axes.window;
        plt.vg = axes.vg;
        plt.aes = aes;

        return plt;
    }

    pub fn plot(self: *Self, x: []f32, y: []f32) void {
        const x_min = self.axes.aes.xlim[0];
        const x_max = self.axes.aes.xlim[1];
        const x_range = x_max - x_min;

        const y_min = self.axes.aes.ylim[0];
        const y_max = self.axes.aes.ylim[1];
        const y_range = y_max - y_min;

        var i: usize = 0;

        var x_normal: f32 = (x[i] - x_min) / x_range;
        var x_tmp: f32 = self.axes.xpos_axes_fb + x_normal * self.axes.wid_axes_fb;

        var y_normal: f32 = (y[i] - y_min) / y_range;
        var y_tmp: f32 = self.axes.ypos_axes_fb - y_normal * self.axes.ht_axes_fb;

        // I would have thought "scissor" could be used with a negative height, just as "rect",
        // so here it was planned to use:
        //
        // vg.scissor(self.xpos_axes_fb, self.ypos_axes_fb, self.wid_axes_fb, -self.ht_axes_fb);
        //
        // But, the negative height causes improper functioning.  So, instead just moved the first
        // corner "up the screen" by the needed amount, and then use a positive height.

        self.vg.save();

        self.vg.scissor(self.axes.xpos_axes_fb, self.axes.ypos_axes_fb - self.axes.ht_axes_fb, self.axes.wid_axes_fb, self.axes.ht_axes_fb);

        // line plot
        if (self.aes.line_style == Aes.LineStyle.solid) {
            self.vg.beginPath();
            self.vg.moveTo(x_tmp, y_tmp);
            i += 1;

            while (i < x.len) : (i += 1) {
                x_normal = (x[i] - x_min) / x_range;
                x_tmp = self.axes.xpos_axes_fb + x_normal * self.axes.wid_axes_fb;

                y_normal = (y[i] - y_min) / y_range;
                y_tmp = self.axes.ypos_axes_fb - y_normal * self.axes.ht_axes_fb;

                self.vg.lineTo(x_tmp, y_tmp);
            }

            self.vg.strokeColor(self.aes.line_col);
            self.vg.strokeWidth(self.aes.line_width);
            self.vg.stroke();
            self.vg.closePath();
        }

        if (self.aes.marker != Aes.Marker.none) {
            var icon: [8]u8 = undefined;
            self.vg.fontSize(self.aes.marker_size);
            self.vg.fillColor(self.aes.marker_col);

            i = 0;
            while (i < x.len) : (i += 1) {
                x_normal = (x[i] - x_min) / x_range;
                x_tmp = self.axes.xpos_axes_fb + x_normal * self.axes.wid_axes_fb;

                y_normal = (y[i] - y_min) / y_range;
                y_tmp = self.axes.ypos_axes_fb - y_normal * self.axes.ht_axes_fb;

                self.vg.fontFace("symbols");
                self.vg.textAlign(.{ .horizontal = .center, .vertical = .middle });
                _ = self.vg.text(x_tmp, y_tmp, cpToUTF8(@intFromEnum(self.aes.marker), &icon));
            }
        }
        self.vg.restore();
    }
};
