const std = @import("std");
const microzig = @import("microzig");

pub const panic = microzig.panic;

const usart = microzig.hal.usart;
const usart1 = usart.usart1;

pub const std_options = microzig.std_options(.{ .logFn = usart.log });

pub const microzig_options: microzig.Options = .{
    .interrupts = .{ .USART1 = on_usart1 },
};

comptime {
    _ = microzig.export_startup();
}

const cpu = microzig.cpu;
const clocks = microzig.hal.clocks;

// Shared between the ISR and main.
var rx_byte: u8 = 0;
var rx_pending: bool = false;

fn on_usart1() callconv(cpu.riscv_calling_convention) void {
    // Handle (and clear) ORE/FE/NE/PE first; the STATR->DATAR sequence would
    // otherwise swallow the byte below.
    usart1.check_errors() catch return;

    if (usart1.is_readable()) {
        @atomicStore(u8, &rx_byte, usart1.read_byte(), .release);
        @atomicStore(bool, &rx_pending, true, .release);
    }
    if (usart1.is_idle()) usart1.clear_idle();
}

pub fn main() !void {
    clocks.init();
    usart1.apply(.{
        .baud_rate = 115200,
        .tx_pin = .{ .gpio = .GPIOA, .number = 9 },
        .rx_pin = .{ .gpio = .GPIOA, .number = 10 },
    });
    usart1.init_logger();

    usart1.set_interrupts(.{ .rx = true, .errors = true, .idle = true });
    usart1.enable_interrupt();

    std.log.info("usart interrupt echo ready", .{});

    var tx_buffer: [64]u8 = undefined;
    var tx = usart1.writer(&tx_buffer);
    tx.interface.writeAll("usart echo\r\n") catch {};
    tx.interface.flush() catch {};

    while (true) {
        while (!@atomicLoad(bool, &rx_pending, .acquire)) cpu.wfi();
        @atomicStore(bool, &rx_pending, false, .release);
        const byte = @atomicLoad(u8, &rx_byte, .acquire);
        tx.interface.print("{c}", .{byte}) catch {};
        tx.interface.flush() catch {};
    }
}
