const std = @import("std");
const ta = @import("ta_zig");

pub fn main() !void {
    const period = 3;
    const mem_size = 1;
    var ma = ta.SMA(period, mem_size){};
    const serie = [_]f64{112.15, 116.72, 119.21, 117.05, 119.01};
    for (serie) |value| {
        ma.update(value);
    }
    std.debug.print("Moving average: {}\n", .{ma.curr()});
}
