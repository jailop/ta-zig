# Zig Library for Technical Analysis

I'm just starting. At this moment I have implemented a few technical
analysis indicators for streaming data:

* Simple Moving Average (SMAvg)
* Simple Moving Variance (SMVar)
* Simple Moving Standard Deviation (SMStdDev)
* Exponential Moving Average (EMAvg)
* Average True Range (ATR)
* Relative Strength Index (RSI) 

This implementation, based on circular lists, keeps just a window of
values for an indicator, including the current one and a few past ones.
When new data is pushed, the indicator is updated and older values
exceeding the memory size are forgotten. Input data is not stored. This
implementation avoids recomputing the indicator over all the data inputs
every time it's updated, making it highly CPU and memory efficient.


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
// Now the moving average is [4.0](4.0)
try std.testing.expectApproxEqAbs(3.0, ma.curr(), 1e-9);
// Retrieving the moving average for t-1 (previous value)
try std.testing.expectApproxEqAbs(2.0, ma.get(1), 1e-9);
```
