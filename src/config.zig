const std = @import("std");
const Allocator = std.mem.Allocator;

username: []const u8,

pub fn deinit() void {}

pub fn load(allocator: Allocator, configFile: []const u8) !?struct { std.json.Parsed(@This()), []u8 } {
    const file = std.fs.openFileAbsolute(configFile, .{}) catch |err| return switch (err) {
        error.FileNotFound => null,
        else => err,
    };
    defer file.close();

    const buffer = try allocator.alloc(u8, 64);
    defer allocator.free(buffer);
    var file_reader = file.reader(buffer);
    var reader = &file_reader.interface;

    const file_size = try file.getEndPos();
    const slice = try reader.readAlloc(allocator, file_size);

    const json = try std.json.parseFromSlice(@This(), allocator, slice, .{});

    return .{ json, slice };
}
