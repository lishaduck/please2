const std = @import("std");
const Allocator = std.mem.Allocator;

username: []const u8,

arena: std.heap.ArenaAllocator,

pub fn deinit(self: @This()) void {
    self.arena.deinit();
}

const RawJson = struct { username: []const u8 };

pub fn create(allocator: Allocator, configPath: []const u8) !?@This() {
    const file = std.fs.openFileAbsolute(configPath, .{}) catch |err| return switch (err) {
        error.FileNotFound => null,
        else => err,
    };
    defer file.close();

    var arena: std.heap.ArenaAllocator = .init(allocator);
    errdefer arena.deinit();
    const a = arena.allocator();

    const size = try file.getEndPos();
    var source = try a.alloc(u8, size);

    var file_reader = file.reader(source);
    var reader = &file_reader.interface;

    const read_len = try reader.readSliceShort(source);
    source = source[0..read_len];

    const parsed = try std.json.parseFromSliceLeaky(RawJson, a, source, .{});

    return .{
        .username = parsed.username,
        .arena = arena,
    };
}
