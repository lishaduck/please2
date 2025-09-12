const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const process = std.process;
const builtin = @import("builtin");
const ascii = std.ascii;

pub const GetEnvVarOrNullOwnedError = error{
    OutOfMemory,

    /// On Windows, environment variable keys provided by the user must be valid WTF-8.
    /// https://simonsapin.github.io/wtf-8/
    InvalidWtf8,
};

fn getEnvVarOrNullOwned(allocator: Allocator, key: []const u8) GetEnvVarOrNullOwnedError!?[]u8 {
    const envVar = process.getEnvVarOwned(allocator, key) catch |err| return switch (err) {
        error.EnvironmentVariableNotFound => null,
        error.OutOfMemory => error.OutOfMemory,
        error.InvalidWtf8 => error.InvalidWtf8,
    };

    if (envVar.len != 0) {
        return envVar;
    } else {
        allocator.free(envVar);

        return null;
    }
}

pub fn getConfigFile(
    allocator: Allocator,
    appname: []const u8,
) ![]const u8 {
    {
        const envAppname = try ascii.allocUpperString(allocator, appname);
        defer allocator.free(envAppname);
        const customConfigVar = try fmt.allocPrint(allocator, "{s}_CONFIG", .{envAppname});
        defer allocator.free(customConfigVar);

        const customConfig = try getEnvVarOrNullOwned(allocator, customConfigVar);
        if (customConfig) |conf| return conf;
    }

    x: {
        const xdg = try getEnvVarOrNullOwned(allocator, "XDG_CONFIG_HOME") orelse break :x;
        defer allocator.free(xdg);

        return try fs.path.join(allocator, &.{ xdg, appname, "config.json" });
    }

    switch (builtin.os.tag) {
        .macos => {
            const home = try std.process.getEnvVarOwned(allocator, "HOME");
            defer allocator.free(home);

            return std.fs.path.join(allocator, &.{ home, "Library", "Application Support", appname, "config.json" });
        },

        // TODO: Roaming AppData on Windows.

        else => {
            const home = try std.process.getEnvVarOwned(allocator, "HOME");
            defer allocator.free(home);

            return std.fs.path.join(allocator, &.{ home, ".config", appname, "config.json" });
        },
    }
}
