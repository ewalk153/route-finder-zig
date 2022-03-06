// const PriorityQueue = @import("std/priority_queue.zig");
const std = @import("std");
const Order = std.math.Order;

const Node = struct {
    name: []const u8,
    id: i32,

    pub fn format(
        self: Node,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("({}-{s}", .{
            self.id, self.name,
        });

        try writer.writeAll(")");
    }
};

const Edge = struct {
    start: i32,
    end: i32,
    cost: i32,
};

pub fn NodeVisit() type {
    return struct {
        const Self = @This();
        
        cost: usize,

        pub fn init(cost: usize) Self {
            return Self{
                .cost = cost,
            };
        }
    };
}

pub fn readNodes(filename: []const u8) !void {
    const ArrayList = std.ArrayList;
    const test_allocator = std.testing.allocator;
    const fmt = std.fmt;
    var file = try std.fs.cwd().openFile(filename, .{});
    var buf: [100]u8 = undefined;
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    while (try in_stream.readUntilDelimiterOrEof(buf[0..], '\n')) |line| { 
        var it = std.mem.tokenize(u8, line, ",");
        var id: i32 = 0;
        var list = ArrayList(u8).init(test_allocator);
        if (it.next()) |item| {
            id = try fmt.parseUnsigned(i32, item, 10);
        }
        if (it.next()) |item| {
            try list.appendSlice(item);
            _ = item;
        }
        const node = Node{
            .id = id,
            .name = list.items,
        };
        std.debug.print("{s}\n", .{node});
        // while (it.next()) |item| {
        //     std.debug.print("{s}\n", .{item});
        // }
        std.debug.print("====\n", .{});
    }
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll("hello world");
    try readNodes("../nodes.csv");

}
