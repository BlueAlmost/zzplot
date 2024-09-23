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

        const nanovg_dep = b.dependency("nanovg", .{ .target = target, .optimize = optimize });
        // const glad = nanovg_dep.builder.addStaticLibrary(.{ //
        //     .name = "glad",
        //     .root_source_file = nanovg_dep.path("lib/gl2/src/glad.c"),
        //     .target = target,
        //     .optimize = optimize,
        // });
        // const fontstash = nanovg_dep.builder.addStaticLibrary(.{ //
        //     .name = "fontstash",
        //     .root_source_file = nanovg_dep.path("src/fontstash.c"),
        //     .target = target,
        //     .optimize = optimize,
        // });

        // exe.linkLibrary(glad);
        // exe.linkLibrary(fontstash);

        exe.addCSourceFile(.{ .file = nanovg_dep.path("lib/gl2/src/glad.c"), .flags = &.{} });
        // exe.addCSourceFile(.{ .file = nanovg_dep.path("src/fontstash.c"), .flags = &.{ "-DFONS_NO_STDIO", "-fno-stack-protector" } });
        // const nanovg_mod = nanovg_dep.module("nanovg");
        exe.addIncludePath(nanovg_dep.path("lib/gl2/include"));
        exe.linkSystemLibrary("glfw");
        // exe.linkSystemLibrary("glad");
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("X11");
        // exe.addIncludePath(b.path("/usr/local/include/glfw"));
        // exe.addIncludePath(b.path("/usr/local/include/GL"));
        // NOT NEEDED exe.addCSourceFile(.{ .file = .{ .path = "../nanovg-zig/src/stb_image.c" }, .flags = &.{ "-DSTBI_NO_STDIO", "-fno-stack-protector" } });
        b.installArtifact(exe);

        b.getInstallStep().dependOn(&b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .{ .custom = "../bin" } } }).step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        run_step.dependOn(&run_cmd.step);

        exe.root_module.addImport("zzplot_import_name", b.dependency("zzplot", .{}).module("ZZPlot"));
    }
};
