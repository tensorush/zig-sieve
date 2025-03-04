const std = @import("std");

pub fn build(b: *std.Build) void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/root.zig");
    const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 1 };

    // Module
    const mod = b.addModule("sieve", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addLibrary(.{
        .name = "sieve",
        .version = version,
        .root_module = mod,
    });

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    install_step.dependOn(lib_step);

    // Documentation
    const docs_step = b.step("doc", "Emit documentation");
    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = lib.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);
    install_step.dependOn(docs_step);

    // Benchmarks
    const benchs_step = b.step("bench", "Run benchmarks");

    const benchs = b.addExecutable(.{
        .name = "bench",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = .ReleaseFast,
            .root_source_file = b.path("src/bench.zig"),
        }),
    });

    const benchs_run = b.addRunArtifact(benchs);
    if (b.args) |args| {
        benchs_run.addArgs(args);
    }
    benchs_step.dependOn(&benchs_run.step);

    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addTest(.{
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .root_source_file = root_source_file,
        }),
    });

    const tests_run = b.addRunArtifact(tests);
    tests_step.dependOn(&tests_run.step);
    install_step.dependOn(tests_step);

    // Formatting check
    const fmt_step = b.step("fmt", "Check formatting");

    const fmt = b.addFmt(.{
        .paths = &.{
            "src/",
            "build.zig",
            "build.zig.zon",
        },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
    install_step.dependOn(fmt_step);
}
