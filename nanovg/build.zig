const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nanovg = b.addModule("nanovg_build_name", .{
        .source_file = std.Build.FileSource.relative("src/nanovg.zig"),
    });

    const nanovg_tests = b.addTest(.{
        .root_source_file = std.Build.FileSource.relative("src/nanovg_test.zig"),
        .target = target,
        .optimize = optimize,
    });

    nanovg_tests.addModule("nanovg_build_name", nanovg);

    const run_nanovg_tests = b.addRunArtifact(nanovg_tests);
    const test_step = b.step("test", "Run module tests");

    test_step.dependOn(&run_nanovg_tests.step);
}
