const std = @import("std");
// fails with compile error
pub fn fileReader() !std.io.BufferedReader(4096, std.fs.File.Reader) {
    var file = try std.fs.cwd().openFile("./lines.csv", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    return buf_reader;
}

pub fn main() !void {
    _ = try fileReader();
}
