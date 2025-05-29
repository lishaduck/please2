//! The main library, this orchestrates it.

const std = @import("std");
const zeit = @import("zeit");
const ansi_term = @import("ansi_term");
const Style = ansi_term.style.Style;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const aAlloc = arena.allocator();

    var env = try std.process.getEnvMap(alloc);
    defer env.deinit();

    const now = try zeit.instant(.{});
    const local = try zeit.local(aAlloc, &env);
    const now_local = now.in(&local);
    const dt = now_local.time();

    const base_style: Style = .{
        .foreground = .Green,
        .background = .Default,
        .font_style = .{},
    };

    const date_style: Style = .{
        .foreground = .Blue,
        .background = .Default,
        .font_style = .{ .bold = true },
    };

    const name_style: Style = .{
        .foreground = .Green,
        .background = .Default,
        .font_style = .{ .bold = true, .rapidblink = true },
    };

    const user = "Eli";

    try stdout.print("──── ", .{});
    try ansi_term.format.updateStyle(stdout, base_style, .{});
    try stdout.print("Hello ", .{});
    try ansi_term.format.updateStyle(stdout, name_style, base_style);
    try stdout.print("{s}", .{user});
    try ansi_term.format.updateStyle(stdout, base_style, name_style);
    try stdout.print("! It's ", .{});
    try ansi_term.format.updateStyle(stdout, date_style, base_style);
    try dt.strftime(stdout, "%d %b");
    try ansi_term.format.updateStyle(stdout, .{}, date_style);
    try stdout.print(" | ", .{});
    try ansi_term.format.updateStyle(stdout, date_style, .{});
    try dt.strftime(stdout, "%I:%M %p");
    try ansi_term.format.updateStyle(stdout, .{}, date_style);
    try stdout.print(" ────\n", .{});

    try bw.flush(); // Don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
