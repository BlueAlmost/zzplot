const std = @import("std");

// const zzplot = @import("zzplot_import_name");
const zzplot = @import("zzplot_import_name");
const nvg = @import("nanovg_import_name");

const Color = zzplot.Color;
const TextAes = zzplot.TextAes;
const PlotAes = zzplot.PlotAes;

const int = zzplot.int;
const float = zzplot.float;
const cpToUTF8 = zzplot.cpToUTF8;

const Allocator = std.mem.Allocator;
const print = std.debug.print;

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub const Aes = struct {
    wid: f32 = 900,
    ht: f32 = 675,
    wid_min: f32 = 250,
    ht_min: f32 = 200,

    xpos: ?i32 = null,
    ypos: ?i32 = null,
    border_px: u32 = 30,
    border_px_top: ?u32 = null,
    border_px_bot: ?u32 = null,
    border_px_left: ?u32 = null,
    border_px_right: ?u32 = null,

    col: nvg.Color = Color.white,
    name: [*c]const u8 = "Figure Window",
    grid: bool = false,

    disp_fps: bool = false,
    fps_beta: f64 = 0.925,

    title_str: ?[]const u8 = null,
    title_font_face: [:0]const u8 = "sans",
    title_font_size: f32 = 21,
    title_col: nvg.Color = Color.black,
};

