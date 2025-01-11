pub fn build(b: *std.Build) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer if (gpa.deinit() == .leak) @panic("memory leak");

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const alloc = arena.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep = b.dependency("src", .{});

    var defines = std.ArrayList([]const u8).init(alloc);
    var cargs = std.ArrayList([]const u8).init(alloc);
    try cargs.appendSlice(&.{
        "-std=gnu90",
        "-fno-sanitize=undefined",
    });
    if (target.result.os.tag == .windows) {
        try defines.appendSlice(&.{
            "-DWIN32_LEAN_AND_MEAN",
            "-D_WIN32_WINNT=0x0A00",
            "-D_CRT_DECLARE_NONSTDC_NAMES=0",
        });
    } else {
        try defines.appendSlice(&.{
            "-D_LARGEFILE_SOURCE",
            "-D_FILE_OFFSET_BITS=64",
        });
        if (target.result.os.tag == .linux) {
            try defines.appendSlice(&.{
                "-D_POSIX_C_SOURCE=200112",
                "-D_GNU_SOURCE",
            });
        }
    }
    const args = try std.mem.concat(alloc, []const u8, &.{
        cargs.items,
        defines.items,
    });

    var mod = b.addModule("source", .{
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });
    mod.addIncludePath(dep.path("include"));
    mod.addIncludePath(dep.path("src"));
    mod.addCSourceFiles(.{
        .files = &.{
            "fs-poll.c",
            "idna.c",
            "inet.c",
            "random.c",
            "strscpy.c",
            "strtok.c",
            "thread-common.c",
            "threadpool.c",
            "timer.c",
            "uv-common.c",
            "uv-data-getter-setters.c",
            "version.c",
        },
        .flags = args,
        .root = dep.path("src"),
    });
    if (target.result.os.tag == .windows) {
        mod.linkSystemLibrary("psapi", .{});
        mod.linkSystemLibrary("user32", .{});
        mod.linkSystemLibrary("advapi32", .{});
        mod.linkSystemLibrary("iphlpapi", .{});
        mod.linkSystemLibrary("userenv", .{});
        mod.linkSystemLibrary("ws2_32", .{});
        mod.linkSystemLibrary("dbghelp", .{});
        mod.linkSystemLibrary("ole32", .{});
        mod.linkSystemLibrary("shell32", .{});
        mod.addCSourceFiles(.{
            .files = &.{
                "async.c",
                "core.c",
                "detect-wakeup.c",
                "dl.c",
                "error.c",
                "fs.c",
                "fs-event.c",
                "getaddrinfo.c",
                "getnameinfo.c",
                "handle.c",
                "loop-watcher.c",
                "pipe.c",
                "thread.c",
                "poll.c",
                "process.c",
                "process-stdio.c",
                "signal.c",
                "snprintf.c",
                "stream.c",
                "tcp.c",
                "tty.c",
                "udp.c",
                "util.c",
                "winapi.c",
                "winsock.c",
            },
            .flags = args,
            .root = dep.path("src/win"),
        });
    } else {
        mod.linkSystemLibrary("pthread", .{});
        mod.addCSourceFiles(.{
            .files = &.{
                "async.c",
                "core.c",
                "dl.c",
                "fs.c",
                "getaddrinfo.c",
                "getnameinfo.c",
                "loop-watcher.c",
                "loop.c",
                "pipe.c",
                "poll.c",
                "process.c",
                "random-devurandom.c",
                "signal.c",
                "stream.c",
                "tcp.c",
                "thread.c",
                "tty.c",
                "udp.c",
            },
            .flags = args,
            .root = dep.path("src/unix"),
        });
        if (target.result.os.tag == .linux) {
            mod.linkSystemLibrary("dl", .{});
            mod.linkSystemLibrary("rt", .{});
            mod.addCSourceFiles(.{
                .files = &.{
                    "linux.c",
                    "procfs-exepath.c",
                    "random-getrandom.c",
                    "random-sysctl-linux.c",
                    "proctitle.c",
                },
                .flags = args,
                .root = dep.path("src/unix"),
            });
        }
    }

    b.addNamedLazyPath("include", dep.path("include"));

    const static = b.addStaticLibrary(.{
        .name = "static",
        .root_module = mod,
    });
    static.installHeadersDirectory(dep.path("include"), "", .{});
    b.installArtifact(static);

    const shared = b.addSharedLibrary(.{
        .name = "shared",
        .root_module = mod,
    });
    shared.installHeadersDirectory(dep.path("include"), "", .{});
    b.installArtifact(shared);
}

const std = @import("std");
