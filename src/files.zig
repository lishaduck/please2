const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;

pub fn readFileAlloc(allocator: Allocator, file: fs.File) ![]const u8 {
    // If the file size doesn't fit a usize it'll be certainly greater than
    // `max_bytes`
    const size = std.math.cast(usize, try file.getEndPos()) orelse
        return error.FileTooBig;

    var source = try allocator.alloc(u8, size);

    var file_reader = file.reader(source);
    var reader = &file_reader.interface;

    const read_len = try reader.readSliceShort(source);
    source = source[0..read_len];

    return source;
}
