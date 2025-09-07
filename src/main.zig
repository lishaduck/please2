//! The main library, this orchestrates it.

const std = @import("std");
const assert = std.debug.assert;
const Io = std.Io;
const zeit = @import("zeit");

const builtin = @import("builtin");
const native_os = builtin.os.tag;

const Username = @import("username.zig");

pub const Init = struct {
    /// A default-selected general purpose allocator for temporary heap allocations.
    /// Debug mode will set up leak checking.
    allocator: std.mem.Allocator,
    /// Environment variables.
    environ: std.process.EnvMap,
};

pub fn printInfo(
    stdout: *Io.Writer,
    ansiConfig: std.Io.tty.Config,
    user: Username,
    dt: zeit.Time,
) !void {
    try stdout.print("──── ", .{});
    try ansiConfig.setColor(stdout, .green);
    try stdout.print("Hello ", .{});
    try ansiConfig.setColor(stdout, .bold);
    try stdout.print("{s}", .{user.username});
    try ansiConfig.setColor(stdout, .reset);
    try ansiConfig.setColor(stdout, .green);
    try stdout.print("! It's ", .{});
    try ansiConfig.setColor(stdout, .blue);
    try ansiConfig.setColor(stdout, .bold);
    try dt.strftime(stdout, "%d %b");
    try ansiConfig.setColor(stdout, .reset);
    try stdout.print(" | ", .{});
    try ansiConfig.setColor(stdout, .blue);
    try ansiConfig.setColor(stdout, .bold);
    try dt.strftime(stdout, "%I:%M %p");
    try ansiConfig.setColor(stdout, .reset);
    try stdout.print(" ────\n", .{});

    try stdout.flush(); // Don't forget to flush!
}

pub fn juicedMain(init: Init) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = std.fs.File.stdout();
    var stdout_writer = stdout_file.writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const now = try zeit.instant(.{});
    const local = try zeit.local(init.allocator, &init.environ);
    defer local.deinit();
    const now_local = now.in(&local);
    const dt = now_local.time();

    const user = try Username.create(init.allocator);
    defer user.deinit(init.allocator);

    const ansiConfig = std.Io.tty.Config.detect(stdout_file);

    try printInfo(stdout, ansiConfig, user, dt);
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

    const allocator, const is_debug = gpa: {
        if (native_os == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) assert(debug_allocator.deinit() == .ok);

    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    juicedMain(.{
        .allocator = allocator,
        .environ = env,
    }) catch |err| switch (err) {
        else => @panic("Oops!"),
    };
}
