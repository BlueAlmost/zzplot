const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zzplot = b.addModule("ZZPlot", .{
        .root_source_file = b.path("src/zzplot.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Needed
    zzplot.import_table.put(b.allocator, "zzplot_import_name", zzplot) catch @panic("OOM");

    // Needed
    // zzplot.addIncludePath(.{ .cwd_relative = "../nanovg-zig/lib/gl2/include" });

    // exe.addIncludePath(.{ .cwd_relative = "../nanovg-zig/src" });
    const nanovg_dep = b.dependency("nanovg", .{ .target = target, .optimize = optimize });
    const nanovg_mod = nanovg_dep.module("nanovg");
    zzplot.addImport("nanovg", nanovg_mod);

    for (nanovg_mod.include_dirs.items) |item| {
        std.debug.print("{s}", .{item.path.src_path.sub_path});
        zzplot.addIncludePath(item.path);
    }
    zzplot.addIncludePath(nanovg_dep.path("lib/gl2/include"));

    const zzplot_tests = b.addTest(.{
        .root_source_file = b.path("src/zzplot_test.zig"),
        .target = target,
        .optimize = optimize,
    });

    // THIS IS THE LINE THAT CAUSES PROBLEM
    // zzplot_tests.root_module.addImport("zzplot", zzplot);

    const run_zzplot_tests = b.addRunArtifact(zzplot_tests);

    const test_step = b.step("test", "Run module tests");

    // _ = run_zzplot_tests;
    // _ = test_step;

    test_step.dependOn(&run_zzplot_tests.step);
}