pub const Figure = struct {
    const Self = @This();

    allocator: Allocator = undefined,
    shared: ?*c.GLFWwindow = null,
    window: ?*c.GLFWwindow = null,
    vg: nvg = undefined,

    aes: Aes,

    monitor: *const ?*c.GLFWmonitor = undefined,
    wid_fb: f32 = undefined,
    ht_fb: f32 = undefined,
    pxRatio: f32 = undefined,
    scale: f32 = undefined,
    live: bool = false,

    cursor_x: f64 = undefined,
    cursor_y: f64 = undefined,

    fps_timer: std.time.Timer = undefined,
    fps_start_time: u64 = undefined,
    fps_buf: [20]u8 = undefined,
    fps: f64 = 0,

    pub fn init(allocator: Allocator, shared: ?*c.GLFWwindow, vg: nvg, aes: Aes) !*Figure {
        if (c.glfwInit() == c.GLFW_FALSE) {
            return error.GLFWInitFailed;
        }

        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 2);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 0);

        const monitor = &c.glfwGetPrimaryMonitor();
        var scale: f32 = undefined;
        c.glfwGetMonitorContentScale(monitor.*, &scale, null);

        var window: ?*c.GLFWwindow = null;
        window = c.glfwCreateWindow(int(aes.wid / scale), int(aes.ht / scale), aes.name, null, shared);
        _ = c.glfwSetFramebufferSizeCallback(window, getFramebufferSize);

        if (window == null) {
            return error.GLFWInitFailed;
        }

        c.glfwSetWindowSizeLimits(window, int(aes.wid_min / scale), int(aes.ht_min / scale), c.GLFW_DONT_CARE, c.GLFW_DONT_CARE);

        var wid_int_fb: c_int = undefined;
        var ht_int_fb: c_int = undefined;
        var wid_fb: f32 = undefined;
        var ht_fb: f32 = undefined;
        var pxRatio: f32 = undefined;

        c.glfwGetFramebufferSize(window, &wid_int_fb, &ht_int_fb);
        wid_fb = float(@as(i32, @intCast(wid_int_fb)));
        ht_fb = float(@as(i32, @intCast(ht_int_fb)));
        pxRatio = wid_fb / (aes.wid / scale);

        _ = c.glfwSetKeyCallback(window, keyCallback);
        c.glfwMakeContextCurrent(window);

        if (c.gladLoadGL() == 0) {
            return error.GLADInitFailed;
        }

        var fig = try allocator.create(Figure);

        fig.allocator = allocator;
        fig.shared = shared;
        fig.window = window;
        fig.vg = vg;

        fig.aes = aes;

        fig.monitor = monitor;
        fig.wid_fb = wid_fb;
        fig.ht_fb = ht_fb;

        fig.pxRatio = pxRatio;
        fig.scale = scale;
        fig.live = true;

        if (fig.aes.disp_fps) {
            fig.fps_timer = try std.time.Timer.start();
        }

        c.glfwSetWindowUserPointer(window, fig);

        if ((fig.aes.xpos != null) and (fig.aes.ypos != null)) {
            setPos(fig, fig.aes.xpos.?, fig.aes.ypos.?);
        }

        return fig;
    }

    pub fn getSize(self: *Self) void {
        var win_wid: i32 = undefined;
        var win_ht: i32 = undefined;

        c.glfwGetWindowSize(self.window, &win_wid, &win_ht);
        self.aes.wid = float(win_wid) / self.scale;
        self.aes.ht = float(win_ht) / self.scale;

        var wid_fb: i32 = undefined;
        var ht_fb: i32 = undefined;

        c.glfwGetFramebufferSize(self.window, &wid_fb, &ht_fb);
        self.wid_fb = float(wid_fb);
        self.ht_fb = float(ht_fb);
        self.pxRatio = self.wid_fb / self.aes.wid;
    }

    pub fn getFramebufferSize(window: ?*c.GLFWwindow, wid_fb: c_int, ht_fb: c_int) callconv(.C) void {
        _ = wid_fb;
        _ = ht_fb;

        var self: *Self = @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window)));
        self.getSize();
    }

    pub fn clear(self: *Self) void {
        c.glClearColor(self.aes.col.r, self.aes.col.g, self.aes.col.b, self.aes.col.a);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);
    }

    pub fn begin(self: *Self) void {
        c.glfwMakeContextCurrent(self.window);
        c.glViewport(0, 0, int(self.wid_fb), int(self.ht_fb));

        self.vg.beginFrame(self.wid_fb, self.ht_fb, self.pxRatio);

        if (self.aes.disp_fps) {
            self.fps_start_time = self.fps_timer.read();
        }

        if (self.aes.grid) {
            drawGrid(self);
        }

        if (self.aes.title_str != null) {
            self.vg.fontSize(self.aes.title_font_size);
            self.vg.fontFace(self.aes.title_font_face);
            self.vg.fillColor(self.aes.title_col);

            const b_left = float(self.aes.border_px_left orelse self.aes.border_px);
            const b_right = float(self.aes.border_px_right orelse self.aes.border_px);
            const wid_net = self.wid_fb - b_left - b_right;

            const x: f32 = b_left + 0.5 * wid_net;

            const y: f32 = 0.8 * float(self.aes.border_px_top orelse self.aes.border_px);

            self.vg.textAlign(.{ .horizontal = .center, .vertical = .baseline });
            _ = self.vg.text(x, y, self.aes.title_str.?);
        }

        clear(self);
    }

    pub fn end(self: *Self) void {

        // order here is important:
        // 1) display fps first (if chosen)
        // 2) then endFrame, swap and poll (always)
        // 3) update filtered fps est, read timer for next frame (if chosen)

        if (self.aes.disp_fps) {
            self.text(0.02, 0.02, .{
                .str = std.fmt.bufPrint(&self.fps_buf, "fps: {d:5.1}", .{self.fps}) catch "fps: *****",
                .col = Color.opacity(Color.blue, 0.6),
            });
        }

        self.vg.endFrame();
        c.glfwSwapBuffers(self.window);
        c.glfwPollEvents();

        if (self.aes.disp_fps) {
            self.fps = self.aes.fps_beta * self.fps + (1 - self.aes.fps_beta) * (1.0e9 / @as(f64, @floatFromInt(self.fps_timer.read() - self.fps_start_time)));

            self.fps_start_time = self.fps_timer.read();
        }
    }

    fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
        const self: *Self = @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window)));
        myKeyCallback(self, key, scancode, action, mods);
    }

    fn myKeyCallback(self: *Self, key: c_int, scancode: c_int, action: c_int, mods: c_int) void {
        _ = scancode;
        _ = mods;

        if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS) {
            self.live = false;
            c.glfwHideWindow(self.window);
        }
    }

    pub fn setPos(self: *Self, x: i32, y: i32) void {
        c.glfwSetWindowPos(self.window, x, y);
    }

    pub fn getCursor(self: *Self) void {
        var mx: f64 = undefined;
        var my: f64 = undefined;

        c.glfwGetCursorPos(self.window, &mx, &my);
        self.cursor_x = mx / self.scale;
        self.cursor_y = my / self.scale;
    }

    pub fn drawGrid(self: *Self) void {
        // for designing figure layouts
        // paint a major 10x10 grid on the window and minor 20x20 grid

        const b_top = float(self.aes.border_px_top orelse self.aes.border_px);
        const b_bot = float(self.aes.border_px_bot orelse self.aes.border_px);
        const b_left = float(self.aes.border_px_left orelse self.aes.border_px);
        const b_right = float(self.aes.border_px_right orelse self.aes.border_px);

        const wid_net = self.wid_fb - b_left - b_right;
        const ht_net = self.ht_fb - b_top - b_bot;

        const line_width_major = 2;
        const line_width_minor = 1;

        const col_major = Color.brighten(Color.blue, 0.7);
        const col_minor = Color.brighten(col_major, 0.4);

        // vertical lines
        var x: f32 = undefined;
        const x_left: f32 = b_left;
        const x_right: f32 = self.wid_fb - b_right;

        var y: f32 = undefined;
        const y_bot: f32 = self.ht_fb - b_bot;

        const y_top: f32 = b_top;

        // majors
        var i: i32 = 0;
        while (i <= 10) : (i += 1) {
            x = 0.1 * float(i) * wid_net + b_left;
            self.vg.beginPath();
            self.vg.moveTo(x, y_bot);
            self.vg.lineTo(x, y_top);
            self.vg.strokeColor(col_major);
            self.vg.strokeWidth(line_width_major);
            self.vg.stroke();
            self.vg.closePath();
        }

        // minors
        i = 0;
        var offset = 0.05 * wid_net;
        while (i <= 9) : (i += 1) {
            x = 0.1 * float(i) * wid_net + b_left + offset;
            self.vg.beginPath();
            self.vg.moveTo(x, y_bot);
            self.vg.lineTo(x, y_top);
            self.vg.strokeColor(col_minor);
            self.vg.strokeWidth(line_width_minor);
            self.vg.stroke();
            self.vg.closePath();
        }

        // horizontal lines
        i = 0;
        while (i <= 10) : (i += 1) {
            y = (1.0 - 0.1 * float(i)) * ht_net + b_top;
            self.vg.beginPath();
            self.vg.moveTo(x_left, y);
            self.vg.lineTo(x_right, y);
            self.vg.strokeColor(col_major);
            self.vg.strokeWidth(line_width_major);
            self.vg.stroke();
            self.vg.closePath();
        }

        // minors
        i = 0;
        offset = 0.05 * ht_net;
        while (i <= 9) : (i += 1) {
            // y = 0.1*float(i)*ht_net + b_bot + offset;
            y = (1.0 - 0.1 * float(i)) * ht_net + b_top - offset;
            self.vg.beginPath();
            self.vg.moveTo(x_left, y);
            self.vg.lineTo(x_right, y);
            self.vg.strokeColor(col_minor);
            self.vg.strokeWidth(line_width_minor);
            self.vg.stroke();
            self.vg.closePath();
        }
    }

    pub fn text(self: *Self, x: f32, y: f32, aes: TextAes) void {
        if (aes.str != null) {
            const x_fb = x * self.wid_fb;
            const y_fb = (1 - y) * self.ht_fb;

            self.vg.save();
            self.vg.translate(x_fb, y_fb);
            self.vg.rotate(aes.rotation);

            self.vg.fontSize(aes.font_size);
            self.vg.fontFace(aes.font_face);
            self.vg.fillColor(aes.col);

            self.vg.textAlign(aes.alignment);
            _ = self.vg.text(0, 0, aes.str.?);

            self.vg.restore();
        }
    }

    pub fn lineSegment(self: *Self, x: [2]f32, y: [2]f32, aes: PlotAes) void {
        const x_fb_0 = x[0] * self.wid_fb;
        const x_fb_1 = x[1] * self.wid_fb;

        const y_fb_0 = (1 - y[0]) * self.ht_fb;
        const y_fb_1 = (1 - y[1]) * self.ht_fb;

        self.vg.beginPath();
        self.vg.moveTo(x_fb_0, y_fb_0);
        self.vg.lineTo(x_fb_1, y_fb_1);
        self.vg.strokeColor(aes.line_col);
        self.vg.strokeWidth(aes.line_width);
        self.vg.stroke();
        self.vg.closePath();

        if (aes.marker != PlotAes.Marker.none) {
            var icon: [8]u8 = undefined;

            self.vg.fontFace("symbols");
            self.vg.fontSize(aes.marker_size);
            self.vg.fillColor(aes.marker_col);

            self.vg.textAlign(.{ .horizontal = .center, .vertical = .middle });
            _ = self.vg.text(x_fb_0, y_fb_0, cpToUTF8(@intFromEnum(aes.marker), &icon));

            self.vg.textAlign(.{ .horizontal = .center, .vertical = .middle });
            _ = self.vg.text(x_fb_1, y_fb_1, cpToUTF8(@intFromEnum(aes.marker), &icon));
        }
    }
};
