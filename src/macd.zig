const std = @import("std");                                                      
const nan = std.math.nan(f64);
const EMAvg = @import("trend.zig").EMAvg;
const Indicator = @import("base.zig").Indicator;

pub fn MACD(short_period: usize, long_period: usize, diff_period: usize,
        smoothing: f64, mem_size: usize) type
{
    const Result = struct {
        macd: f64 = nan,
        signal: f64 = nan,
        hist: f64 = nan,
    };
    return struct {
        data: Indicator(Result, Result{}, mem_size) =
            Indicator(Result, Result{}, mem_size){},
        short_ema: EMAvg(short_period, smoothing, 1) = 
            EMAvg(short_period, smoothing, 1){},
        long_ema: EMAvg(long_period, smoothing, 1) =
            EMAvg(long_period, smoothing, 1){},
        diff_ema: EMAvg(diff_period, smoothing, 1) = 
            EMAvg(diff_period, smoothing, 1){},

        start: usize = @max(short_period, long_period),
        counter: usize = 0,

        pub fn update(self: *@This(), value: f64) void {
            self.counter += 1;
            self.short_ema.update(value);
            self.long_ema.update(value);
            if (self.counter >= self.start) {
                const diff = self.short_ema.curr() - self.long_ema.curr();
                self.diff_ema.update(diff);
                self.data.push(Result{
                    .macd = diff,
                    .signal = self.diff_ema.curr(),
                    .hist = diff - self.diff_ema.curr()
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

// Data for this test was taken from:
// <https://investexcel.net/how-to-calculate-macd-in-excel/>
test "MACD" {
    var macd = MACD(12, 26, 9, 2.0, 2){};
    const ts = [_]f64{
        459.99, 448.85, 446.06, 450.81, 442.8,
        448.97, 444.57, 441.4, 430.47, 420.05,
        431.14, 425.66, 430.58, 431.72, 437.87,
        428.43, 428.35, 432.5, 443.66, 455.72,
        454.49, 452.08, 452.73, 461.91, 463.58,
        461.14, 452.08, 442.66, 428.91, 429.79,
        431.99, 427.72, 423.2, 426.21, 426.98,
        435.69, 434.33, 429.8, 419.85, 426.24,
        402.8, 392.05, 390.53, 398.67, 406.13,
        405.46, 408.38, 417.2, 430.12, 442.78,
        439.29, 445.52, 449.98, 460.71, 458.66,
        463.84, 456.77, 452.97, 454.74, 443.86,
        428.85, 434.58, 433.26, 442.93, 439.66,
        441.3,
    };
    const res = [_]f64{
        3.03752586873395, 1.90565222933578, 1.05870843537763, 0.410640325343509,
        -0.152012994298479, -0.790034731709356, -1.33810041258299,
        -2.17197457979186, -3.30783450954566, -4.59014109868629,
        -5.75668618055047, -6.65738137622787, -7.33974702300915,
        -7.78618154079804, -7.90287193112745, -7.58262468963905,
        -6.78603605354027, -5.77285851501159, -4.5644861655494,
        -3.21555428301682, -1.67071586469137, -0.112968660984149,
        1.45411118991556, 2.82877971367526, 3.94371200786538, 4.85665087093101,
        5.41047306555065, 5.45836826902626, 5.26562556819742, 4.89909832689482,
        4.58597343224244, 4.26011131701701, 3.96060129677866,
    };
    const test_pos = 33;
    for (0..ts.len, ts) |i, value| {
        macd.update(value);
        std.debug.print("{}", .{macd.curr()});
        if (i < test_pos) {
            try std.testing.expect(std.math.isNan(macd.curr().signal));
        } else if (i == test_pos) {
            try std.testing.expectApproxEqAbs(macd.curr().signal,
                res[i - test_pos], 1e-3);
        } else {
            try std.testing.expectApproxEqAbs(macd.curr().signal,
                res[i - test_pos], 1e-3);
            try std.testing.expectApproxEqAbs(macd.get(1).signal,
                res[i - test_pos - 1], 1e-3);
        }
    }
}
