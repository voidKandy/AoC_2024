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
