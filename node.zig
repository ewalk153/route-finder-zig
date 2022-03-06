const std = @import("std");

pub const Node = struct {
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

        try writer.print("({}-{s})", .{
            self.id, self.name,
        });
    }
};
