const std = @import("std");
const nan = std.math.nan(f64);
const sqrt = std.math.sqrt;
const Indicator = @import("base.zig").Indicator;
const SMA = @import("trend.zig").SMA;


/// Simple Moving Variance measures volatility. You can indicate the
/// degree of freedom. Usually, for population dof=0, and for a simple
/// sample dof=1.
pub fn SMVar(period: usize, dof: u8, mem_size: usize) type {
    return struct {
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},
        ma: SMA(period, 1) = SMA(period, 1){},
        prev_values: [period]f64 = [_]f64{nan} ** period,
        pos: usize = 0,
        length: usize = 0,
        sum: f64 = 0.0,

        const Self = @This();

        pub fn update(self: *Self, value: f64) void {
            if (self.length < period) {
                self.length += 1;
            }
            self.prev_values[self.pos] = value;
            self.ma.update(value);
            self.pos = (self.pos + 1) % period;
            if (self.length < period) {
                self.data.push(std.math.nan(f64));
            } else {
                self.sum = 0.0;
                for (self.prev_values) |v| {
                    const diff = v - self.ma.curr();
                    self.sum += diff * diff;
                }
                self.data.push(self.sum / (period - dof));
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

/// Simple Moving Standard Deviation measures volatility. The scale is
/// the same as the input value. You can indicate the degree of freedom.
/// Usually, for population dof=0, and for a simple sample dof=1.
pub fn SMStd(period: usize, dof: u8, mem_size: usize) type {
    return struct {
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},
        variance: SMVar(period, dof, mem_size) =
            SMVar(period, dof, mem_size){},

        const Self =  @This();

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

/// Average True Range measures the market volatility by descomposing
/// the entire range of an asset price for a given period. It is taken
/// as the greater ot the following:
///
/// * The current high less the current low
/// * The absolute value of the current high less the previous close
/// * The absolute value of the current low less the previous close
///
/// The ATR is a moving average of the true ranges, usually for a period
/// of 14 days for daily trading. A shorter period can be useful the
/// generate more signals.
pub fn ATR(period: usize, mem_size: usize) type {
    return struct {
        /// Results for ATR are stored here.
        data: SMA(period, mem_size) = SMA(period, mem_size){},

        const Self = ATR(period, mem_size);

        pub fn update(self: *Self, high: f64, low: f64, close: f64) void {
            const high_low = high - low;
            const high_close = if (high > close) high - close else close - high;
            const low_close = if (low > close) low - close else close - low;
            const tr =
                if (high_low > high_close and high_low > low_close) high_low else if (high_close > low_close) high_close else low_close;
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
    var mv = SMStd(3, 0, 5){};
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
