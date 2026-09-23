const helper = @import("utils/peripherals_helper.zig");

pub const All = helper.create_peripheral_enum(&.{
    "AFIO", // should this stay here?
    "GPIO",
    "USART",
    "DMA1",
    "DMA2",
});

pub const GPIO = helper.sub_peripheral_enum(All, &.{"GPIO"}, null);
pub const USART = helper.sub_peripheral_enum(All, &.{"USART"}, null);

pub const to_reg = helper.to_reg;

/// Converts a sub-peripheral enum value back to the total `All` enum,
/// e.g. for passing to clock enable functions.
pub inline fn to_peripheral(id: anytype) All {
    return switch (@TypeOf(id)) {
        All => id,
        else => @fromBackingInt(@backingInt(id)),
    };
}
