const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zzplot = b.addModule("zzplot_build_name", .{
        .source_file = .{ .path = "src/zzplot.zig" },
        .dependencies = &.{
            .{ .name = "nanovg_import_name", .module = b.dependency("nanovg_zon_name", .{}).module("nanovg_build_name") },
        },
    });

    // expose zzplot module to itself
    zzplot.dependencies.put("zzplot", zzplot) catch @panic("OOM");

    const nanovg = b.addModule("nanovg_build_name", .{
        .source_file = .{ .path = "../nanovg/src/nanovg.zig" },
    });

    _ = nanovg;

    const zzplot_tests = b.addTest(.{
        .root_source_file = std.Build.FileSource.relative("src/zzplot_test.zig"),
        .target = target,
        .optimize = optimize,
    });

    zzplot_tests.addModule("zzplot_build_name", zzplot);

    const run_zzplot_tests = b.addRunArtifact(zzplot_tests);
    const test_step = b.step("test", "Run module tests");

    test_step.dependOn(&run_zzplot_tests.step);
}
