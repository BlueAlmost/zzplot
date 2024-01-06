const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    // const optimize = std.builtin.OptimizeMode.ReleaseFast;
    const optimize = std.builtin.OptimizeMode.Debug;

    const run_step = b.step("run", "Run the demo");
    const test_step = b.step("test", "Run unit tests");

    const targs = [_]Targ{
        .{
            .name = "barebones",
            .src = "barebones/barebones.zig",
        },

        .{
            .name = "simple_labels",
            .src = "simple_labels/simple_labels.zig",
        },

        .{
            .name = "layout_display",
            .src = "layout_display/layout_display.zig",
        },

        .{
            .name = "layout_display_unequal_borders",
            .src = "layout_display_unequal_borders/layout_display_unequal_borders.zig",
        },

        .{
            .name = "more_aesthetics",
            .src = "more_aesthetics/more_aesthetics.zig",
        },

        .{
            .name = "one_window_multiplot",
            .src = "one_window_multiplot/one_window_multiplot.zig",
        },

        .{
            .name = "multiple_windows",
            .src = "multiple_windows/multiple_windows.zig",
        },
        .{
            .name = "sine_movie",
            .src = "sine_movie/sine_movie.zig",
        },
    };

    // build all targets
    for (targs) |targ| {
        targ.build(b, target, optimize, run_step, test_step);
    }
}

const Targ = struct {
    name: []const u8,
    src: []const u8,

    pub fn build(self: Targ, b: *std.Build, target: anytype, optimize: anytype, run_step: anytype, test_step: anytype) void {
        var exe = b.addExecutable(.{
            .name = self.name,
            .root_source_file = .{ .path = self.src },
            .target = target,
            .optimize = optimize,
        });

        exe.addIncludePath(.{ .path = "../nanovg/src" });
        exe.addIncludePath(.{ .path = "../nanovg/lib/gl2/include" });

        exe.linkSystemLibrary("glfw3");
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("X11");

        exe.addCSourceFile(.{ .file = .{ .path = "../nanovg/lib/gl2/src/glad.c" }, .flags = &.{} });

        b.installArtifact(exe);

        b.getInstallStep().dependOn(&b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .{ .custom = "../bin" } } }).step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        run_step.dependOn(&run_cmd.step);

        const zzplot_dep = b.dependency("zzplot_zon_name", .{ // as declared in build.zig.zon
            .target = target,
            .optimize = optimize,
        });

        const zzplot = zzplot_dep.module("zzplot_build_name"); // as declared in build.zig of dependency

        exe.addModule("zzplot_import_name", zzplot); // name to use when importing

        // expose zzplot module to itself
        zzplot.dependencies.put("zzplot", zzplot) catch @panic("OOM");

        // nanovg static library ===============================================================

        const nanovg = b.addModule("nanovg", .{
            .source_file = .{ .path = "../nanovg/src/nanovg.zig" },
        });

        const lib = b.addStaticLibrary(.{
            .name = "nanovg",
            .root_source_file = .{ .path = "../nanovg/src/nanovg.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.linkLibrary(lib);

        lib.addModule("nanovg", nanovg);

        lib.addIncludePath(.{ .path = "nanovg" });

        lib.addCSourceFile(.{ .file = .{ .path = "../nanovg/src/fontstash.c" }, .flags = &.{ "-DFONS_NO_STDIO", "-fno-stack-protector" } });

        lib.addCSourceFile(.{ .file = .{ .path = "../nanovg/src/stb_image.c" }, .flags = &.{ "-DSTBI_NO_STDIO", "-fno-stack-protector" } });

        lib.linkLibC();

        b.installArtifact(lib);

        _ = test_step;
    }
};
