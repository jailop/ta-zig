const std = @import("std");
const nan = std.math.nan(f64);
const Indicator = @import("base.zig").Indicator;

/// Simple Moving Average.
/// To compute the simple moving average for the time points contained
/// in the indicated period. It is used to determine the average price
/// of an asset. It is typically calculated using closing prices.
/// Because it smooths price fluctuations, it is useful to identify
/// potential trends.
pub fn SMA(period: usize, mem_size: usize) type {
    return struct {
        /// Results for the moving average are stored here.
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},
        /// Contains the previous data values. It is a circular list.
        /// When a new data value arrives, the older one is removed and
        /// the new one is added to the list.
        prev_values: [period]f64 = [_]f64{nan} ** period,
        /// Position pointer to access items in `prev_values`.
        pos: usize = 0,
        /// A sentinel value when values start to be computed
        length: usize = 0,
        /// The sum of values. When a new value arrives, the older
        /// values is discounted from this field and the new one is
        /// added to.
        sum: f64 = 0.0,

        const Self = @This();

        /// Add a new value to the time series. This values is used to
        /// update the moving average.
        pub fn update(self: *Self, value: f64) void {
            if (self.length < period) {
                self.length += 1;
            } else {
                self.sum -= self.prev_values[self.pos];
            }
            self.prev_values[self.pos] = value;
            self.sum += value;
            self.pos = (self.pos + 1) % period;
            if (self.length < period) {
                self.data.push(std.math.nan(f64));
            } else {
                self.data.push(self.sum / period);
            }
        }

        /// Returns the current moving average. This function is the
        /// same as calling get(0).
        pub inline fn curr(self: Self) f64 {
            return self.data.curr();
        }

        /// Returns the moving average back by offset positions.
        /// If offset is greater than mem_size, a nan value is returned.
        pub inline fn get(self: Self, offset: usize) f64 {
            return self.data.get(offset);
        }
    };
}


/// The Exponential Moving Average emphasizes recent data points more
/// heavily. When the smoothing factor is increased, more recent
/// observations have more influence.
pub fn EMA(period: usize, smoothing: f64, mem_size: usize) type {
    return struct {
        /// Results for the exponential moving average are store here.
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},
        /// An auxiliary variable to keep temporally the previous updated value.
        prev_value: f64 = 0.0,
        /// To check when valid values are available, otherwise nan is
        /// returned.
        length: usize = 0,

        const Self = EMA(period, smoothing, mem_size);

        pub fn update(self: *Self, value: f64) void {
            self.length += 1;
            if (self.length < period) {
                self.prev_value += value;
                self.data.push(std.math.nan(f64));
            } else if (self.length == period) {
                self.prev_value = (self.prev_value + value) / period;
                self.data.push(self.prev_value);
            } else {
                const alpha = smoothing / (1 + period);
                self.prev_value = (value * alpha) +
                    self.prev_value * (1.0 - alpha);
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

/// On-Balance Volume leverages volume flow to anticipate asset price
/// movements. It aims to forecast when major market moves will occur
/// based on changes in volume. It is assumed that when volume rises
/// sharply without a corresponding price change, an eventual
/// significant price movement is likely.
///
/// To compute OBV, the current close prices is compared with the
/// previous one. If it is greater than, the current volume is added to the
/// indicador. If it is less than, the current volume is substracted
/// from the indicador.
pub fn OBV(mem_size: usize) type {
    return struct {
        /// OBV results are stored here.
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},
        /// To remember the previous closing price.
        prev_close: f64 = nan,
        pub fn update(self: *@This(), close: f64, volume: f64) void {
            if (std.math.isNan(self.prev_close)) {
                self.prev_close = close;
                self.data.push(0.0);
                return;
            }
            const accum =
                if (close > self.prev_close)
                    volume
                else if (close < self.prev_close)
                    -volume
                else
                    0.0;
            self.data.push(self.data.curr() + accum);
            self.prev_close = close;
        }

        pub inline fn curr(self: @This()) f64 {
            return self.data.curr();
        }

        pub inline fn get(self: @This(), offset: usize) f64 {
            return self.data.get(offset);
        }
    };
}

test "Moving Average" {
    var ma = SMA(3, 5){};
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
    var ema = EMA(3, 2.0, 5){};
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

test "On-Balance Volume" {
    var obv = OBV(1){};
    obv.update(10.0, 25200.0);
    try std.testing.expectApproxEqAbs(0.0, obv.curr(), 1e-9);
    obv.update(10.15, 30000.0);
    try std.testing.expectApproxEqAbs(30000.0, obv.curr(), 1e-9);
    obv.update(10.17, 25600.0);
    try std.testing.expectApproxEqAbs(55600.0, obv.curr(), 1e-9);
    obv.update(10.13, 32000.0);
    try std.testing.expectApproxEqAbs(23600.0, obv.curr(), 1e-9);
    obv.update(10.11, 23000.0);
    try std.testing.expectApproxEqAbs(600.0, obv.curr(), 1e-9);
}
