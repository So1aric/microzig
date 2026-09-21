const microzig = @import("microzig");

const std = @import("std");

const Io = std.Io;

const cpu = microzig.cpu;
const interrupt = cpu.interrupt;

const clocks = microzig.hal.clocks;

const peripherals = microzig.chip.peripherals;

const Peripherals = microzig.hal.Peripherals;

pub const USART = Peripherals.USART;

const Reader = struct {
    interface: Io.Reader,
    usart: USART,
};

const Writer = struct {
    interface: Io.Writer,
    usart: USART,
};

// pub fn writer(usart: USART, buffer: []u8) Writer {
//     return .{
//         .interface = .{
//             .buffer = buffer,
//             .vtable = &.{
//                 .drain = drain,
//             },
//         },
//         .usart = usart,
//     };
// }

fn drain(io_writer: *Io.Writer, data: []const []const u8, splat: usize) Io.Writer.Error!usize {
    _ = io_writer;
    _ = data;
    _ = splat;
    return 0;
}

pub fn foo() type {
    return Peripherals.USART;
}

pub fn bar() type {
    return Peripherals.All;
}

pub const Config = struct {};

// pub fn apply(usart: USART, comptime cfg: Config) void {
//     const reg = Peripherals.to_reg(usart);
//
//     clocks.enable(Peripherals.to_peripheral(usart));
//     clocks.enable(.AFIO);
// }
