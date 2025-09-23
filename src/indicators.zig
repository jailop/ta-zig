const std = @import("std");
const nan = std.math.nan(f64);

pub fn Indicator(T: type, nan_value: T, size: usize) type {
    return struct {

        data: [size]T = [_]T{nan_value} ** size,
        pos: usize = 0,

        const Self = @This();

        pub fn push(self: *Self, value: T) void {
            if (self.pos == 0) {
                self.pos = size;
            }
            self.pos -= 1;
            self.data[self.pos] = value;
        }
        
        pub fn get(self: Self, offset: usize) T {
            if (offset >= size) {
                return nan_value;
            }
            return self.data[(self.pos + offset) % size];
        }

        pub fn curr(self: Self) T {
            return self.data[self.pos];
        }
    };
}

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
        variance: SMVar(periods, dof, mem_size) =
            SMVar(periods, dof, mem_size){},

        const Self = SMStdDev(periods, dof, mem_size);
                  
        pub inline fn update(self: *Self, value: f64) void {
            self.variance.update(value);
        }

        pub inline fn curr(self: Self) f64 {
            return std.math.sqrt(self.variance.curr());
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

pub fn RSI(periods: usize, mem_size: usize) type {
    return struct {

        gains: SMAvg(periods, 1) = SMAvg(periods, 1){},
        losses: SMAvg(periods, 1) = SMAvg(periods, 1){},
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},

        const Self = RSI(periods, mem_size);

        pub fn update(self: *Self, open_price: f64, close_price: f64) void {
            const diff = close_price - open_price;
            if (diff > 0) {
                self.gains.update(diff);
                self.losses.update(0.0);
            } else {
                self.gains.update(0.0);
                self.losses.update(-diff);
            }
            if (std.math.isNan(self.losses.curr())) {
                self.data.push(std.math.nan(f64));
            } else {
                const rsi = 100.0 -
                    (100.0 / (1.0 + (self.gains.curr() / self.losses.curr())));
                self.data.push(rsi);
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

test "Indicator" {
    var ind = Indicator(f64, std.math.nan(f64), 3){};
    ind.push(1.0);
    ind.push(2.0);
    ind.push(3.0);
    try std.testing.expectApproxEqAbs(3.0, ind.curr(), 1e-9);
    try std.testing.expectEqual(3.0, ind.get(0));
    try std.testing.expectEqual(2.0, ind.get(1));
    try std.testing.expectEqual(1.0, ind.get(2));
    try std.testing.expect(std.math.isNan(ind.get(3)));
    ind.push(4.0);
    try std.testing.expectApproxEqAbs(4.0, ind.curr(), 1e-9);
    try std.testing.expectEqual(4.0, ind.get(0));
    try std.testing.expectEqual(3.0, ind.get(1));
    try std.testing.expectEqual(2.0, ind.get(2));
    try std.testing.expect(std.math.isNan(ind.get(3)));
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

test "Average True Range" {
    var atr = ATR(3, 1){};
    atr.update(10.0, 5.0, 7.0);
    atr.update(12.0, 6.0, 8.0);
    atr.update(14.0, 7.0, 9.0);
    try std.testing.expectApproxEqAbs(6.0, atr.curr(), 1e-9);
    atr.update(16.0, 8.0, 10.0);
    try std.testing.expectApproxEqAbs(7.0, atr.curr(), 1e-9);
}

test "Relative Strength Index" {
    var rsi = RSI(3, 1){};
    rsi.update(1.0, 2.0);
    rsi.update(2.0, 4.0);
    rsi.update(4.0, 3.0);
    try std.testing.expectApproxEqAbs(75.0, rsi.curr(), 1e-9);
}
