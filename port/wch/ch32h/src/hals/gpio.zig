const microzig = @import("microzig");
const clocks = microzig.hal.clocks;
const Peripherals = microzig.hal.Peripherals;

pub const Pin = struct {
    gpio: Peripherals.GPIO,
    number: u4,

    pub const Config = struct {
        mode: Mode,
        speed: Speed,
        pull: Pull,
    };

    pub const Mode = union(enum) {
        input: Input,
        output: Output,

        pub const Input = enum(u2) {
            analog,
            floating,
            pull,
            reserved,
        };

        pub const Output = enum(u2) {
            general_purpose_push_pull,
            general_purpose_open_drain,
            alternate_function_push_pull,
            alternate_function_open_drain,
        };
    };

    pub const Speed = enum(u2) {
        max_10MHz,
        max_50MHz,
        max_100MHz,
        max_180MHz,
    };

    pub const Pull = enum {
        up,
        down,
        disabled,
    };

    pub fn enable(pin: Pin) void {
        clocks.enable(Peripherals.to_peripheral(pin.gpio));
    }

    /// Enables this pin's port clock, then applies the given configuration.
    pub fn apply(pin: Pin, comptime cfg: Config) void {
        pin.enable();
        pin.set_mode(cfg.mode);
        pin.set_speed(cfg.speed);
        pin.set_pull(cfg.pull);
    }

    inline fn mask(pin: Pin) u16 {
        return @as(u16, 1) << pin.number;
    }

    pub inline fn set_mode(pin: Pin, mode: Mode) void {
        const port = Peripherals.to_reg(pin.gpio);

        const offset = (pin.number & 0b111) * 4;
        const cfg_bits = switch (mode) {
            .input => |input| (@as(u32, @backingInt(input)) << 2),
            .output => |output| (@as(u32, @backingInt(output)) << 2) | 1,
        };

        if (pin.number < 8) {
            port.CFGLR.raw &= ~(@as(u32, 0b1111) << offset);
            port.CFGLR.raw |= cfg_bits << offset;
        } else {
            port.CFGHR.raw &= ~(@as(u32, 0b1111) << offset);
            port.CFGHR.raw |= cfg_bits << offset;
        }
    }

    pub inline fn set_speed(pin: Pin, speed: Speed) void {
        const port = Peripherals.to_reg(pin.gpio);

        port.SPEED.raw &= ~(@as(u32, 0b11) << (pin.number * 2));
        port.SPEED.raw |= @as(u32, @backingInt(speed)) << (pin.number * 2);
    }

    pub inline fn set_pull(pin: Pin, pull: Pull) void {
        const port = Peripherals.to_reg(pin.gpio);

        switch (pull) {
            .up => port.OUTDR.raw |= pin.mask(),
            .down => port.OUTDR.raw &= ~pin.mask(),
            .disabled => {},
        }
    }

    pub inline fn read(pin: Pin) u1 {
        const port = Peripherals.to_reg(pin.gpio);
        return if ((port.INDR.raw & pin.mask()) == 0) 0 else 1;
    }

    pub inline fn put(pin: Pin, level: u1) void {
        const port = Peripherals.to_reg(pin.gpio);

        if (level == 1) {
            port.BSHR.raw = pin.mask();
        } else {
            port.BCR.raw = pin.mask();
        }
    }

    pub inline fn toggle(pin: Pin) void {
        const port = Peripherals.to_reg(pin.gpio);
        port.OUTDR.raw ^= pin.mask();
    }
};
