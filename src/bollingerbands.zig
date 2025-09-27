const std = @import("std");
const nan = std.math.nan(f64);
const sqrt = std.math.sqrt;
const Indicator = @import("base.zig").Indicator;
const SMA = @import("trend.zig").SMA;
const SMStd = @import("volatility.zig").SMStd;


/// Bollinger Bands help to gauge the volitily of an asset. It is
/// represent by three values:
///
/// * sma: The simple moving average for the given period.
/// * upper: Upper band indicator representing z-times up the moving standard
/// deviation from sma.
/// * lower: Lower band indicator representing z-times down the moving
/// standard deviation from sma.
///
/// This fields can be accessed from the result obtained from curr() or
/// get(), like curr().sma for example. It is common that z is set to
/// 2.0.
///
/// The bands widen when asset's price becomes more volatile and
/// contract when it is more stable. Usually, if price is near to the
/// upper band it can be an indicator of overbought, while it can
/// oversold if the price is near to the lower band. 
pub fn BollingerBands(period: usize, z: f64, mem_size: usize) type {
    return struct {
        const Result = struct {
            sma: f64 = nan,
            upper: f64 = nan,
            lower: f64 = nan,
        };
        /// Bands are stored here.
        data: Indicator(Result, Result{}, mem_size) =
            Indicator(Result, Result{}, mem_size){},
        /// Used to compute the value of the middle band.
        sma: SMA(period, 1) = SMA(period, 1){},
        /// Used to compute the value of the lower and upper bands.
        std: SMStd(period, 1, 1) = SMStd(period, 1, 1){},
        /// Used to check when valid values are already available.
        counter: usize = 0,

        pub fn update(self: *@This(), value: f64) void {
            self.counter += 1;
            self.sma.update(value);
            self.std.update(value);
            const range = self.std.curr() * z;
            if (self.counter >= period) {
                self.data.push(Result{
                    .sma = self.sma.curr(),
                    .upper = self.sma.curr() + range,
                    .lower = self.sma.curr() - range,
                });
            } else {
                self.data.push(Result{});
            }
        }

        pub inline fn curr(self: @This()) Result {
            return self.data.curr();
        }

        pub inline fn get(self: @This(), offset: usize) Result {
            return self.data.get(offset);
        }
    };
}

test "Bollinger Bands" {
    const period = 3;
    const z = 2.0;
    const mem_size = 3;
    var bands = BollingerBands(period, z, mem_size){};
    bands.update(1.0);
    bands.update(2.0);
    bands.update(3.0);
    try std.testing.expectApproxEqAbs(2.0, bands.curr().sma, 1e-9);
    try std.testing.expectApproxEqAbs(4.0, bands.curr().upper, 1e-9);
    try std.testing.expectApproxEqAbs(0.0, bands.curr().lower, 1e-9);
    bands.update(7.0);
    const sd = 2 * sqrt(7.0);
    try std.testing.expectApproxEqAbs(4.0, bands.curr().sma, 1e-9);
    try std.testing.expectApproxEqAbs(4.0 + sd, bands.curr().upper, 1e-9);
    try std.testing.expectApproxEqAbs(4.0 - sd, bands.curr().lower, 1e-9);
}
