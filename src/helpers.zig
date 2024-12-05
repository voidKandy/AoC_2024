const std = @import("std");

pub fn posInString(ch: u8, str: *const []const u8) ?u32 {
    for (str.*, 0..) |c, i| {
        if (ch == c) {
            const ret: u32 = @intCast(i);
            return ret;
        }
    }
    return null;
}
pub fn asciiByteToU32(byte: u8) ?u32 {
    switch (byte) {
        48...57 => {
            const n: u32 = @intCast(byte);
            return n - 48;
        },
        else => {
            return null;
        },
    }
}

pub fn absDif(a: u32, b: u32) u32 {
    if (a < b) {
        return b - a;
    }
    return a - b;
}

pub fn readToString(filename: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const infile = try std.fs.cwd().openFile(filename, .{});
    defer infile.close();

    var buf_reader = std.io.bufferedReader(infile.reader());
    const reader = buf_reader.reader();

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    const writer = line.writer();
    while (reader.streamUntilDelimiter(writer, '\n', null)) {
        defer line.clearRetainingCapacity();

        buffer.appendSlice(line.items) catch |err| {
            return err;
        };
    } else |err| {
        if (err != error.EndOfStream) {
            return err;
        }
    }

    const copied = try allocator.dupe(u8, buffer.items);
    return copied;
}
