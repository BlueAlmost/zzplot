const std = @import("std");
const zzplot = @import("zzplot");

const Color = zzplot.Color;

const Fig = zzplot.Fig;

const TextAes = zzplot.TextAes;

const int = zzplot.int;
const float = zzplot.float;
const isInt = zzplot.isInt;

const Allocator = std.mem.Allocator;
const print = std.debug.print;

const nvg = zzplot.nanovg;
const Figure = zzplot.Figure;
const Ticks = zzplot.Ticks;

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub const Aes = struct {
    xpos: f32 = 0.0,
    ypos: f32 = 0.0,
    wid: f32 = 1.0,
    ht: f32 = 1.0,

    xlim: [2]f32 = .{ 0, 1 },
    ylim: [2]f32 = .{ 0, 1 },

    border_px: u32 = 40,
    border_px_top: ?u32 = null,
    border_px_bot: ?u32 = null,
    border_px_left: ?u32 = null,
    border_px_right: ?u32 = null,

    draw_border: bool = false,
    border_line_width: f32 = 2,
    border_fg_col: nvg.Color = Color.black,
    border_bg_col: nvg.Color = Color.white,

    draw_box: bool = true,
    box_line_width: f32 = 1,
    box_fg_col: nvg.Color = Color.black,
    box_bg_col: nvg.Color = Color.none,

    draw_ticks: bool = true,
    ticks_line_width: f32 = 1,
    ticks_len_px: u32 = 5,
    ticks_col: nvg.Color = Color.black,
    xticks: ?Ticks = null,
    yticks: ?Ticks = null,
    ticks_grid_space_px: u32 = 2,
    ticks_font_size: f32 = 16,

    draw_grid: bool = false,
    grid_line_width: f32 = 1,
    grid_col: nvg.Color = Color.brighten(Color.black, 0.7),

    title_str: ?[]const u8 = null,
    title_offset: f32 = 3,
    title_font_face: [:0]const u8 = "sans",
    title_font_size: f32 = 19,
    title_col: nvg.Color = Color.black,

    xlabel_str: ?[]const u8 = null,
    xlabel_offset: f32 = 3,
    ylabel_str: ?[]const u8 = null,
    ylabel_offset: f32 = 3,
    label_font_size: f32 = 17,
    label_font_face: [:0]const u8 = "sans",
    label_col: nvg.Color = Color.black,
};

