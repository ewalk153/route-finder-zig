const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn ArrayValHash(comptime K: type, comptime VItem: type) type {
    return struct {
        allocator: Allocator,
        pathHistory: std.AutoHashMap(K, ArrayList(VItem)),

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .pathHistory = std.AutoHashMap(K, ArrayList(VItem)).init(allocator),
            };
        }
        pub fn putNext(self: *Self, key: K, lastKey: K, val: VItem) !void {
            var v = try self.pathHistory.getOrPut(lastKey);
            var items: ArrayList(VItem) = undefined;
            if (!v.found_existing) {
                items = ArrayList(VItem).init(self.allocator);
            } else {
                items = v.value_ptr.*;
            }
            try items.append(val);
            v = try self.pathHistory.getOrPut(key);
            if (!v.found_existing) {
                v.value_ptr.* = items;
            }
        }
        pub fn putAll(self: *Self, key: K, val: ArrayList(VItem)) !void {
            try self.pathHistory.put(key, val);
        }
        pub fn get(self: *Self, key: K) ArrayList(VItem) {
            if(self.pathHistory.get(key)) |item| {
                return item;
            }
            return ArrayList(VItem).init(self.allocator);
        }
        pub fn put(self: *Self, key: K, val: VItem) !void {
            var v = try self.pathHistory.getOrPut(key);
            if (!v.found_existing) {
                v.value_ptr.* = ArrayList(VItem).init(self.allocator);
            }
            try v.value_ptr.*.append(val);
        }
        // TODO implement deinit to clean up values on destruction
    };
}