const std = @import("std");
const helpers = @import("./helpers.zig");
const print = std.debug.print;
const panic = std.debug.panic;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const input = helpers.readToString("inputs/day4.txt", allocator) catch |err| {
        panic("error getting input: {any}\n", .{err});
    };
    defer allocator.free(input);

    return;
}

/// [0]width [1]height
const Coords = std.meta.Tuple(&.{ u32, u32 });

const NR: u8 = 0;
const NL: u8 = 1;
const NT: u8 = 2;
const NTL: u8 = 3;
const NTR: u8 = 4;
const NB: u8 = 5;
const NBL: u8 = 6;
const NBR: u8 = 7;
fn invertNeighborCode(code: u8) u8 {
    return switch (code) {
        NR => NL,
        NL => NR,
        NT => NB,
        NTL => NBR,
        NTR => NBL,
        NB => NT,
        NBL => NTR,
        NBR => NTL,
        else => unreachable,
    };
}

const GridCell = struct {
    ch: u8,
    coords: Coords,
    dims: *const Coords,

    fn countCellOccurences(self: *GridCell, map: *const std.AutoHashMap(Coords, GridCell), substr: []const u8) u32 {
        print("counting for cell char: {c} {d}.{d}\n", .{ self.ch, self.coords[0], self.coords[1] });
        var all: u32 = 0;
        var allocbuffer: [16]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&allocbuffer);
        const allocator = fba.allocator();
        var buffer = allocator.dupe(u8, substr) catch {
            panic("failed to dupe", .{});
        };
        defer allocator.free(buffer);
        @memset(buffer, 0);

        const pattern_pos = helpers.posInString(self.ch, &substr) orelse panic("ch: {c} not in str: {s}\n", .{ self.ch, substr });

        const neighbors: [8]?Coords = self.neighborCoords();
        print("got neighbors: {any}\n", .{neighbors});

        var invert_code = false;
        for (neighbors, 0..) |nopt, c| {
            @memset(buffer, 0);
            buffer[pattern_pos] = self.ch;
            if (nopt) |ncoord| {
                var code: u8 = @intCast(c);
                const str = switch (code) {
                    NR => "NR",
                    NL => "NL",
                    NT => "NT",
                    NTL => "NTL",
                    NTR => "NTR",
                    NB => "NB",
                    NBL => "NBL",
                    NBR => "NBR",
                    else => "other",
                };
                var n = map.get(ncoord) orelse continue;
                const n_pattern_pos = helpers.posInString(n.ch, &substr) orelse continue;
                const dif = helpers.absDif(n_pattern_pos, pattern_pos);
                print("{s} with char {c} dif: {d}\n", .{ str, n.ch, dif });

                if (dif == 1) {
                    print("checking neighbor: {c}\n", .{n.ch});
                    buffer[n_pattern_pos] = n.ch;

                    var ascending = n_pattern_pos > pattern_pos;
                    var next_expected_char_idx: u32 = undefined;

                    if (n_pattern_pos == substr.len - 1 or n_pattern_pos == 0) {
                        if (std.mem.eql(u8, buffer, substr)) {
                            all += 1;
                            print("found! {d}\n", .{all});
                            continue;
                        } else if (n_pattern_pos == 0) {
                            next_expected_char_idx = pattern_pos + 1;
                            ascending = true;
                        } else if (n_pattern_pos == substr.len - 1) {
                            next_expected_char_idx = pattern_pos - 1;
                            ascending = false;
                        }
                        invert_code = !invert_code;
                    } else {
                        next_expected_char_idx = switch (ascending) {
                            true => n_pattern_pos + 1,
                            false => n_pattern_pos - 1,
                        };
                    }

                    if (next_expected_char_idx >= substr.len) {
                        print("breaking, expected char too large: {d}\n", .{next_expected_char_idx});
                        continue;
                    }

                    if (invert_code) {
                        code = invertNeighborCode(code);
                    }

                    var child_neighbors = GridCell.neighborCoords(&n);
                    var child_coords = (child_neighbors[code]) orelse continue;

                    while (true) {
                        var child_neighbor = (map.get(child_coords)) orelse break;
                        child_neighbors = GridCell.neighborCoords(&child_neighbor);
                        print("current child: ({d},{d}) - {c}\n", .{ child_neighbor.coords[0], child_neighbor.coords[1], child_neighbor.ch });
                        print("neighbors: {any}\n", .{child_neighbors});

                        if (next_expected_char_idx < substr.len and child_neighbor.ch == substr[next_expected_char_idx]) {
                            buffer[next_expected_char_idx] = child_neighbor.ch;
                            print("child was expected, buffer updated: {s}\n", .{buffer});

                            if (std.mem.eql(u8, buffer, substr)) {
                                all += 1;
                                print("found! {d}\n", .{all});
                                break;
                            } else {
                                if (ascending) {
                                    if (next_expected_char_idx == substr.len - 1) {
                                        print("too large\n", .{});
                                        break;
                                    }
                                    next_expected_char_idx += 1;
                                } else {
                                    if (next_expected_char_idx == 0) {
                                        print("too small\n", .{});
                                        break;
                                    }
                                    next_expected_char_idx -= 1;
                                }
                            }
                        } else {
                            break;
                        }
                        child_coords = (child_neighbors[code]) orelse break;
                        print("next child: {any}\n", .{map.get(child_coords)});
                    }
                }
            }
        }

        return all;
    }

    fn neighborCoords(self: *GridCell) [8]?Coords {
        var all: [8]?Coords = undefined;
        @memset(&all, null);
        var all_codes: [8]?u8 = undefined;
        var all_codes_len: u8 = 0;
        @memset(&all_codes, null);

        const has_top = self.coords[1] > 1;
        const has_bottom = self.coords[1] < self.dims[1];
        const has_right = self.coords[0] < self.dims[0];
        const has_left = self.coords[0] > 1;

        if (has_top) {
            all_codes[all_codes_len] = NT;
            all_codes_len += 1;
            if (has_right) {
                all_codes[all_codes_len] = NTR;
                all_codes_len += 1;
            }
            if (has_left) {
                all_codes[all_codes_len] = NTL;
                all_codes_len += 1;
            }
        }

        if (has_bottom) {
            all_codes[all_codes_len] = NB;
            all_codes_len += 1;
            if (has_right) {
                all_codes[all_codes_len] = NBR;
                all_codes_len += 1;
            }
            if (has_left) {
                all_codes[all_codes_len] = NBL;
                all_codes_len += 1;
            }
        }

        if (has_right) {
            all_codes[all_codes_len] = NR;
            all_codes_len += 1;
        }

        if (has_left) {
            all_codes[all_codes_len] = NL;
            all_codes_len += 1;
        }

        for (0..all_codes_len) |i| {
            if (all_codes[i]) |code| {
                all[code] = getNeighbor(&self.coords, code);
            }
        }
        return all;
    }
};

