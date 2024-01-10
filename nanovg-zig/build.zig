const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nanovg = b.addModule("nanovg_build_name", .{
        .root_source_file = .{ .path = "src/nanovg.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    nanovg.addIncludePath(.{ .path = "../nanovg-zig/src" });
    nanovg.addIncludePath(.{ .path = "../nanovg-zig/lib/gl2/include" });
    // nanovg.addCSourceFile(.{ .file = .{ .path = "../nanovg-zig/lib/gl2/src/glad.c" }, .flags = &.{} });



    const nanovg_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/nanovg_test.zig"},
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // nanovg_tests.addModule("nanovg_build_name", nanovg);
    nanovg_tests.root_module.addImport("nanovg_build_name", nanovg);

    const run_nanovg_tests = b.addRunArtifact(nanovg_tests);
    const test_step = b.step("test", "Run module tests");

    test_step.dependOn(&run_nanovg_tests.step);
}

