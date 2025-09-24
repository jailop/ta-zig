const trend = @import("trend.zig");
pub const SMAvg = trend.SMAvg;
pub const EMAvg = trend.EMAvg;
pub const MACD = @import("macd.zig").MACD;

const volatility = @import("volatility.zig");
pub const SMVar = volatility.SMVar;
pub const SMStdDev = volatility.SMStdDev;
pub const ATR = volatility.ATR;

const momentum = @import("momentum.zig");
pub const RSI = momentum.RSI;
