const std = @import("std");
const print = std.debug.print;
const mem = std.mem; // will be used to compare bytes
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn matchedString(first: ArrayList([]const u8), second: ArrayList([]const u8)) bool {
    for(first.items) |fItem| {
        for(second.items) |sItem| {
            if (mem.eql(u8, fItem, sItem)) {
                return true;
            }
        }
    }
    return false;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const bytes = "hello";
    print("{s}\n", .{@typeName(@TypeOf(bytes))});       // *const [5:0]u8
    print("{d}\n", .{bytes.len});                       // 5
    print("{c}\n", .{bytes[1]});                        // 'e'
    print("{d}\n", .{bytes[5]});                        // 0
    print("{}\n", .{'e' == '\x65'});                    // true
    print("{d}\n", .{'\u{1f4a9}'});                     // 128169
    print("{d}\n", .{'💯'});                            // 128175
    print("{}\n", .{mem.eql(u8, "hello", "h\x65llo")}); // true
    print("0x{x}\n", .{"\xff"[0]}); // non-UTF-8 strings are possible with \xNN notation.
    print("{u}\n", .{'⚡'});

    var first = ArrayList([]const u8).init(allocator);
    try first.append("first");
    try first.append("second");
    var second = ArrayList([]const u8).init(allocator);
    try second.append("third");
    try second.append("boyo");

    print("Matched? {s}\n", .{matched(first, second)});
}
