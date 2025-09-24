const std = @import("std");
const nan = std.math.nan(f64);
const Indicator = @import("base.zig").Indicator;
const SMAvg = @import("trend.zig").SMAvg;

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

test "Relative Strength Index" {
    var rsi = RSI(3, 1){};
    rsi.update(1.0, 2.0);
    rsi.update(2.0, 4.0);
    rsi.update(4.0, 3.0);
    try std.testing.expectApproxEqAbs(75.0, rsi.curr(), 1e-9);
}
