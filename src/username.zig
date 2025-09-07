const std = @import("std");
const Allocator = std.mem.Allocator;

const builtin = @import("builtin");
const native_os = builtin.os.tag;

username: []const u8,

extern "advapi32" fn GetUserNameW(
    lpBuffer: [*]u16,
    pcbBuffer: *u32,
) callconv(.winapi) std.os.windows.LSTATUS;

pub const Error = error{
    UserNotFound,
    Unexpected,
};

pub fn create(allocator: Allocator) Error!@This() {
    if (native_os == .windows) {
        var buffer: [256]u16 = undefined;
        var size: u32 = 256;

        const success = GetUserNameW(&buffer, &size);
        if (success == 0) return error.UserNotFound;

        const name = std.unicode.utf16LeToUtf8Alloc(allocator, buffer[0..@intCast(size - 1)]) catch return error.Unexpected;

        return .{
            .username = name,
        };
    } else {
        const uid = std.posix.getuid();
        const pw = std.c.getpwuid(uid);

        if (pw) |info| return .{
            .username = std.mem.span(info.name orelse return error.UserNotFound),
        };

        return error.UserNotFound;
    }
}

pub fn deinit(self: @This(), allocator: Allocator) void {
    if (native_os == .windows) {
        allocator.free(self.username);
    }
}
