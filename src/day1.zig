const std = @import("std");
const print = std.debug.print;

const ARRSIZE = 5;
pub fn main() !void {
    var total_dist: u32 = 0;

    const infile = try std.fs.cwd().openFile("inputs/day1.txt", .{});
    defer infile.close();

    var br = std.io.bufferedReader(infile.reader());
    const reader = br.reader().any();

    while (nextListPair(reader)) |list_pair| {
        const dist = list_pair.calculateDist();
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

const ListPair = struct {
    list1: [ARRSIZE]u32,
    list2: [ARRSIZE]u32,

    fn calculateDist(self: *const ListPair) u32 {
        std.debug.assert(self.list1.len == self.list2.len);
        const n = self.list1.len;
        var sum: u32 = 0;

        for (0..n) |i| {
            const v1 = self.list1[i];
            const v2 = self.list2[i];
            if (v1 > v2) {
                sum += v1 - v2;
            } else {
                sum += v2 - v1;
            }
        }

        return sum;
    }
};

fn nextListPair(reader: std.io.AnyReader) !ListPair {
    var list1 = [ARRSIZE]u32{ 0, 0, 0, 0, 0 };
    var list2 = [ARRSIZE]u32{ 0, 0, 0, 0, 0 };
    var amt_added: u32 = 0;
    var list1_full = false;
    while (reader.readByte()) |byte| {
        switch (byte) {
            '\n' => {
                if (!list1_full) {
                    continue;
                }
                return ListPair{
                    .list1 = list1,
                    .list2 = list2,
                };
            },

            else => {
                if (asciiByteToU32(byte)) |num| {
                    if (list1_full) {
                        list2[amt_added] = num;
                    } else {
                        list1[amt_added] = num;
                    }
                    amt_added += 1;
                    if (amt_added == ARRSIZE) {
                        list1_full = true;
                        amt_added = 0;
                    }
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
    var list1 = [5]u32{ 4, 2, 1, 3, 3 };
    var list2 = [5]u32{ 3, 5, 3, 9, 3 };
    const pair = ListPair{
        .list1 = list1,
        .list2 = list2,
    };

    std.mem.sort(u32, &list1, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, &list2, {}, comptime std.sort.asc(u32));

    try expect(11 == pair.calculateDist());
}
