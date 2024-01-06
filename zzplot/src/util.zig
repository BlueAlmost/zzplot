const std = @import("std");
const zzplot = @import("zzplot");

const print = std.debug.print;

const Figure = zzplot.Figure;

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub fn createShared() !?*c.GLFWwindow {

    // initialize glfw, glad, and create dummy shared window (hidden)

    if (c.glfwInit() == c.GLFW_FALSE) {
        return error.GLFWInitFailed;
    }
    c.glfwSwapInterval(1);
    c.glfwSetTime(0);

    const shared = c.glfwCreateWindow(100, 100, "shared", null, null);

    c.glfwHideWindow(shared);
    c.glfwMakeContextCurrent(shared);

    if (c.gladLoadGL() == 0) {
        return error.GLADInitFailed;
    }
    return shared;
}

pub inline fn isInt(f: f32) bool {
    if (f == @round(f)) return true else return false;
}

pub inline fn int(f: anytype) i32 {
    switch (@TypeOf(f)) {
        f16, f32, f64 => {
            return @as(i32, @intFromFloat(@round(f)));
        },
        else => {
            @compileError("expected float argument");
        },
    }
}

pub inline fn float(i: anytype) f32 {
    switch (@TypeOf(i)) {
        u8, u16, u32, u64, usize, i8, i16, i32, i64 => {
            return @as(f32, @floatFromInt(i));
        },
        else => {
            @compileError("expected integer argument");
        },
    }
}

pub fn minMax(comptime T: type, x: anytype) [2]T {

    // intended input x is a "tuple of slices"
    // x is .{ []S, []S, []S}, output will be coerced to type T

    var xmin: T = std.math.floatMax(T);
    var xmax: T = -std.math.floatMax(T);

    inline for (std.meta.fields(@TypeOf(x))) |fld| {
        const slc: fld.type = @field(x, fld.name);
        for (slc) |val| {
            xmin = @min(xmin, @as(T, val));
            xmax = @max(xmax, @as(T, val));
        }
    }
    return .{ xmin, xmax };
}

pub fn max(comptime T: type, x: []T) T {
    var val_max = x[0];
    for (x) |val| {
        val_max = @max(val_max, val);
    }
    return val_max;
}

pub fn min(comptime T: type, x: []T) T {
    var val_min = x[0];
    for (x) |val| {
        val_min = @min(val_min, val);
    }
    return val_min;
}

pub fn anyLive(figs: []*Figure) bool {
    for (figs) |fig| {
        if (fig.live) {
            return true;
        }
    }
    return false;
}

pub fn cpToUTF8(cp: u21, buf: []u8) [:0]const u8 {
    const len = std.unicode.utf8Encode(cp, buf) catch unreachable;
    buf[len] = 0;
    return @ptrCast(buf[0..len]);
}