pub const Axes = struct {
    const Self = @This();

    allocator: Allocator = undefined,
    window: ?*c.GLFWwindow = null,
    vg: nvg = undefined,

    aes: Aes,

    fig_border_px_flt_top: f32 = undefined,
    fig_border_px_flt_bot: f32 = undefined,
    fig_border_px_flt_left: f32 = undefined,
    fig_border_px_flt_right: f32 = undefined,

    // positional fields - in fig border corrected frame buffer coordinates
    xpos_fb: f32 = undefined,
    ypos_fb: f32 = undefined,
    wid_fb: f32 = undefined,
    ht_fb: f32 = undefined,

    // axes positional fields - in fig border corrected frame buffer coordinates
    xpos_axes_fb: f32 = undefined,
    ypos_axes_fb: f32 = undefined,
    wid_axes_fb: f32 = undefined,
    ht_axes_fb: f32 = undefined,

    pub fn init(fig: *Figure, aes: Aes) !*Axes {

        // use defaults for base fields with simplified initializaiton
        var axes = try fig.allocator.create(Axes);

        axes.allocator = fig.allocator;
        axes.window = fig.window;
        axes.vg = fig.vg;

        axes.fig_border_px_flt_top = float(fig.aes.border_px_top orelse fig.aes.border_px);
        axes.fig_border_px_flt_bot = float(fig.aes.border_px_bot orelse fig.aes.border_px);
        axes.fig_border_px_flt_left = float(fig.aes.border_px_left orelse fig.aes.border_px);
        axes.fig_border_px_flt_right = float(fig.aes.border_px_right orelse fig.aes.border_px);

        axes.aes = aes;

        return axes;
    }

    pub fn updateSizeFields(self: *Self) void {
        var wid_fb_int: c_int = undefined;
        var ht_fb_int: c_int = undefined;

        c.glfwGetFramebufferSize(self.window, &wid_fb_int, &ht_fb_int);
        var wid_fb: f32 = float(@as(i32, @intCast(wid_fb_int)));
        wid_fb = wid_fb - self.fig_border_px_flt_left - self.fig_border_px_flt_right;

        var ht_fb: f32 = float(@as(i32, @intCast(ht_fb_int)));
        ht_fb = ht_fb - self.fig_border_px_flt_top - self.fig_border_px_flt_bot;

        self.wid_fb = self.aes.wid * wid_fb;
        self.ht_fb = self.aes.ht * ht_fb;

        self.xpos_fb = self.aes.xpos * wid_fb + self.fig_border_px_flt_left;
        self.ypos_fb = (1.0 - self.aes.ypos) * ht_fb + self.fig_border_px_flt_top;

        self.xpos_axes_fb = self.xpos_fb + float(self.aes.border_px_left orelse self.aes.border_px);
        self.ypos_axes_fb = self.ypos_fb - float(self.aes.border_px_bot orelse self.aes.border_px);

        self.wid_axes_fb = self.wid_fb - float((self.aes.border_px_left orelse self.aes.border_px) + (self.aes.border_px_right orelse self.aes.border_px));

        self.ht_axes_fb = self.ht_fb - float((self.aes.border_px_top orelse self.aes.border_px) + (self.aes.border_px_bot orelse self.aes.border_px));
    }

    pub fn draw(self: *Self) void {
        updateSizeFields(self);

        if (self.aes.draw_border) {
            self.vg.beginPath();

            self.vg.rect(self.xpos_fb, self.ypos_fb, self.wid_fb, -self.ht_fb);

            self.vg.fillColor(self.aes.border_bg_col);
            self.vg.fill();

            self.vg.strokeColor(self.aes.border_fg_col);
            self.vg.strokeWidth(self.aes.border_line_width);
            self.vg.stroke();

            self.vg.closePath();
        }

        if (self.aes.draw_box) {
            self.vg.beginPath();

            self.vg.rect(self.xpos_axes_fb, self.ypos_axes_fb, self.wid_axes_fb, -self.ht_axes_fb);

            self.vg.fillColor(self.aes.box_bg_col);
            self.vg.fill();

            self.vg.strokeColor(self.aes.box_fg_col);
            self.vg.strokeWidth(self.aes.box_line_width);
            self.vg.stroke();

            self.vg.closePath();
        }

        if (self.aes.draw_ticks and (self.aes.xticks != null) and (self.aes.yticks != null)) {
            self.drawTicks();

            if (self.aes.draw_grid) {
                self.drawGrid();
            }
        }

        if (self.aes.title_str != null) {
            titleDisp(self);
        }

        if (self.aes.xlabel_str != null) {
            xlabelDisp(self);
        }

        if (self.aes.ylabel_str != null) {
            ylabelDisp(self);
        }
    }

    pub fn set_limits(self: *Self, xlim: [2]f32, ylim: [2]f32, ticks_aes: Ticks.Aes) void {
        self.aes.xlim = xlim;
        self.aes.ylim = ylim;

        self.aes.xticks = Ticks.get(xlim, ticks_aes);
        self.aes.yticks = Ticks.get(ylim, ticks_aes);
    }

    pub fn drawTicks(self: *Self) void {
        var buffer: [30]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buffer);
        const stream = fbs.writer();

        // x_ticks
        const xlim = self.aes.xlim;

        const xt_min = self.aes.xticks.?.min;
        const xt_max = self.aes.xticks.?.max;
        const xt_inc = self.aes.xticks.?.inc;

        var xt: f32 = xt_min;
        while (xt < xt_max + 0.5 * xt_inc) : (xt += xt_inc) {
            const x_range = xlim[1] - xlim[0];

            const y_bot: f32 = self.ypos_axes_fb;
            const y_top: f32 = self.ypos_axes_fb - self.ht_axes_fb;

            // draw tick marks
            const xt_normal: f32 = (xt - xlim[0]) / x_range;
            const xt_tmp: f32 = self.xpos_axes_fb + xt_normal * self.wid_axes_fb;

            if ((xt != xlim[0]) and (xt != xlim[1])) {
                self.vg.beginPath();
                self.vg.strokeColor(self.aes.ticks_col);
                self.vg.strokeWidth(self.aes.ticks_line_width);

                self.vg.moveTo(xt_tmp, y_top);
                self.vg.lineTo(xt_tmp, y_top + float(self.aes.ticks_len_px));
                self.vg.moveTo(xt_tmp, y_bot);
                self.vg.lineTo(xt_tmp, y_bot - float(self.aes.ticks_len_px));
                self.vg.stroke();
                self.vg.closePath();
            }

            // format string to stream, then use "fbs.getWritten() to retrieve it
            formatTickLabel(stream, x_range, xt_min, xt_max, xt_inc, xt);

            self.vg.fontSize(self.aes.ticks_font_size);
            self.vg.fontFace(self.aes.label_font_face);
            self.vg.fillColor(self.aes.label_col);

            self.vg.textAlign(.{ .horizontal = .center, .vertical = .top });
            _ = self.vg.text(xt_tmp, y_bot + 0.1 * float(self.aes.border_px), fbs.getWritten());
            fbs.reset();
        }

        // y_ticks

        const ylim = self.aes.ylim;

        const yt_min = self.aes.yticks.?.min;
        const yt_max = self.aes.yticks.?.max;
        const yt_inc = self.aes.yticks.?.inc;

        var yt: f32 = yt_min;
        while (yt < yt_max + 0.5 * yt_inc) : (yt += yt_inc) {
            const y_range = ylim[1] - ylim[0];

            const x_left: f32 = self.xpos_axes_fb;
            const x_rt: f32 = self.xpos_axes_fb + self.wid_axes_fb;

            // draw tick marks
            const yt_normal: f32 = (yt - ylim[0]) / y_range;
            const yt_tmp: f32 = self.ypos_axes_fb - yt_normal * self.ht_axes_fb;

            if ((yt != ylim[0]) and (yt != ylim[1])) {
                self.vg.beginPath();
                self.vg.strokeColor(self.aes.ticks_col);
                self.vg.strokeWidth(self.aes.ticks_line_width);

                self.vg.moveTo(x_left, yt_tmp);
                self.vg.lineTo(x_left + float(self.aes.ticks_len_px), yt_tmp);
                self.vg.moveTo(x_rt, yt_tmp);
                self.vg.lineTo(x_rt - float(self.aes.ticks_len_px), yt_tmp);

                self.vg.stroke();
                self.vg.closePath();
            }

            // format string to stream, then use "fbs.getWritten() to retrieve it
            formatTickLabel(stream, y_range, yt_min, yt_max, yt_inc, yt);

            self.vg.fontSize(self.aes.ticks_font_size);
            self.vg.fontFace(self.aes.label_font_face);
            self.vg.fillColor(self.aes.label_col);

            self.vg.textAlign(.{ .horizontal = .right, .vertical = .middle });
            _ = self.vg.text(x_left - 0.1 * float(self.aes.border_px), yt_tmp, fbs.getWritten());

            fbs.reset();
        }
    }

    pub fn drawGrid(self: *Self) void {
        const line_width = self.aes.grid_line_width;
        const col = self.aes.grid_col;

        const xlim = self.aes.xlim;
        const ylim = self.aes.ylim;

        // vertical lines / xticks

        const xt_min = self.aes.xticks.?.min;
        const xt_max = self.aes.xticks.?.max;
        const xt_inc = self.aes.xticks.?.inc;

        var xt: f32 = xt_min;

        const y_bot: f32 = self.ypos_axes_fb - @as(f32, @floatFromInt(self.aes.ticks_grid_space_px + self.aes.ticks_len_px));
        const y_top: f32 = self.ypos_axes_fb - self.ht_axes_fb + @as(f32, @floatFromInt(self.aes.ticks_grid_space_px + self.aes.ticks_len_px));

        while (xt <= xt_max) : (xt += xt_inc) {
            if (((xt != xlim[0]) and (xt != xlim[1])) or (self.aes.draw_box == false)) {
                const x_range = xlim[1] - xlim[0];

                const xt_normal: f32 = (xt - xlim[0]) / x_range;
                const xt_tmp: f32 = self.xpos_axes_fb + xt_normal * self.wid_axes_fb;

                self.vg.beginPath();
                self.vg.moveTo(xt_tmp, y_bot);
                self.vg.lineTo(xt_tmp, y_top);
                self.vg.strokeColor(col);
                self.vg.strokeWidth(line_width);
                self.vg.stroke();
                self.vg.closePath();
            }
        }

        // horizontal lines / yticks
        const yt_min = self.aes.yticks.?.min;
        const yt_max = self.aes.yticks.?.max;
        const yt_inc = self.aes.yticks.?.inc;

        var yt: f32 = yt_min;

        const x_left: f32 = self.xpos_axes_fb + @as(f32, @floatFromInt(self.aes.ticks_grid_space_px + self.aes.ticks_len_px));
        const x_rt: f32 = self.xpos_axes_fb + self.wid_axes_fb - @as(f32, @floatFromInt(self.aes.ticks_grid_space_px + self.aes.ticks_len_px));

        while (yt <= yt_max) : (yt += yt_inc) {
            if (((yt != ylim[0]) and (yt != ylim[1])) or (self.aes.draw_box == false)) {
                const y_range = ylim[1] - ylim[0];

                const yt_normal: f32 = (yt - ylim[0]) / y_range;
                const yt_tmp: f32 = self.ypos_axes_fb - yt_normal * self.ht_axes_fb;

                self.vg.beginPath();
                self.vg.moveTo(x_left, yt_tmp);
                self.vg.lineTo(x_rt, yt_tmp);
                self.vg.strokeColor(col);
                self.vg.strokeWidth(line_width);
                self.vg.stroke();
                self.vg.closePath();
            }
        }
    }

    pub fn titleDisp(self: *Self) void {
        if (self.aes.title_str != null) {
            self.vg.fontSize(self.aes.title_font_size);
            self.vg.fontFace(self.aes.title_font_face);
            self.vg.fillColor(self.aes.title_col);

            const x: f32 = self.xpos_fb + 0.5 * self.wid_fb;

            // var y: f32 = self.ypos_fb - self.ht_fb + 0.8 * float(self.aes.border_px);
            const y: f32 = self.ypos_fb - self.ht_fb + self.aes.title_offset;

            self.vg.textAlign(.{ .horizontal = .center, .vertical = .top });
            _ = self.vg.text(x, y, self.aes.title_str.?);
        }
    }

    pub fn xlabelDisp(self: *Self) void {
        if (self.aes.xlabel_str != null) {
            self.vg.fontSize(self.aes.label_font_size);
            self.vg.fontFace(self.aes.label_font_face);
            self.vg.fillColor(self.aes.label_col);

            const x: f32 = self.xpos_fb + 0.5 * self.wid_fb;
            const y: f32 = self.ypos_fb - self.aes.xlabel_offset;

            self.vg.textAlign(.{ .horizontal = .center, .vertical = .bottom });
            _ = self.vg.text(x, y, self.aes.xlabel_str.?);
        }
    }

    pub fn ylabelDisp(self: *Self) void {
        if (self.aes.ylabel_str != null) {
            self.vg.fontSize(self.aes.label_font_size);
            self.vg.fontFace(self.aes.label_font_face);
            self.vg.fillColor(self.aes.label_col);

            const x: f32 = self.xpos_fb + self.aes.ylabel_offset;
            const y: f32 = self.ypos_fb - 0.5 * self.ht_fb;

            self.vg.save();
            self.vg.translate(x, y);
            self.vg.rotate(-std.math.pi / 2.0);

            self.vg.textAlign(.{ .horizontal = .center, .vertical = .top });
            _ = self.vg.text(0, 0, self.aes.ylabel_str.?);

            self.vg.restore();
        }
    }

    pub fn formatTickLabel(stream: anytype, data_range: f32, tick_min: f32, tick_max: f32, tick_inc: f32, tick_val: f32) void {

        // use stream printing to adjust the number of decimal places needed
        // for tick strings (when not scientific notation)

        const eps = data_range / 1000;

        if (isInt(tick_min) and isInt(tick_inc)) {
            if (@max(@abs(tick_min), @abs(tick_max)) < 9999) {

                // if int needs less than 4 char, use decimal notation
                // else use scientific notation
                stream.print("{d:.0}", .{tick_val}) catch unreachable;
            } else {
                stream.print("{e:7.2}", .{tick_val}) catch unreachable;
            }
        } else {

            // for non-integer ticks, determine how many digits to right
            // of decimal point are needed
            if (@abs(tick_val - @round(tick_val)) < eps) {
                stream.print("{d:.0}", .{tick_val}) catch unreachable;
            } else if (@abs(10 * tick_val - @round(10 * tick_val)) < eps) {
                stream.print("{d:.1}", .{tick_val}) catch unreachable;
            } else if (@abs(100 * tick_val - @round(100 * tick_val)) < eps) {
                stream.print("{d:.2}", .{tick_val}) catch unreachable;
            } else {
                stream.print("{e:7.2}", .{tick_val}) catch unreachable;
            }
        }
    }

    pub fn text(self: *Self, x: f32, y: f32, aes: TextAes) void {
        if (aes.str != null) {

            // const x_min = self.axes.aes.xlim[0];
            const x_min = self.aes.xlim[0];
            const x_max = self.aes.xlim[1];
            const x_range = x_max - x_min;

            const y_min = self.aes.ylim[0];
            const y_max = self.aes.ylim[1];
            const y_range = y_max - y_min;

            const x_normal: f32 = (x - x_min) / x_range;
            const x_tmp: f32 = self.xpos_axes_fb + x_normal * self.wid_axes_fb;

            const y_normal: f32 = (y - y_min) / y_range;
            const y_tmp: f32 = self.ypos_axes_fb - y_normal * self.ht_axes_fb;

            self.vg.save();
            self.vg.translate(x_tmp, y_tmp);
            self.vg.rotate(aes.rotation);

            self.vg.fontSize(aes.font_size);
            self.vg.fontFace(aes.font_face);
            self.vg.fillColor(aes.col);

            self.vg.textAlign(aes.alignment);
            _ = self.vg.text(0, 0, aes.str.?);

            self.vg.restore();
        }
    }
};
