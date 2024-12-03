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
    const all_muls = allMul(&lexer, allocator);
    defer all_muls.deinit();

    for (all_muls.items) |m| {
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
    disable: bool,
    openidx: usize,
    closeidx: usize,
    commaidx: usize,

    fn multiply(self: *MulPair) u32 {
        if (self.disable) {
            return 0;
        }
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
            num += val;
            val_buffer[i] = null;
        } else {
            break;
        }
    }
    return num;
}

fn checkDoOrDont(lexer: *Lexer, disable: *bool) void {
    if (lexer.ch != 'd') {
        return;
    }
    var buf: [6]u8 = undefined;
    @memset(&buf, 0);
    var buflen: usize = 0;

    while (lexer.peek()) |next| {
        if (lexer.ch == ')') {
            switch (buflen) {
                3 => disable.* = false,
                6 => disable.* = true,
                else => {},
            }
            return;
        }
        const next_valid = switch (lexer.ch) {
            'd' => next == 'o',
            'o' => next == 'n' or next == '(',
            'n' => next == '\'',
            '\'' => next == 't',
            't' => next == '(',
            '(' => next == ')',
            else => false,
        };

        if (next_valid) {
            buf[buflen] = lexer.ch;
            buflen += 1;
            lexer.progress();
        } else {
            return;
        }
    }
}

fn allMul(lexer: *Lexer, allocator: std.mem.Allocator) std.ArrayList(MulPair) {
    var buffer = std.ArrayList(MulPair).init(allocator);
    var disable = false;
    while (lexer.peek()) |_| {
        if (nextValidMul(lexer, &disable)) |m| {
            buffer.append(m) catch |err| {
                panic("error appending: {any}", .{err});
            };
        }
    }
    return buffer;
}

fn nextValidMul(lexer: *Lexer, disable: *bool) ?MulPair {
    var openparen: ?usize = null;
    var comma: ?usize = null;
    var buf: [BUFSIZE]u8 = undefined;
    var buflen: usize = 0;
    @memset(&buf, 0);

    while (lexer.peek()) |next| {
        switch (lexer.ch) {
            'd' => {
                checkDoOrDont(lexer, disable);
            },
            ',' => comma = buflen,
            '(' => openparen = buflen,
            ')' => {
                if (std.mem.eql(u8, buf[0..3], "mul") and buflen > 0) {
                    buf[buflen] = lexer.ch;
                    const pair = MulPair{
                        .disable = disable.*,
                        .str = buf,
                        .openidx = openparen orelse return null,
                        .closeidx = buflen,
                        .commaidx = comma orelse return null,
                    };
                    return pair;
                }
            },
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

        lexer.progress();
    }
    return null;
}

test "small test" {
    const expect = std.testing.expect;
    _ = expect;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    const expected: u32 = 48;
    var total: u32 = 0;
    var lexer = Lexer.new(input);
    const all_muls = allMul(&lexer, allocator);
    defer all_muls.deinit();

    for (all_muls.items) |m| {
        var mul = m;
        const v = MulPair.multiply(&mul);
        total += v;
    }
    if (total != expected) {
        panic("expected: {d}\ngot: {d}\n", .{ expected, total });
    }
}
