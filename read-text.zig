const std = @import("std");
const assert = std.debug.assert;
const eql = std.debug.eql;

// parse std as a basic CSV file
// note, I'll need to convert this to tab separated value
// as that was my input
pub fn main() !void {
    var buf: [100]u8 = undefined;
    const stdin = std.io.getStdIn().reader();
    while (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |line| { 
        var it = std.mem.tokenize(u8, line, ",");
        while (it.next()) |item| {
            std.debug.print("{s}\n", .{item});
        }
    }
}

