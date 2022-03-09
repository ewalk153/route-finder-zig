const std = @import("std");
const Edge = @import("./edge.zig").Edge;
const Node = @import("./node.zig").Node;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Order = std.math.Order;

pub fn readLines(allocator: Allocator, filename: []const u8) ![]const LineTime {
    var lines = ArrayList(LineTime).init(allocator);

    var file = try std.fs.cwd().openFile(filename, .{});
    var buf: [1000]u8 = undefined;
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    while (try in_stream.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        try lines.append(try LineTime.parse(line));
    }
    return lines.items;
}

const LineTime = struct {
    name: []const u8,
    startStation: []const u8,
    endStation: []const u8,
    duration: i32,
    oneWay: i32 = 0,

    pub fn parse(line: []const u8) !LineTime {
        const test_allocator = std.testing.allocator;
        var name = ArrayList(u8).init(test_allocator);
        var startStation = ArrayList(u8).init(test_allocator);
        var endStation = ArrayList(u8).init(test_allocator);
        var duration: i32 = 0;
        var oneWay: i32 = 0;

        var it = std.mem.tokenize(u8, line, "\t");

        if (it.next()) |item| {
            try name.appendSlice(item);
        }
        if (it.next()) |item| {
            try startStation.appendSlice(item);
        }
        if (it.next()) |item| {
            try endStation.appendSlice(item);
        }
        if (it.next()) |item| {
            var timeSplit = std.mem.split(u8, item, ":");
            _ = timeSplit.next();
            if (timeSplit.next()) |time| {
                duration = std.fmt.parseInt(i32, time, 10) catch 0;
            }
        }
        if (it.next()) |item| {
            oneWay = std.fmt.parseInt(i32, item, 10) catch 0;
        }

        return LineTime {
            .name = name.items,
            .startStation = startStation.items,
            .endStation = endStation.items,
            .duration = duration,
            .oneWay = oneWay,
        };
    }

    pub fn format(
        self: LineTime,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("({s}-{s}->{s},{},{})", .{
            self.name,
            self.startStation,
            self.endStation,
            self.duration,
            self.oneWay,
        });
    }
};
const Structure = struct {
    nodes: ArrayList(Node),
    edges: ArrayList(Edge),

    const Self = @This();

    pub fn build(allocator: Allocator, lines: []const LineTime) !Structure {
        var nodeMap = std.StringHashMap(Node).init(allocator);
        var i: i32 = 0;
        for (lines) |line| {
            var v = try nodeMap.getOrPut(line.startStation);
            if (!v.found_existing) {
                v.value_ptr.* = Node {
                    .name = line.startStation,
                    .id = i,
                };
                i += 1;
            }
        }

        var edges = ArrayList(Edge).init(allocator);
        for (lines) |line| {
            if (nodeMap.get(line.startStation)) |startNode| {
                if (nodeMap.get(line.endStation)) |endNode| {
                    if (line.oneWay == 0 or line.oneWay == 1) {
                        try edges.append(
                            Edge {
                                .start = startNode.id,
                                .end = endNode.id,
                                .line = line.name,
                                .cost = line.duration,
                            }
                        );
                    }
                }
                if (nodeMap.get(line.endStation)) |endNode| {
                    if (line.oneWay == 0 or line.oneWay == -1) {
                        try edges.append(
                            Edge {
                                .start = endNode.id,
                                .end = startNode.id,
                                .line = line.name,
                                .cost = line.duration,
                            }
                        );
                    }
                }
            }
        }

        var nodes = ArrayList(Node).init(allocator);
        var allNodes = nodeMap.iterator();
        while(allNodes.next()) |entry| {
            try nodes.append(entry.value_ptr.*);
        }
        return Self {
            .nodes = nodes,
            .edges = edges,
        };
    }
};

// edge lookup
// build a hash that returns the list of next destinations
// Key: i32, value: arrayList of Edges, with costs

pub const GraphEdge = struct {
    startId: i32,
    endId: i32,
    cost: i32,
    line: ArrayList([]const u8),
};

const Graph = struct {
    edges: std.AutoHashMap(i32, ArrayList(GraphEdge)),

    const Self = @This();

    pub fn build(allocator: Allocator, routeEdges: ArrayList(Edge)) !Self {
        var edges = std.AutoHashMap(i32, ArrayList(GraphEdge)).init(allocator); 
        for(routeEdges.items) |routeEdge| {
            var line = ArrayList([]const u8).init(allocator);
            try line.append(routeEdge.line);
            const e = GraphEdge {
                .startId = routeEdge.start,
                .endId = routeEdge.end,
                .cost = routeEdge.cost,
                .line = line,
            };

            var v = try edges.getOrPut(routeEdge.start);
            if (!v.found_existing) {
                v.value_ptr.* = ArrayList(GraphEdge).init(allocator);
                try v.value_ptr.*.append(e);
            } else {
                var found = false;
                for(v.value_ptr.*.items) |edge, i| {
                    if(edge.endId == routeEdge.end) {
                        found = true;
                        var e2 = edge;
                        try e2.line.append(routeEdge.line);
                        var newEdgeList = [_]GraphEdge{e2};
                        try v.value_ptr.*.replaceRange(i, 0, &newEdgeList);
                        break;
                    }
                }
                if (!found) {
                    try v.value_ptr.*.append(e);
                } else {
                    // todo, debug to confirm lists are properly replaced
                    // std.debug.print("Second path found for element {s}\n", .{e});
                }
            }
        }
        return Self {
            .edges = edges,
        };
    }

    const CostNode = struct {
        id: i32,
        cost: i32,
    };

    fn lessThan(context: void, a: CostNode, b: CostNode) Order {
        _ = context;
        return std.math.order(a.cost, b.cost);
    }

    // add switch costs for lines, onces there is more than one
    // line
    // convert to multi-path
    pub fn route(self: Graph, allocator: Allocator, source: i32, destination: i32) !i32 {
        var dist = std.AutoHashMap(i32, i32).init(allocator);
        const PQltNode = std.PriorityQueue(CostNode, void, lessThan);
        var q = PQltNode.init(allocator, {});
        try q.add(CostNode{
            .id = source, 
            .cost = 0,
        });

        while(q.removeOrNull()) |val| {
            if(val.id == destination) {
                return val.cost;
            }
            if(dist.get(val.id)) |x| {
                _ = x;
                continue;
            }
            try dist.put(val.id, val.cost);
            if (self.edges.get(val.id)) |paths| {
                for(paths.items) |path| {
                    if(dist.get(path.endId)) |x| {
                        _ = x;
                        continue;
                    }
                    try q.add(CostNode{
                        .id = path.endId,
                        .cost = val.cost + path.cost,
                    });
                }
            }
        }
        return -1;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // // parse doc into line, source, destination, directionality (bi)
    var lines = try readLines(allocator, "./lines.csv");
    // // std.debug.print("{s}\n", .{lines});

    // // build index of locations along the way
    var structures = try Structure.build(allocator, lines);
    // // write out nodes and edges based on index
    // std.debug.print("{s}\n", .{structures.nodes.items});
    // std.debug.print("{s}\n", .{structures.edges.items});

    var g = try Graph.build(allocator, structures.edges);

    if (g.edges.get(10)) |paths| {
        std.debug.print("{s}\n", .{paths.items});
    } else {
        std.debug.print("Nothing found for 0\n", .{});
    }

    // std.debug.print("{}\n", .{g.edges.count()});

    var cost = try g.route(allocator, 1, 216);

    std.debug.print("{}\n", .{cost});

    std.debug.print("done\n", .{});
}
