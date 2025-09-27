const std = @import("std");

/// Base Indicador
///     T: type
///     nan_value: A generic NaN value
///     size: Size of the buffer
/// It is expected that other indicators use this same API
pub fn Indicator(T: type, nan_value: T, size: usize) type {
    return struct {
        data: [size]T = [_]T{nan_value} ** size, // A circular list
        pos: usize = 0, // Current position

        const Self = @This();

        /// A new value is inserted into the list
        /// Old values are overwritten
        pub fn push(self: *Self, value: T) void {
            if (self.pos == 0) {
                self.pos = size;
            }
            self.pos -= 1;
            self.data[self.pos] = value;
        }

        // Back values are indicated by a positive integer
        pub fn get(self: Self, offset: usize) T {
            if (offset >= size) {
                return nan_value;
            }
            return self.data[(self.pos + offset) % size];
        }

        // Get the current value
        pub fn curr(self: Self) T {
            return self.data[self.pos];
        }
    };
}

test "Indicator" {
    var ind = Indicator(f64, std.math.nan(f64), 3){};
    ind.push(1.0);
    ind.push(2.0);
    ind.push(3.0);
    try std.testing.expectApproxEqAbs(3.0, ind.curr(), 1e-9);
    try std.testing.expectEqual(3.0, ind.get(0));
    try std.testing.expectEqual(2.0, ind.get(1));
    try std.testing.expectEqual(1.0, ind.get(2));
    try std.testing.expect(std.math.isNan(ind.get(3)));
    ind.push(4.0);
    try std.testing.expectApproxEqAbs(4.0, ind.curr(), 1e-9);
    try std.testing.expectEqual(4.0, ind.get(0));
    try std.testing.expectEqual(3.0, ind.get(1));
    try std.testing.expectEqual(2.0, ind.get(2));
    try std.testing.expect(std.math.isNan(ind.get(3)));
}
