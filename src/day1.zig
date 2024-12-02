// I know this is a mess, my goal was to solve this problem
// without ANY heap allocations
// What you're doing wrong is that the input file is TWO lists, not 1000 pairs of lists

const std = @import("std");
const helpers = @import("./helpers.zig");
const print = std.debug.print;

pub fn main() !void {
    const infile = try std.fs.cwd().openFile("inputs/day1.txt", .{});
    defer infile.close();

    var br = std.io.bufferedReader(infile.reader());
    const reader = br.reader().any();

    var list_pair = ListPair.new();
    while (nextNumPair(reader)) |num_pair| {
        list_pair.push(num_pair);
    } else |err| {
        if (err != error.EndOfStream) {
            print("unexpected error: {any}\n", .{err});
            return;
        }
    }

    const dist = ListPair.calculateDist(&list_pair);
    print("total dist: {d}\n", .{dist});

    return;
}

const ARRAY_BUFFER_SIZE = 1024;
const ListPair = struct {
    list1: [ARRAY_BUFFER_SIZE]u32,
    list2: [ARRAY_BUFFER_SIZE]u32,
    len: usize,

    fn new() ListPair {
        var list1: [ARRAY_BUFFER_SIZE]u32 = undefined;
        @memset(&list1, 0);
        var list2: [ARRAY_BUFFER_SIZE]u32 = undefined;
        @memset(&list2, 0);
        return ListPair{
            .list1 = list1,
            .list2 = list2,
            .len = 0,
        };
    }

    const List = enum { one, two };
    fn push(self: *ListPair, pair: NumPair) void {
        const n = self.*.len + 1;
        if (n > ARRAY_BUFFER_SIZE) {
            std.debug.panic("ARRAY_BUFFER_SIZE should be increased, size too large: {d}\n", .{n});
        }
        self.*.list1[self.*.len] = pair[0];
        self.*.list2[self.*.len] = pair[1];
        self.*.len = n;
        return;
    }

    fn calculateDist(self: *ListPair) u64 {
        var sum: u32 = 0;

        for (0..self.len) |_| {
            const min1 = minInSlice(self.list1[0..self.len]);
            const min2 = minInSlice(self.list2[0..self.len]);
            // print("dist between {any} and {any}\n", .{ min1, min2 });
            sum += helpers.absDif(min1[0], min2[0]);

            self.list1[min1[1]] = std.math.maxInt(u32);
            self.list2[min2[1]] = std.math.maxInt(u32);
        }

        return sum;
    }
};

const MinTuple = std.meta.Tuple(&.{ u32, usize });
fn minInSlice(list: []const u32) MinTuple {
    var tup: MinTuple = .{ std.math.maxInt(u32), std.math.maxInt(usize) };
    for (list, 0..) |v, i| {
        if (v < tup[0]) {
            tup[0] = v;
            tup[1] = i;
        }
    }

    return tup;
}

const NumPair = std.meta.Tuple(&.{ u32, u32 });
const VAL_BUFFER_SIZE = 6;
fn nextNumPair(reader: std.io.AnyReader) !NumPair {
    // var lists = ListPair.new();
    var pair = NumPair{ 0, 0 };
    var push_to_list2 = false;

    var val_buffer: [VAL_BUFFER_SIZE]?u32 = undefined;
    @memset(&val_buffer, null);
    var val_buffer_len: u32 = 0;

    while (reader.readByte()) |byte| {
        switch (byte) {
            // whitespace
            ' ', '\n' => {
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
                        if (push_to_list2) {
                            pair[0] += val;
                        } else {
                            pair[1] += val;
                        }
                    } else {
                        break;
                    }
                }

                if (byte == '\n') {
                    break;
                } else {
                    push_to_list2 = true;
                }
            },
            else => {
                if (helpers.asciiByteToU32(byte)) |num| {
                    val_buffer[val_buffer_len] = num;
                    val_buffer_len += 1;
                    // var wh = ListPair.List.one;
                    // if (push_to_list2) {
                    //     wh = ListPair.List.two;
                    // }
                    // lists.push_list(wh, num);
                }
            },
        }
    } else |err| {
        return err;
    }
    return pair;
}

test "small test" {
    const expect = std.testing.expect;

    const l1 = [5]u32{ 4, 2, 1, 3, 3 };
    const l2 = [5]u32{ 3, 5, 3, 9, 3 };

    var pair = ListPair.new();

    for (0..5) |i| {
        const npair = NumPair{ l1[i], l2[i] };
        pair.push(npair);
    }

    const dist = ListPair.calculateDist(&pair);
    print("dist: {d}\n", .{dist});
    try expect(10 == dist);
}
