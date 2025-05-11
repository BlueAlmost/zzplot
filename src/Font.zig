const nvg = @import("nanovg");

pub fn init(vg: nvg) void {
    const mnsymbol = @embedFile("FontDir/mnsymbol/MnSymbol12.ttf");
    _ = vg.createFontMem("symbols", mnsymbol);

    const entypo = @embedFile("FontDir/entypo.ttf");
    _ = vg.createFontMem("icons", entypo);

    const normal = @embedFile("FontDir/Roboto-Regular.ttf");
    _ = vg.createFontMem("sans", normal);

    const bold = @embedFile("FontDir/Roboto-Bold.ttf");
    _ = vg.createFontMem("sans-bold", bold);

    // DejaVuSans CREATE PROBLEMS WHEN USING AS A MARKER, SINCE CHARACTERS ARE
    // NOT CENTERED, CREATING OFFSET
    // const DejaVuSans = @embedFile("FontsDir/DejaVuSans.ttf");
    // _ = vg.createFontMem("symbols", DejaVuSans);
}
