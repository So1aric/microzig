const std = @import("std");
const microzig = @import("microzig");

pub const panic = microzig.panic;

pub const std_options = microzig.std_options(.{ .logFn = usart.log });

comptime {
    _ = microzig.export_startup();
}

const clocks = microzig.hal.clocks;
const usart = microzig.hal.usart;
const usart1 = usart.usart1;

pub fn main() !void {
    clocks.init();
    usart1.apply(.{
        .baud_rate = 115200,
        .tx_pin = .{ .gpio = .GPIOA, .number = 9 },
        .rx_pin = .{ .gpio = .GPIOA, .number = 10 },
    });
    usart1.init_logger();

    std.log.info("usart echo ready", .{});

    var tx_buffer: [64]u8 = undefined;
    var tx = usart1.writer(&tx_buffer);
    tx.interface.writeAll("usart echo\r\n") catch {};
    tx.interface.flush() catch {};

    var rx_buffer: [1]u8 = undefined;
    var rx = usart1.reader(&rx_buffer);

    while (true) {
        const byte = try rx.interface.takeByte();
        try tx.interface.print("{c}", .{byte});
        try tx.interface.flush();
    }
}
