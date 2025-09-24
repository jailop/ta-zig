const std = @import("std");
const nan = std.math.nan(f64);
const sqrt = std.math.sqrt;
const Indicator = @import("base.zig").Indicator;
const SMAvg = @import("trend.zig").SMAvg;

pub fn SMVar(periods: usize, dof: u8, mem_size: usize) type {
    return struct {
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},
        ma: SMAvg(periods, 1) = SMAvg(periods, 1){},
        prev_values: [periods]f64 = [_]f64{nan} ** periods,
        pos: usize = 0,
        length: usize = 0,
        sum: f64 = 0.0,

        const Self = SMVar(periods, dof, mem_size);

        pub fn update(self: *Self, value: f64) void {
            if (self.length < periods) {
                self.length += 1;
            }
            self.prev_values[self.pos] = value;
            self.ma.update(value);
            self.pos = (self.pos + 1) % periods;
            if (self.length < periods) {
                self.data.push(std.math.nan(f64));
            } else {
                self.sum = 0.0;
                for (self.prev_values) |v| {
                    const diff = v - self.ma.curr();
                    self.sum += diff * diff;
                }
                self.data.push(self.sum / (periods - dof));
            }
        }

        pub inline fn curr(self: Self) f64 {
            return self.data.curr();
        }

        pub inline fn get(self: Self, offset: usize) f64 {
            return self.data.get(offset);
        }
    };
}

pub fn SMStdDev(periods: usize, dof: u8, mem_size: usize) type {
    return struct {
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},
        variance: SMVar(periods, dof, mem_size) =
            SMVar(periods, dof, mem_size){},

        const Self = SMStdDev(periods, dof, mem_size);
                  
        pub inline fn update(self: *Self, value: f64) void {
            self.variance.update(value);
            self.data.push(sqrt(self.variance.curr()));
        }

        pub inline fn curr(self: Self) f64 {
            return self.data.curr();
        }

        pub inline fn get(self: Self, offset: usize) f64 {
            return self.data.get(offset);
        }
    };
}

pub fn ATR(periods: usize, mem_size: usize) type {
    return struct {

        data: SMAvg(periods, mem_size) = SMAvg(periods, mem_size){},

        const Self = ATR(periods, mem_size);

        pub fn update(self: *Self, high: f64, low: f64, close: f64) void {
            const high_low = high - low;
            const high_close = if (high > close) high - close else close - high;
            const low_close = if (low > close) low - close else close - low;
            const tr = 
                if (high_low > high_close and high_low > low_close) high_low
                else if (high_close > low_close) high_close
                else low_close;
            self.data.update(tr);
        }

        pub inline fn curr(self: Self) f64 {
            return self.data.curr();
        }

        pub inline fn get(self: Self, offset: usize) f64 {
            return self.data.get(offset);
        }
    };
}

test "Moving Variance" {
    var mv = SMVar(3, 0, 5){};
    mv.update(1.0);
    mv.update(2.0);
    mv.update(3.0);
    try std.testing.expectApproxEqAbs(2.0, mv.ma.curr(), 1e-9);
    try std.testing.expectApproxEqAbs(2.0 / 3.0, mv.curr(), 1e-9);
    mv.update(4.0);
    try std.testing.expectApproxEqAbs(3.0, mv.ma.curr(), 1e-9);
    try std.testing.expectApproxEqAbs(2.0 / 3.0, mv.curr(), 1e-9);
    mv.update(5.0);
    try std.testing.expectApproxEqAbs(4.0, mv.ma.curr(), 1e-9);
    try std.testing.expectApproxEqAbs(2.0 / 3.0, mv.curr(), 1e-9);
    mv.update(6.0);
    try std.testing.expectApproxEqAbs(5.0, mv.ma.curr(), 1e-9);
    try std.testing.expectApproxEqAbs(2.0 / 3.0, mv.curr(), 1e-9);
}

test "Moving Standard Deviation" {
    var mv = SMStdDev(3, 0, 5){};
    mv.update(1.0);
    mv.update(2.0);
    mv.update(3.0);
    try std.testing.expectApproxEqAbs(sqrt(2.0 / 3.0), mv.curr(), 1e-9);
    mv.update(4.0);
    try std.testing.expectApproxEqAbs(sqrt(2.0 / 3.0), mv.curr(), 1e-9);
    mv.update(5.0);
    try std.testing.expectApproxEqAbs(sqrt(2.0 / 3.0), mv.curr(), 1e-9);
    mv.update(6.0);
    try std.testing.expectApproxEqAbs(sqrt(2.0 / 3.0), mv.curr(), 1e-9);
}

test "Average True Range" {
    var atr = ATR(3, 1){};
    atr.update(10.0, 5.0, 7.0);
    atr.update(12.0, 6.0, 8.0);
    atr.update(14.0, 7.0, 9.0);
    try std.testing.expectApproxEqAbs(6.0, atr.curr(), 1e-9);
    atr.update(16.0, 8.0, 10.0);
    try std.testing.expectApproxEqAbs(7.0, atr.curr(), 1e-9);
}

