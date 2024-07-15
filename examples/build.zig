const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    // const optimize = std.builtin.OptimizeMode.ReleaseFast;
    const optimize = std.builtin.OptimizeMode.Debug;

    const run_step = b.step("run", "Run the demo");
    // const test_step = b.step("test", "Run unit tests");

    const targs = [_]Targ{
        .{
            .name = "barebones",
            .src = "barebones/barebones.zig",
        },

        // .{
        //     .name = "simple_labels",
        //     .src = "simple_labels/simple_labels.zig",
        // },

        // .{
        //     .name = "layout_display",
        //     .src = "layout_display/layout_display.zig",
        // },

        // .{
        //     .name = "layout_display_unequal_borders",
        //     .src = "layout_display_unequal_borders/layout_display_unequal_borders.zig",
        // },

        // .{
        //     .name = "more_aesthetics",
        //     .src = "more_aesthetics/more_aesthetics.zig",
        // },

        // .{
        //     .name = "one_window_multiplot",
        //     .src = "one_window_multiplot/one_window_multiplot.zig",
        // },

        // .{
        //     .name = "multiple_windows",
        //     .src = "multiple_windows/multiple_windows.zig",
        // },

        // .{
        //     .name = "sine_movie",
        //     .src = "sine_movie/sine_movie.zig",
        // },
    };

    // build all targets
    for (targs) |targ| {
        // targ.build(b, target, optimize, run_step, test_step);
        targ.build(b, target, optimize, run_step);
    }
}

const Targ = struct {
    name: []const u8,
    src: []const u8,

    // pub fn build(self: Targ, b: *std.Build, target: anytype, optimize: anytype, run_step: anytype, test_step: anytype) void {

    pub fn build(self: Targ, b: *std.Build, target: anytype, optimize: anytype, run_step: anytype) void {

        // _ = test_step;

        const exe = b.addExecutable(.{
            .name = self.name,
            // .root_source_file = .{ .cwd_relative = self.src },
            .root_source_file = b.path(self.src),
            .target = target,
            .optimize = optimize,
        });

        exe.linkSystemLibrary("glfw");
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("X11");

        // NOT NEEDED exe.addIncludePath(.{ .path = "../nanovg-zig/src" });

        // Needed
        exe.addIncludePath(.{ .cwd_relative = "../nanovg-zig/lib/gl2/include" });

        // Needed
        exe.addCSourceFile(.{ .file = b.path("../nanovg-zig/lib/gl2/src/glad.c"), .flags = &.{} });

        // Needed
        exe.addCSourceFile(.{ .file = b.path("../nanovg-zig/src/fontstash.c"), .flags = &.{ "-DFONS_NO_STDIO", "-fno-stack-protector" } });

        // NOT NEEDED exe.addCSourceFile(.{ .file = .{ .path = "../nanovg-zig/src/stb_image.c" }, .flags = &.{ "-DSTBI_NO_STDIO", "-fno-stack-protector" } });

        b.installArtifact(exe);

        b.getInstallStep().dependOn(&b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .{ .custom = "../bin" } } }).step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        run_step.dependOn(&run_cmd.step);

        exe.root_module.addImport( "zzplot_import_name",
            b.dependency("zzplot_zon_name", .{}).module("zzplot_build_name"));
    }
};
