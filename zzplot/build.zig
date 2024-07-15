const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zzplot = b.addModule("zzplot_build_name", .{
        .root_source_file = b.path("src/zzplot.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Needed
    zzplot.import_table.put(b.allocator, "zzplot_import_name", zzplot) catch @panic("OOM");

    zzplot.addImport("nanovg_import_name", 
        b.dependency("nanovg_zon_name", .{}).module("nanovg"));

    // NOT NEEDED zzplot.addIncludePath(.{ .path = "../nanovg-zig/src"});

    // Needed
    zzplot.addIncludePath(.{ .cwd_relative = "../nanovg-zig/lib/gl2/include"});



    const zzplot_tests = b.addTest(.{
        // .root_source_file = .{ .cwd_relative ="src/zzplot_test.zig"},
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
