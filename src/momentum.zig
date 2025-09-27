const std = @import("std");
const nan = std.math.nan(f64);
const Indicator = @import("base.zig").Indicator;
const SMA = @import("trend.zig").SMA;

/// Relative Strength Index measures the speed and magnitude of price
/// changes. It is used to detect overbought or oversold conditions. It
/// is an oscillator on a scale of 0 to 100. Usually, values above 70
/// indicates an overbought conditions, while values under 30 do for
/// oversold conditions.
pub fn RSI(periods: usize, mem_size: usize) type {
    return struct {
        // Keep the record of gains.
        gains: SMA(periods, 1) = SMA(periods, 1){},
        // Keep the record of losses.
        losses: SMA(periods, 1) = SMA(periods, 1){},
        // Results for RSI are stored here.
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

/// The Stochastic Oscilator helps to identify potential market
/// reversals by comparing the closing price to its price range over a
/// given period.
pub fn StochasticOscilator(period: usize, mem_size: usize) type {
    return struct {
        data: Indicator(f64, nan, mem_size) = Indicator(f64, nan, mem_size){},
        low: Indicator(f64, nan, period) = Indicator(f64, nan, period){},
        high: Indicator(f64, nan, period) = Indicator(f64, nan, period){},

        pub fn update(self: *@This(), value: f64) void {
            const lowest = std.mem.min(f64, &self.low.data);
            const highest = std.mem.max(f64, &self.high.data);
            const osc = (value - lowest) / (highest - lowest);
            self.data.push(osc * 100.0);
            self.low.push(value);
            self.high.push(value);
        }

        pub inline fn curr(self: @This()) f64 {
            return self.data.curr();
        }

        pub inline fn get(self: @This(), offset: usize) f64 {
            return self.data.get(offset);
        }
    };
}

test "Relative Strength Index" {
    var rsi = RSI(3, 1){};
    rsi.update(1.0, 2.0);
    rsi.update(2.0, 4.0);
    rsi.update(4.0, 3.0);
    try std.testing.expectApproxEqAbs(75.0, rsi.curr(), 1e-9);
}

test "Stochastic Oscilator" {
    var oscilator = StochasticOscilator(3, 1){};
    oscilator.update(150.0);
    oscilator.update(125.0);
    oscilator.update(145.0);
    try std.testing.expectApproxEqAbs(80.0, oscilator.curr(), 1e-9);
    oscilator.update(120.0);
    oscilator.update(160.0);
    oscilator.update(140.0);
    try std.testing.expectApproxEqAbs(50.0, oscilator.curr(), 1e-9);
}
