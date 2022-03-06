// const PriorityQueue = @import("std/priority_queue.zig");
const std = @import("std");
const Order = std.math.Order;

pub fn ToyNode() type {
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

fn lessThan(context: void, a: u32, b: u32) Order {
    _ = context;
    return std.math.order(a, b);
}

fn lessThanToyNode(context: void, a: ToyNode(), b: ToyNode()) Order {
    _ = context;
    return std.math.order(a.cost, b.cost);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;
    const PQlt = std.PriorityQueue(u32, void, lessThan);

    const PQltNode = std.PriorityQueue(ToyNode(), void, lessThanToyNode);
    var queue = PQlt.init(allocator, {});

    var queueNode = PQltNode.init(allocator, {});

    try stdout.writeAll("Hello world\n");

    defer queue.deinit();

    try queue.add(54);
    try queue.add(12);
    try queue.add(7);
    try queue.add(23);
    try queue.add(25);
    try queue.add(13);

    try stdout.print("{d}\n", .{queue.remove()});
    try stdout.print("{d}\n", .{queue.remove()});
    try stdout.print("{d}\n", .{queue.remove()});
    try stdout.print("{d}\n", .{queue.remove()});
    try stdout.print("{d}\n", .{queue.remove()});
    try stdout.print("{d}\n", .{queue.remove()});
    try stdout.print("{d}\n", .{queue.removeOrNull()});

    try queueNode.add(ToyNode().init(54));
    try queueNode.add(ToyNode().init(12));
    try queueNode.add(ToyNode().init(7));
    try queueNode.add(ToyNode().init(23));
    try queueNode.add(ToyNode().init(25));
    try queueNode.add(ToyNode().init(15));

    try stdout.print("{d}\n", .{queueNode.remove()});
    try stdout.print("{d}\n", .{queueNode.remove()});
    try stdout.print("{d}\n", .{queueNode.remove()});
    try stdout.print("{d}\n", .{queueNode.remove()});
    try stdout.print("{d}\n", .{queueNode.remove()});
    try stdout.print("{d}\n", .{queueNode.remove()});
    
    // try expectEqual(@as(u32, 7), queue.remove());
    // try expectEqual(@as(u32, 12), queue.remove());
    // try expectEqual(@as(u32, 13), queue.remove());
    // try expectEqual(@as(u32, 23), queue.remove());
    // try expectEqual(@as(u32, 25), queue.remove());
    // try expectEqual(@as(u32, 54), queue.remove());
}
