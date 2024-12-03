const std = @import("std");
const helpers = @import("./helpers.zig");
const print = std.debug.print;
const panic = std.debug.panic;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const input = helpers.readToString("inputs/day3.txt", allocator) catch |err| {
        panic("error getting input: {any}\n", .{err});
    };
    defer allocator.free(input);

    var total: u32 = 0;
    var lexer = Lexer.new(input);
    while (nextValidMul(&lexer)) |m| {
        var mul = m;
        const v = MulPair.multiply(&mul);
        total += v;
    }
    print("total: {d}\n", .{total});
    return;
}

const Lexer = struct {
    input: []const u8,
    pos: usize,
    read_pos: usize,
    ch: u8,
    fn new(input: []const u8) Lexer {
        var l = Lexer{
            .input = input,
            .pos = 0,
            .read_pos = 0,
            .ch = 0,
        };
        l.progress();
        return l;
    }

    fn progress(self: *Lexer) void {
        if (self.read_pos >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_pos];
        }
        self.pos = self.read_pos;
        self.read_pos += 1;
    }

    fn peek(self: *Lexer) ?u8 {
        if (self.read_pos >= self.input.len) {
            return null;
        }
        return self.input[self.read_pos];
    }
};

const BUFSIZE = 16;
const MulPair = struct {
    str: [BUFSIZE]u8,
    openidx: usize,
    closeidx: usize,
    commaidx: usize,

    fn multiply(self: *MulPair) u32 {
        var val_buffer: [VALBUFFER_SIZE]?u32 = undefined;
        @memset(&val_buffer, null);
        var val_buffer_len: u32 = 0;

        for (self.str[self.openidx..self.commaidx]) |ch| {
            if (helpers.asciiByteToU32(ch)) |n| {
                val_buffer[val_buffer_len] = n;
                val_buffer_len += 1;
            }
        }

        const first_num = u32FromValueBuffer(&val_buffer, &val_buffer_len);

        for (self.str[self.commaidx..self.closeidx]) |ch| {
            if (helpers.asciiByteToU32(ch)) |n| {
                val_buffer[val_buffer_len] = n;
                val_buffer_len += 1;
            }
        }

        const second_num = u32FromValueBuffer(&val_buffer, &val_buffer_len);
        print("first num: {d}\nsecond num: {d}\n", .{ first_num, second_num });
        return first_num * second_num;
    }
};

const VALBUFFER_SIZE = 5;
fn u32FromValueBuffer(val_buffer: *[VALBUFFER_SIZE]?u32, len: *u32) u32 {
    var num: u32 = 0;
    for (0..len.*) |i| {
        if (val_buffer[i]) |v| {
            if (len.* > 0) {
                len.* -= 1;
            }
            var factor: u32 = 1;
            for (0..len.*) |_| {
                factor *= 10;
            }

            const val: u32 = v * factor;
            // print("new num += {d}\n", .{val});
            num += val;
            val_buffer[i] = null;
        } else {
            break;
        }
    }
    return num;
}

fn nextValidMul(lexer: *Lexer) ?MulPair {
    var openparen: ?usize = null;
    var closeparen: ?usize = null;
    var comma: ?usize = null;
    var buf: [BUFSIZE]u8 = undefined;
    var buflen: usize = 0;
    @memset(&buf, 0);

    while (lexer.peek()) |next| {
        if (lexer.ch == ')' and buflen > 0 and std.mem.eql(u8, buf[0..3], "mul")) {
            closeparen = buflen;
            buf[buflen] = lexer.ch;
            return MulPair{
                .str = buf,
                .openidx = openparen orelse return null,
                .closeidx = closeparen orelse return null,
                .commaidx = comma orelse return null,
            };
        } else {
            switch (lexer.ch) {
                ',' => comma = buflen,
                '(' => openparen = buflen,
                else => {},
            }
            const next_valid = switch (lexer.ch) {
                'm' => next == 'u',
                'u' => next == 'l',
                'l' => next == '(',
                ',', '(' => switch (next) {
                    48...57 => true,
                    else => false,
                },
                48...57 => switch (next) {
                    ',', 48...57, ')' => true,
                    else => false,
                },
                else => false,
            };
            if (next_valid) {
                buf[buflen] = lexer.ch;
                buflen += 1;
            } else {
                buflen = 0;
            }
        }

        lexer.progress();
    }
    return null;
}

test "small test" {
    const expect = std.testing.expect;
    const input = "xmul(2,4)%&mul[3,7]select(255,530)!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    const expected: u32 = 161;
    var total: u32 = 0;
    var lexer = Lexer.new(input);
    while (nextValidMul(&lexer)) |m| {
        var mul = m;
        const v = MulPair.multiply(&mul);
        total += v;
    }
    try expect(total == expected);
    // var sum: u32 = 0;
}
