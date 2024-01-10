const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zzplot = b.addModule("zzplot_build_name", .{
        .root_source_file = .{ .path = "src/zzplot.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Needed
    zzplot.import_table.put(b.allocator, "zzplot_import_name", zzplot) catch @panic("OOM");

    zzplot.addImport("nanovg_import_name", 
        b.dependency("nanovg_zon_name", .{}).module("nanovg_build_name"));

    // NOT NEEDED zzplot.addIncludePath(.{ .path = "../nanovg-zig/src"});

    // Needed
    zzplot.addIncludePath(.{ .path = "../nanovg-zig/lib/gl2/include"});



    const zzplot_tests = b.addTest(.{
        .root_source_file = .{ .path ="src/zzplot_test.zig"},
        .target = target,
        .optimize = optimize,
    });

    zzplot_tests.root_module.addImport("zzplot", zzplot);

    const run_zzplot_tests = b.addRunArtifact(zzplot_tests);
    const test_step = b.step("test", "Run module tests");

    test_step.dependOn(&run_zzplot_tests.step);
}
