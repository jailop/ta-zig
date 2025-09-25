const std = @import("std");

const Side = enum {
    NoSide,
    Buy,
    Sell,
    Both,
};

const OrderType = enum {
    NoOrder,
    Market,
    Limit,
    Stop,
    StopLimit,
    TakeProfit,
    TakeProfitLimit,
    TrailingStop,
    FillOrKill,
    ImmediateOrCancel,
    PostOnly,
};

const OrderStatus = enum {
    Draft,
    New,
    Filled,
    Partial,
    Cancelled,
    Rejected,
};

const Order = struct {
    creationTime: i64,
    updateTime: i64,
    order_id: usize = 0,
    symbol: []const u8 = "",
    exchange: []const u8 = "",
    side: Side = Side.NoSide,
    orderType: OrderType = OrderType.NoOrder,
    status: OrderStatus = OrderStatus.Draft,
    quantity: f64 = 0.0,
    price: f64 = 0.0,

    pub fn default() Order {
        const currentTime = std.time.microTimestamp();
        return Order{
            .creationTime = currentTime,
            .updateTime = currentTime,
        };
    }
};

test "Order" {
    const order = Order.default();
    try std.testing.expect(order.side == Side.NoSide);
    try std.testing.expect(order.orderType == OrderType.NoOrder);
    try std.testing.expect(order.price == 0.0);
    try std.testing.expect(order.quantity == 0.0);
}
