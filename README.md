# Zig Library for Technical Analysis

I'm just starting. At this moment I have implemented a few technical
analysis indicators for streaming data:

Trend:

* Simple Moving Average (SMAvg)
* Exponential Moving Average (EMAvg)
* Moving Average Convergence Divergence (MACD) (new)

Volatility:

* Simple Moving Variance (SMVar)
* Simple Moving Standard Deviation (SMStdDev)
* Average True Range (ATR)

Momentum:

* Relative Strength Index (RSI) 

This implementation, based on circular lists, keeps just a window of
values for an indicator, including the current one and a few past ones.

Input data is not stored.
When new data is pushed, the indicator is updated and older values
exceeding the memory size are forgotten.

For example, computing a moving average at each update, doesn't sum all values involved to divide them over the number of items. Instead, it is just the previous average that is updated with the new value, performing a minimal number of operations. 

$$\bar{MA}_{t,p} = \bar{MA}_{t-1,p} + \frac{x_t - x_{t-p}}{p}$$

Where:

* $\bar{MA}_{t,p}$: Current moving average


This
implementation avoids recomputing the indicator over all the input data
every time it's updated. All parameters are defined at compile time. Memory is statically allocated. All these features make indicators highly CPU and memory efficient.


Example:

```zig
const period = 3;
const memory_size = 5;
var ma = SMAvg(period, memory_size){};
// Pushing a few values
ma.update(1.0);
ma.update(2.0);
ma.update(3.0);
// At this point the moving average is 2.0
try std.testing.expectApproxEqAbs(2.0, ma.curr(), 1e-9);
// Updating the moving average with a new value
ma.update(4.0);
// Now the moving average is 3.0
try std.testing.expectApproxEqAbs(3.0, ma.curr(), 1e-9);
// Retrieving the moving average for t-1 (previous value)
// Past values are indexed by backward positive integers
try std.testing.expectApproxEqAbs(2.0, ma.get(1), 1e-9);
```
