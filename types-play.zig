const std = @import("std");
pub fn Foo() type {
    return struct {
        a: i32 = 7,
    };
}
pub const Bar = struct {
    a: i32 = 5,
};

pub fn main() !void {
    var z = Foo(){};
    std.debug.print("{s}\n", .{z});
    var x = Bar{};
    std.debug.print("{s}\n", .{x});

    var q = .{
        .a = @as(i32, 3),
    };
    std.debug.print("{s}\n", .{q});

}