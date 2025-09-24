const std = @import("std");
const nan = std.math.nan(f64);
const Indicator = @import("base.zig").Indicator;

pub fn SMAvg(periods: usize, mem_size: usize) type {
    return struct {
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},
        prev_values: [periods]f64 = [_]f64{nan} ** periods,
        pos: usize = 0,
        length: usize = 0,
        sum: f64 = 0.0,

        const Self = @This();
        
        pub fn update(self: *Self, value: f64) void {
            if (self.length < periods) {
                self.length += 1;
            } else {
                self.sum -= self.prev_values[self.pos];
            }
            self.prev_values[self.pos] = value;
            self.sum += value;
            self.pos = (self.pos + 1) % periods;
            if (self.length < periods) {
                self.data.push(std.math.nan(f64));
            } else {
                self.data.push(self.sum / periods);
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

pub fn EMAvg(periods: usize, smoothing: f64, mem_size: usize) type {
    return struct {
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},
        prev_value: f64 = 0.0,
        length: usize = 0,

        const Self = EMAvg(periods, smoothing, mem_size);

        pub fn update(self: *Self, value: f64) void {
            self.length += 1;
            if (self.length < periods) {
                self.prev_value += value;
                self.data.push(std.math.nan(f64));
            } else if (self.length == periods) {
                self.prev_value = (self.prev_value + value) / periods;
                self.data.push(self.prev_value);
            } else {
                const alpha = smoothing / (1 + periods);
                self.prev_value = (value * alpha) + self.prev_value * (1.0 - alpha);
                self.data.push(self.prev_value);
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

test "Moving Average" {
    var ma = SMAvg(3, 5){};
    ma.update(1.0);
    ma.update(2.0);
    ma.update(3.0);
    try std.testing.expectApproxEqAbs(2.0, ma.curr(), 1e-9);
    ma.update(4.0);
    try std.testing.expectApproxEqAbs(3.0, ma.curr(), 1e-9);
    ma.update(5.0);
    try std.testing.expectApproxEqAbs(4.0, ma.curr(), 1e-9);
    ma.update(6.0);
    try std.testing.expectApproxEqAbs(5.0, ma.curr(), 1e-9);
}

test "Exponential Moving Average" {
    var ema = EMAvg(3, 2.0, 5){};
    ema.update(1.0);
    ema.update(2.0);
    ema.update(3.0);
    try std.testing.expectApproxEqAbs(2.0, ema.curr(), 1e-9);
    ema.update(4.0);
    try std.testing.expectApproxEqAbs(3.0, ema.curr(), 1e-9);
    ema.update(5.0);
    try std.testing.expectApproxEqAbs(4.0, ema.curr(), 1e-9);
    ema.update(6.0);
    try std.testing.expectApproxEqAbs(5.0, ema.curr(), 1e-9);
}



