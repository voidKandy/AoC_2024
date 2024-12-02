const std = @import("std");
const helpers = @import("./helpers.zig");
const print = std.debug.print;
const panic = std.debug.panic;

pub fn main() !void {
    const infile = try std.fs.cwd().openFile("inputs/day2.txt", .{});
    defer infile.close();

    var br = std.io.bufferedReader(infile.reader());
    const reader = br.reader().any();

    var safe_count: u32 = 0;

    while (nextReport(reader)) |r| {
        // print("got report: {any}\n", .{r});

        if (reportIsSafe(r)) {
            safe_count += 1;
        }
    } else |err| {
        if (err != error.EndOfStream) {
            print("unexpected error: {any}\n", .{err});
            return;
        }
    }

    print("Num Safe: {d}\n", .{safe_count});
    return;
}

const ARR_BUFFER_SIZE = 16;
const VAL_BUFFER_SIZE = 4;

const Report = std.meta.Tuple(&.{ []u32, usize });
fn nextReport(reader: std.io.AnyReader) !Report {
    var arr: [ARR_BUFFER_SIZE]u32 = undefined;
    @memset(&arr, 0);
    var len: usize = 0;
    var val_buffer: [VAL_BUFFER_SIZE]?u32 = undefined;
    @memset(&val_buffer, null);
    var val_buffer_len: u32 = 0;

    while (reader.readByte()) |byte| {
        switch (byte) {
            // whitespace
            // '\n' => {
            //     break;
            // },
            ' ', '\n' => {
                var num: u32 = 0;
                // print("val buffer: {any}\n", .{val_buffer});
                for (0..val_buffer_len) |i| {
                    if (val_buffer[i]) |v| {
                        if (val_buffer_len > 0) {
                            val_buffer_len -= 1;
                        }
                        var factor: u32 = 1;
                        for (0..val_buffer_len) |_| {
                            factor *= 10;
                        }

                        const val: u32 = v * factor;
                        // print("new num += {d}\n", .{val});
                        num += val;
                    } else {
                        break;
                    }
                }
                arr[len] = num;
                // print("pushed {d} to arr\n{any}\n", .{ num, arr });
                len += 1;

                if (byte == '\n') {
                    break;
                }
            },
            else => {
                if (helpers.asciiByteToU32(byte)) |num| {
                    if (len + 1 > arr.len) {
                        panic("not enough in array buffer, need at least {d}", .{len + 1});
                    }
                    // print("pushing {d} to val_buffer\n", .{num});
                    val_buffer[val_buffer_len] = num;
                    val_buffer_len += 1;
                }
            },
        }
    } else |err| {
        return err;
    }
    return Report{ &arr, len };
}

fn reportIsSafe(report: Report) bool {
    var prev: ?u32 = null;
    var is_asc: ?bool = null;

    for (report[0][0..report[1]]) |v| {
        if (prev) |p| {
            if (v < p) {
                if (is_asc) |asc| {
                    if (asc) {
                        return false;
                    }
                }
                is_asc = false;
            } else {
                if (is_asc) |asc| {
                    if (!asc) {
                        return false;
                    }
                }
                is_asc = true;
            }
            const dif = helpers.absDif(v, p);

            if (dif < 1 or dif > 3) {
                return false;
            }
        }
        prev = v;
    }

    // print("report: {any} passed!\n", .{report[0]});

    return true;
}

test "input test" {
    const expect = std.testing.expect;
    const infile = try std.fs.cwd().openFile("inputs/day2test.txt", .{});
    defer infile.close();

    var br = std.io.bufferedReader(infile.reader());
    const reader = br.reader().any();

    var exp_arr = [_]u32{ 5, 20, 999, 56, 7, 5 };
    const expected = Report{
        &exp_arr,
        6,
    };

    if (nextReport(reader)) |r| {
        for (expected[0], 0..) |expval, i| {
            if (expval != r[0][i]) {
                panic("expected {d} at idx: {d}, got {d}\n", .{ expval, i, r[0][i] });
            }
        }
        try expect(expected[1] == r[1]);
    } else |err| {
        panic("error: {any}\n", .{err});
    }
}

test "small test" {
    const expect = std.testing.expect;
    const input = [_][5]u32{
        [5]u32{ 7, 6, 4, 2, 1 },
        [5]u32{ 1, 2, 7, 8, 9 },
        [5]u32{ 9, 7, 6, 2, 1 },
        [5]u32{ 1, 3, 2, 4, 5 },
        [5]u32{ 8, 6, 4, 4, 1 },
        [5]u32{ 1, 3, 6, 7, 9 },
    };

    const expected = [_]bool{ true, false, false, false, false, true };

    for (input, 0..) |a, i| {
        var arr = a;
        const report = Report{
            &arr,
            6,
        };
        const safe = reportIsSafe(report);
        try expect(expected[i] == safe);
    }
}
