const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const c_lib = b.addStaticLibrary("foo", "foo.c");
    c_lib.linkLibC();
    c_lib.setTarget(target); // removing this line prevents the error: 'stdio.h' file not found from clang
    c_lib.setBuildMode(mode);

    const lib = b.addStaticLibrary("zig-windows-repro", "src/main.zig");
    lib.setBuildMode(mode);
    lib.step.dependOn(&c_lib.step);
    lib.linkLibrary(c_lib);
    if (target.os_tag) |os| {
        if (os == .windows) {
            // workaround for missing includes: https://github.com/ziglang/zig/issues/5402
            if (b.env_map.get("INCLUDE")) |entry| {
                var it = std.mem.split(entry, ";");
                while (it.next()) |path| {
                    lib.addIncludeDir(path);
                }
            }
        }
    }
    lib.install();

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
