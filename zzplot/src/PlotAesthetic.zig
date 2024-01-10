const zzplot = @import("zzplot_import_name");
const nvg = zzplot.nanovg;
const Color = zzplot.Color;

pub const LineStyle = enum {
    none,
    solid,
};

line_width: f32 = 1,
line_style: LineStyle = LineStyle.solid,
line_col: nvg.Color = Color.black,

// plot marker attributes
marker: Marker = Marker.none,
marker_col: nvg.Color = Color.black,
marker_size: f32 = 8.0,

grid: bool = false,

// using mnsymbol ttf imported as "symbols"
pub const Marker = enum(u21) {
    none = 0x0000,
    asterisk = 0x2217,
    bowtie = 0x22C8,

    cdot = 0x22C5,

    circle = 0x25EF,
    circleAsterisk = 0x229B,
    circleFilled = 0x25CF,
    circleDot = 0x2299,
    circlePlus = 0x2295,
    circleRing = 0x229A,
    circleStar = 0x235F,
    circleTimes = 0x2297,

    diamond = 0x25C7,
    diamondFilled = 0x25C6,

    hourGlass = 0x29D6,

    lozenge = 0x25CA,
    lozengeFilled = 0x29EB,

    malteseCross = 0x2720,

    plus = 0x002B,

    square = 0x25FB,
    squareDot = 0x22A1,
    squareFilled = 0x220E,
    squarePlus = 0x229E,
    squareTimes = 0x22A0,

    star = 0x2606,
    starFilled = 0x2605,

    times = 0x00D7,

    triangleDown = 0x25BD,
    triangleDownFilled = 0x25BC,
    triangleLeft = 0x25C1,
    triangleLeftFilled = 0x25C0,
    triangleUp = 0x25B3,
    triangleUpFilled = 0x25B2,
    triangleRight = 0x25B7,
    triangleRightFilled = 0x25B6,
};
