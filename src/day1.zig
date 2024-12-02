// I know this is a mess, my goal was to solve this problem
// without ANY heap allocations
// What you're doing wrong is that the input file is TWO lists, not 1000 pairs of lists

const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var total_dist: u64 = 0;

    const infile = try std.fs.cwd().openFile("inputs/day1.txt", .{});
    defer infile.close();

    var br = std.io.bufferedReader(infile.reader());
    const reader = br.reader().any();

    while (nextNumPair(reader)) |list_pair| {
        var pair = list_pair;
        const dist = NumPair.calculateDist(&pair);
        total_dist += dist;
    } else |err| {
        if (err != error.EndOfStream) {
            print("unexpected error: {any}\n", .{err});
            return;
        }
    }
    print("total dist: {d}\n", .{total_dist});

    return;
}

const ARRAY_BUFFER_SIZE = 10;
const NumPair = struct {
    list1: [ARRAY_BUFFER_SIZE]u32,
    list1_len: usize,
    list2: [ARRAY_BUFFER_SIZE]u32,
    list2_len: usize,

    fn new() NumPair {
        var list1: [ARRAY_BUFFER_SIZE]u32 = undefined;
        @memset(&list1, 0);
        var list2: [ARRAY_BUFFER_SIZE]u32 = undefined;
        @memset(&list2, 0);
        return NumPair{
            .list1 = list1,
            .list1_len = 0,
            .list2 = list2,
            .list2_len = 0,
        };
    }

    const List = enum { one, two };
    fn push_list(self: *NumPair, which: List, v: u32) void {
        // print("pushing {d} to list {any} of: {any}\n", .{ v, which, self });
        switch (which) {
            List.one => {
                const n = self.*.list1_len + 1;
                if (n > ARRAY_BUFFER_SIZE) {
                    std.debug.panic("ARRAY_BUFFER_SIZE should be increased, size too large: {d}\n", .{n});
                }
                self.*.list1[self.*.list1_len] = v;
                self.*.list1_len = n;
            },
            List.two => {
                const n = self.*.list2_len + 1;
                if (n > ARRAY_BUFFER_SIZE) {
                    std.debug.panic("ARRAY_BUFFER_SIZE should be increased, size too large: {d}\n", .{n});
                }
                self.*.list2[self.*.list2_len] = v;
                self.*.list2_len = n;
            },
        }
        return;
    }

    fn calculateDist(self: *NumPair) u64 {
        std.debug.assert(self.list1_len == self.list2_len);
        const n = self.list1_len;
        var sum: u32 = 0;

        for (0..n) |_| {
            const min1 = minInSlice(self.list1[0..n]);
            const min2 = minInSlice(self.list2[0..n]);

            if (min1[0] > min2[0]) {
                sum += min1[0] - min2[0];
            } else {
                sum += min2[0] - min1[0];
            }

            self.list1[min1[1]] = 9999;
            self.list2[min2[1]] = 9999;
        }

        return sum;
    }
};

const MinTuple = std.meta.Tuple(&.{ u32, usize });
fn minInSlice(list: []const u32) MinTuple {
    var tup: MinTuple = .{ 999, 999 };
    for (list, 0..) |v, i| {
        if (v < tup[0]) {
            tup[0] = v;
            tup[1] = i;
        }
    }

    return tup;
}

fn nextNumPair(reader: std.io.AnyReader) !NumPair {
    var lists = NumPair.new();
    var push_to_list2 = false;
    while (reader.readByte()) |byte| {
        switch (byte) {
            // whitespace
            9...12 | 32 => {
                if (byte == '\n') {
                    if (!push_to_list2) {
                        continue;
                    } else {
                        return lists;
                    }
                }
                push_to_list2 = true;
            },
            else => {
                if (asciiByteToU32(byte)) |num| {
                    var wh = NumPair.List.one;
                    if (push_to_list2) {
                        wh = NumPair.List.two;
                    }
                    lists.push_list(wh, num);
                }
            },
        }
    } else |err| {
        return err;
    }
}

fn asciiByteToU32(byte: u8) ?u32 {
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

test "small test" {
    const expect = std.testing.expect;
    const l1 = [5]u32{ 4, 2, 1, 3, 3 };
    const l2 = [5]u32{ 3, 5, 3, 9, 3 };

    var pair = NumPair.new();

    for (l1) |v| {
        pair.push_list(NumPair.List.one, v);
    }
    for (l2) |v| {
        pair.push_list(NumPair.List.two, v);
    }

    const dist = NumPair.calculateDist(&pair);
    print("dist: {d}\n", .{dist});
    try expect(10 == dist);
}
