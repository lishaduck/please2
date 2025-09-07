const std = @import("std");
const Allocator = std.mem.Allocator;

const builtin = @import("builtin");
const native_os = builtin.os.tag;

username: []const u8,

pub fn create(allocator: Allocator) !@This() {
    if (native_os == .windows) {
        var buffer: [256]u16 = undefined;
        var size: u32 = 256;

        const success = std.windows.GetUserNameW(&buffer[0], &size);
        if (success == 0) return error.UserNotFound;

        return try std.unicode.utf16LeToUtf8Alloc(allocator, buffer[0..@intCast(size - 1)]);
    } else {
        const uid = std.c.getuid();
        const pw = std.c.getpwuid(uid);
        if (pw == null) return error.UserNotFound;

        return .{
            .username = std.mem.span(pw.?.name).?,
        };
    }
}

pub fn deinit(self: @This(), allocator: Allocator) void {
    if (native_os == .windows) {
        allocator.free(self);
    }
}
