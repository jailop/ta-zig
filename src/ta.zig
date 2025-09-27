//! ta-zig is a module with indicators for trading technical analysis.
//! It is designed to handle streaming data.  This implementation avoids
//! recomputing the indicator over all the input data every time it's
//! updated. All parameters are defined at compile time. Finally, memory
//! is only statically allocated. All these features make this module
//! highly CPU and memory efficient.
//!
//! To use this module you have to:
//!
//! * Build a concrete type, given the parameters for the indicator. 
//! * Feed the indicator with values calling the function `update`.
//!
//! One
//! required parameter for all the available indicators is `mem_size`. It
//! indicates how many back values should be remembered by the
//! indicator.
//! 
//! You can retrieve values for the respective indicator, using any of
//! these functions:
//!
//! * curr(): Current value of the indicator
//! * get(offset): Past value of the indicator.
//!
//! If offset is 0, then it is the current value. If offset is 1, it is
//! the inmediate previous value, and so on. Maximum value of offset
//! should match the mem_size parameter.


const trend = @import("trend.zig");
pub const SMA = trend.SMA;
pub const EMA = trend.EMA;
pub const MACD = @import("macd.zig").MACD;
pub const BollingerBands = @import("bollingerbands.zig").BollingerBands;
pub const OBV = @import("trend.zig").OBV;

const volatility = @import("volatility.zig");
pub const SMVar = volatility.SMVar;
pub const SMStd = volatility.SMStd;
pub const ATR = volatility.ATR;

const momentum = @import("momentum.zig");
pub const RSI = momentum.RSI;
pub const StochasticOscilator = momentum.StochasticOscilator;
