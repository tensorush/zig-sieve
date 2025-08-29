const std = @import("std");

const manifest = @import("build.zig.zon");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/root.zig");
    const version: std.SemanticVersion = try .parse(manifest.version);

    // Public root module
    const root_mod = b.addModule("sieve", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
        .strip = b.option(bool, "strip", "Strip binary"),
    });

    // Library
    const lib = b.addLibrary(.{
        .name = "sieve",
        .version = version,
        .root_module = root_mod,
    });
    b.installArtifact(lib);

    // Documentation
    const docs_step = b.step("doc", "Emit documentation");

    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = lib.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);

    // Benchmark
    const bench_step = b.step("bench", "Run benchmark");

    const bench_exe = b.addExecutable(.{
        .name = "bench",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = .ReleaseFast,
            .root_source_file = b.path("src/bench.zig"),
        }),
    });

    const bench_exe_run = b.addRunArtifact(bench_exe);
    if (b.args) |args| {
        bench_exe_run.addArgs(args);
    }
    bench_step.dependOn(&bench_exe_run.step);

    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addTest(.{
        .root_module = root_mod,
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

    // Compilation check for ZLS Build-On-Save
    // See: https://zigtools.org/zls/guides/build-on-save/
    const check_step = b.step("check", "Check compilation");
    const check_exe = b.addExecutable(.{
        .name = "sieve",
        .version = version,
        .root_module = root_mod,
    });
    check_step.dependOn(&check_exe.step);
}
