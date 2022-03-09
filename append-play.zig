const std = @import("std");
const RndGen = std.rand.DefaultPrng;
const ArrayValHash = @import("./array_val_hash.zig").ArrayValHash(i32, i32);

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rnd = RndGen.init(0);
    var i: i32 = 0;

    var pathHistory = ArrayValHash.init(allocator);
    i = 0;
    while(i < 100) {
        const x = @rem(rnd.random().int(i32), 5);
        try pathHistory.put(x, rnd.random().int(i32));
        i += 1;
    }
    var iterator = pathHistory.pathHistory.iterator();
    while(iterator.next()) |entry| {
        std.debug.print("Result {}=>", .{entry.key_ptr.*});
        for (entry.value_ptr.*.items) |val| {

            std.debug.print("{},", .{val});
        }
        std.debug.print("\n", .{});
    }
}
