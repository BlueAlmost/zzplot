const std = @import("std");
const print = std.debug.print;

pub const zzplot = @import("zzplot_import_name");
pub const nanovg = @import("nanovg_import_name");

pub const Figure = @import("Figure.zig").Figure;

pub const Axes = @import("Axes.zig").Axes;
pub const AxesAes = @import("Axes.zig").Aes;

pub const Ticks = @import("Ticks.zig");

pub const Plot = @import("Plot.zig").Plot;
pub const PlotAes = @import("Plot.zig").Aes;

pub const TextAes = @import("TextAesthetics.zig");

pub const createShared = @import("util.zig").createShared;
pub const Font = @import("Font.zig");
pub const Color = @import("Color.zig");

pub const int = @import("util.zig").int;
pub const isInt = @import("util.zig").isInt;
pub const float = @import("util.zig").float;
pub const minMax = @import("util.zig").minMax;
pub const cpToUTF8 = @import("util.zig").cpToUTF8;

pub const anyLive = @import("util.zig").anyLive;
