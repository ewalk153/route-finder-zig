const std = @import("std");
const Edge = @import("./edge.zig").Edge;
const Node = @import("./node.zig").Node;
const ArrayList = std.ArrayList;
const mem = std.mem;
const io = std.io;
const Allocator = mem.Allocator;
const Order = std.math.Order;
const PathHistoryHash = @import("./array_val_hash.zig").ArrayValHash(i32, GraphEdge);

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
            try name.appendSlice(mem.trimRight(u8, item, std.ascii.spaces[0..]));
        }
        if (it.next()) |item| {
            try startStation.appendSlice(mem.trimRight(u8, item, std.ascii.spaces[0..]));
        }
        if (it.next()) |item| {
            try endStation.appendSlice(mem.trimRight(u8, item, std.ascii.spaces[0..]));
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
        var first = true;
        for (lines) |line| {
            if(first) {
                first = false;
                continue;
            }
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
                    if (line.oneWay == 0 or line.oneWay == -1) {
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
                    if (line.oneWay == 0 or line.oneWay == 1) {
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
    maxId: i32,

    const Self = @This();

    pub fn build(allocator: Allocator, routeEdges: ArrayList(Edge)) !Self {
        var edges = std.AutoHashMap(i32, ArrayList(GraphEdge)).init(allocator);
        var maxId: i32 = 0;
        for(routeEdges.items) |routeEdge| {
            var line = ArrayList([]const u8).init(allocator);
            try line.append(routeEdge.line);
            const e = GraphEdge {
                .startId = routeEdge.start,
                .endId = routeEdge.end,
                .cost = routeEdge.cost,
                .line = line,
            };
            if(routeEdge.start > maxId ){
                maxId = routeEdge.start;
            }
            if(routeEdge.end > maxId) {
                maxId = routeEdge.end;
            }

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
            .maxId = maxId,
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
    pub const routeHistory = struct {
        cost: i32,
        path: []const(GraphEdge),
    };
    pub fn route(self: Graph, allocator: Allocator, source: i32, destination: i32) !routeHistory {
        var dist = std.AutoHashMap(i32, i32).init(allocator);
        var pathH = PathHistoryHash.init(allocator);
        const PQltNode = std.PriorityQueue(CostNode, void, lessThan);
        var q = PQltNode.init(allocator, {});
        try q.add(CostNode{
            .id = source,
            .cost = 0,
        });

        while(q.removeOrNull()) |val| {
            var currentPath = pathH.get(val.id);
            var currentEdgeLine = ArrayList([]const u8).init(allocator);
            if(currentPath.items.len > 0) {
                currentEdgeLine = currentPath.items[currentPath.items.len - 1].line;
            }
            if(val.id == destination) {
                return routeHistory {
                    .cost = val.cost,
                    .path = currentPath.items,
                };
            }
            if(dist.get(val.id)) |last_cost| {
                if(val.cost >= last_cost) {
                    continue;
                }
            }
            try dist.put(val.id, val.cost);
            if (self.edges.get(val.id)) |paths| {
                for(paths.items) |path| {
                    if(dist.get(path.endId)) |_| {
                        continue;
                    }
                    var newPath = ArrayList(GraphEdge).init(allocator);
                    try newPath.appendSlice(currentPath.items);
                    try newPath.append(path);
                    try pathH.putAll(path.endId, newPath);
                    var switchCost: i32 = 0;
                    if(!matchedString(currentEdgeLine, path.line)) {
                        switchCost = 15;
                    }

                    try q.add(CostNode{
                        .id = path.endId,
                        .cost = val.cost + path.cost + switchCost,
                    });
                }
            }
        }
        return routeHistory {
            .cost = -1,
            .path = &[_]GraphEdge{},
        };
    }

    pub fn multiRoute(self: Graph, allocator: Allocator, source: i32) !RouteResults {
        var dist = std.AutoHashMap(i32, i32).init(allocator);
        var pathH = PathHistoryHash.init(allocator);
        const PQltNode = std.PriorityQueue(CostNode, void, lessThan);
        var q = PQltNode.init(allocator, {});
        try q.add(CostNode{
            .id = source,
            .cost = 0,
        });

        while(q.removeOrNull()) |val| {
            var currentPath = pathH.get(val.id);
            var currentEdgeLine = ArrayList([]const u8).init(allocator);
            if(currentPath.items.len > 0) {
                currentEdgeLine = currentPath.items[currentPath.items.len - 1].line;
            }
            if(dist.get(val.id)) |last_cost| {
                if(val.cost >= last_cost) {
                    continue;
                }
            }
            try dist.put(val.id, val.cost);
            if (self.edges.get(val.id)) |paths| {
                for(paths.items) |path| {
                    if(dist.get(path.endId)) |_| {
                        continue;
                    }
                    var newPath = ArrayList(GraphEdge).init(allocator);
                    try newPath.appendSlice(currentPath.items);
                    try newPath.append(path);
                    try pathH.putAll(path.endId, newPath);
                    var switchCost: i32 = 0;
                    if(!matchedString(currentEdgeLine, path.line)) {
                        switchCost = 15;
                    }

                    try q.add(CostNode{
                        .id = path.endId,
                        .cost = val.cost + path.cost + switchCost,
                    });
                }
            }
        }
        return RouteResults{
            .costs = dist,
            .paths = pathH,
        };
    }
};

pub const RouteResults = struct {
    costs: std.AutoHashMap(i32, i32),
    paths: PathHistoryHash,
};

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

fn printMatrix(allocator: Allocator, g: Graph) !void {
    var i: i32 = 0;
    var j: i32 = 0;
    while(i < g.maxId) : (i += 1) {
        var result = try g.multiRoute(allocator, i);
        j = 0;
        while(j < g.maxId) : (j += 1) {
            if(j > 0) {
                print(",", .{});
            }
            if(result.costs.get(j)) |val| {
                print("{}", .{val});
            } else {
                print("\nWARNING...{}->{} unreachable....\n\n", .{i, j});
            }
        }
        print("\n", .{});
    }
}

fn traverseGraph(allocator: Allocator, g: Graph) !void {
    // if (g.edges.get(10)) |paths| {
    //     std.debug.print("{s}\n", .{paths.items});
    // } else {
    //     std.debug.print("Nothing found for 0\n", .{});
    // }

    // std.debug.print("{}\n", .{g.edges.count()});

    var result = try g.route(allocator, 1, 216);

    std.debug.print("Cost: {}\n", .{result.cost});

    // clearly, there is a bug in either our route finding, and/or backtrack checking
    for(result.path) |el| {
        std.debug.print("Step: {}->{}\n", .{el.startId, el.endId});
    }

    std.debug.print("{}\n", .{result.path.len});

    var result2 = try g.multiRoute(allocator, 1);
    _ = result2;
    var it = result2.costs.iterator();
    while(it.next()) |entry| {
        std.debug.print("{}=>{}\n", .{entry.key_ptr.*, entry.value_ptr.*});
    }
    var i: i32 = 1;
    while(i < g.maxId) : (i += 1) {
        std.debug.print("{},{}\n", .{i, result2.costs.get(i).?}); //
    }
    std.debug.print("\n", .{});
}

fn cmpByNode(_: void, a: Node, b: Node) bool {
    return a.id < b.id;
}

fn printNodes(structures: Structure) !void {
    var nodes = structures.nodes;
    var x = nodes.toOwnedSlice();
    std.sort.sort(Node, x, {}, cmpByNode);
    for(x) |node| {
        print("{},{s}\n", .{node.id, node.name});
    }
}

fn cmpByEdge(_: void, a: Edge, b: Edge) bool {
    return a.start < b.start;
}

fn printEdges(structures: Structure) !void {
    var edges = structures.edges;
    var x = edges.toOwnedSlice();
    std.sort.sort(Edge, x, {}, cmpByEdge);
    for(x) |edge| {
        print("{s},{},{}\n", .{edge.line, edge.start, edge.end});
    }
}

var stdout_mutex = std.Thread.Mutex{};
pub fn print(comptime fmt: []const u8, args: anytype) void {
    stdout_mutex.lock();
    defer stdout_mutex.unlock();
    const stdout = io.getStdOut().writer();
    nosuspend stdout.print(fmt, args) catch return;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // // parse doc into line, source, destination, directionality (bi)
    var lines = try readLines(allocator, "./lines.csv");
    // // std.debug.print("{s}\n", .{lines});

    // // build index of locations along the way
    var structures = try Structure.build(allocator, lines);
    try printNodes(structures);
    try printEdges(structures);

    var g = try Graph.build(allocator, structures.edges);
    _ = g;

    // try traverseGraph(allocator, g);

    // try printMatrix(allocator, g);

    std.debug.print("done\n", .{});
}