fn getNeighbor(coords: *const Coords, code: u8) Coords {
    switch (code) {
        NR => {
            return Coords{
                coords[0] + 1,
                coords[1],
            };
        },
        NL => {
            return Coords{
                coords[0] - 1,
                coords[1],
            };
        },
        NT => {
            return Coords{
                coords[0],
                coords[1] - 1,
            };
        },
        NTL => {
            return Coords{
                coords[0] - 1,
                coords[1] - 1,
            };
        },
        NTR => {
            return Coords{
                coords[0] + 1,
                coords[1] - 1,
            };
        },
        NB => {
            return Coords{
                coords[0],
                coords[1] + 1,
            };
        },
        NBL => {
            return Coords{
                coords[0] - 1,
                coords[1] + 1,
            };
        },
        NBR => {
            return Coords{
                coords[0] + 1,
                coords[1] + 1,
            };
        },
        else => {
            panic("encountered unexpected code: {d}\n", .{code});
        },
    }
}

fn getDims(str: []const u8) Coords {
    var height: u32 = 1;
    var width: u32 = 0;

    for (str) |ch| {
        if (ch == '\n') {
            height += 1;
            width = 0;
        } else {
            width += 1;
        }
    }

    print("got dims w: {d} h: {d}\n", .{ width, height });
    return Coords{ width, height };
}

fn allOccurences(map: *std.AutoHashMap(Coords, GridCell), substr: []const u8) u32 {
    var all: u32 = 0;

    var line: u32 = 1;
    var char: u32 = 1;

    while (true) {
        const key = Coords{ char, line };
        var cell = map.get(key) orelse break;
        all += cell.countCellOccurences(map, substr);
        defer _ = map.remove(key);

        if (char == cell.dims[0]) {
            char = 1;
            line += 1;
        } else {
            char += 1;
        }

        if (line > cell.dims[1]) {
            break;
        }
    }

    return all;
}

fn strToCells(str: []const u8, dims: *const Coords, allocator: std.mem.Allocator) std.AutoHashMap(Coords, GridCell) {
    var map = std.AutoHashMap(Coords, GridCell).init(allocator);
    var line_no: u32 = 1;
    var char_no: u32 = 1;
    var char_bounds: u32 = 0;

    for (str) |ch| {
        if (ch == '\n') {
            line_no += 1;
            char_bounds = char_no;
            char_no = 1;
            continue;
        } else {
            map.put(Coords{ char_no, line_no }, GridCell{
                .coords = Coords{ char_no, line_no },
                .ch = ch,
                .dims = dims,
            }) catch |err| {
                panic("error appending: {any}\n", .{err});
            };
            char_no += 1;
        }
    }

    return map;
}

test "cell test" {
    const expect = std.testing.expect;
    _ = expect;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
    ;

    const dims = getDims(input);
    var cells = strToCells(input, &dims, allocator);
    defer cells.deinit();

    if (cells.get(Coords{ 1, 1 })) |c| {
        var cell = c;
        const ns = GridCell.neighborCoords(&cell);
        var exp: [8]?Coords = undefined;
        @memset(&exp, null);
        exp[NR] = Coords{ 2, 1 };
        exp[NB] = Coords{ 1, 2 };
        exp[NBR] = Coords{ 2, 2 };

        for (ns, 0..) |n, i| {
            var same = false;
            if (n) |unwrapped| {
                if (exp[i]) |expun| {
                    same = unwrapped[0] == expun[0] and unwrapped[1] == expun[1];
                }
            } else {
                same = exp[i] == null;
            }

            if (!same) {
                panic("expected neighbors: {any}\ngot: {any}\n", .{ exp, ns });
            }
        }
    }

    if (cells.get(Coords{ 5, 5 })) |c| {
        var cell = c;
        const l = GridCell.neighborCoords(&cell);
        for (l) |opt| {
            _ = opt orelse panic("should have all neighbors", .{});
        }
    }

    return;
}

test "count test" {
    const expect = std.testing.expect;
    _ = expect;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
    ;

    const dims = getDims(input);
    var cells = strToCells(input, &dims, allocator);
    defer cells.deinit();
    const occ = allOccurences(&cells, "XMAS");
    const exp: u32 = 3;
    if (occ != exp) {
        panic("expected {d} got: {d}\n", .{ exp, occ });
    }
}
