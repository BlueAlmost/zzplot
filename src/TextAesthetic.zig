const nvg = @import("nanovg");
const Color = @import("Color.zig");

str: ?[]const u8 = null,
font_size: f32 = 20,
font_face: [:0]const u8 = "sans",
col: nvg.Color = Color.black,
rotation: f32 = 0.0,

alignment: nvg.TextAlign = nvg.TextAlign{},
