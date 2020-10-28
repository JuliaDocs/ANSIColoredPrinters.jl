using Test, AnsiColoredPrinters

@testset "isnormal" begin
    n = AnsiColoredPrinters.SGRColor()
    @test AnsiColoredPrinters.isnormal(n)

    c16 = AnsiColoredPrinters.SGRColor("30")
    @test !AnsiColoredPrinters.isnormal(c16)

    c256 = AnsiColoredPrinters.SGRColor("38_5", "000")
    @test !AnsiColoredPrinters.isnormal(c256)
end

@testset "is216color" begin
    c000 = AnsiColoredPrinters.SGRColor("38_5", "000")
    @test AnsiColoredPrinters.is216color(c000)

    c080808 = AnsiColoredPrinters.SGRColor("48_5", "080808")
    @test !AnsiColoredPrinters.is216color(c080808)

    cabc = AnsiColoredPrinters.SGRColor("38_2", "abc")
    @test !AnsiColoredPrinters.is216color(cabc)
end

@testset "set_16colors!" begin
    ctx = AnsiColoredPrinters.SGRContext()

    AnsiColoredPrinters.set_16colors!(ctx, "30")
    @test ctx.fg.class == "30"
    @test isempty(ctx.fg.hex)
    @test AnsiColoredPrinters.codes(ctx.fg) === (30,)

    AnsiColoredPrinters.set_16colors!(ctx, "47")
    @test ctx.bg.class == "47"
    @test isempty(ctx.bg.hex)
    @test AnsiColoredPrinters.codes(ctx.bg) === (47,)

    AnsiColoredPrinters.set_16colors!(ctx, "97")
    @test ctx.fg.class == "97"
    @test isempty(ctx.fg.hex)
    @test AnsiColoredPrinters.codes(ctx.fg) === (97,)

    AnsiColoredPrinters.set_16colors!(ctx, "100")
    @test ctx.bg.class == "100"
    @test isempty(ctx.bg.hex)
    @test AnsiColoredPrinters.codes(ctx.bg) === (100,)
end

@testset "set_256colors!" begin
    ctx = AnsiColoredPrinters.SGRContext()

    # 16 colors
    AnsiColoredPrinters.set_256colors!(ctx, "38", "1")
    @test ctx.fg.class == "31"
    @test isempty(ctx.fg.hex)
    @test AnsiColoredPrinters.codes(ctx.fg) === (31,)

    AnsiColoredPrinters.set_256colors!(ctx, "48", "6")
    @test ctx.bg.class == "46"
    @test isempty(ctx.bg.hex)
    @test AnsiColoredPrinters.codes(ctx.bg) === (46,)

    AnsiColoredPrinters.set_256colors!(ctx, "38", "15")
    @test ctx.fg.class == "97"
    @test isempty(ctx.fg.hex)
    @test AnsiColoredPrinters.codes(ctx.fg) === (97,)

    AnsiColoredPrinters.set_256colors!(ctx, "48", "8")
    @test ctx.bg.class == "100"
    @test isempty(ctx.bg.hex)
    @test AnsiColoredPrinters.codes(ctx.bg) === (100,)

    # 216 colors (6 * 6 * 6)
    AnsiColoredPrinters.set_256colors!(ctx, "38", "16")
    @test ctx.fg.class == "38_5"
    @test ctx.fg.hex == "000"
    @test AnsiColoredPrinters.codes(ctx.fg) === (38, 5, 16)

    AnsiColoredPrinters.set_256colors!(ctx, "48", "17")
    @test ctx.bg.class == "48_5"
    @test ctx.bg.hex == "00005f"
    @test AnsiColoredPrinters.codes(ctx.bg) === (48, 5, 17)

    AnsiColoredPrinters.set_256colors!(ctx, "38", "110")
    @test ctx.fg.class == "38_5"
    @test ctx.fg.hex == "87afd7"
    @test AnsiColoredPrinters.codes(ctx.fg) === (38, 5, 110)

    AnsiColoredPrinters.set_256colors!(ctx, "38", "230")
    @test ctx.fg.class == "38_5"
    @test ctx.fg.hex == "ffffd7"
    @test AnsiColoredPrinters.codes(ctx.fg) === (38, 5, 230)

    AnsiColoredPrinters.set_256colors!(ctx, "48", "231")
    @test ctx.bg.class == "48_5"
    @test ctx.bg.hex == "fff"
    @test AnsiColoredPrinters.codes(ctx.bg) === (48, 5, 231)

    # grays
    AnsiColoredPrinters.set_256colors!(ctx, "38", "232")
    @test ctx.fg.class == "38_5"
    @test ctx.fg.hex == "080808"
    @test AnsiColoredPrinters.codes(ctx.fg) === (38, 5, 232)

    AnsiColoredPrinters.set_256colors!(ctx, "48", "255")
    @test ctx.bg.class == "48_5"
    @test ctx.bg.hex == "eee"
    @test AnsiColoredPrinters.codes(ctx.bg) === (48, 5, 255)
end

@testset "set_24bitcolors" begin
    ctx = AnsiColoredPrinters.SGRContext()

    AnsiColoredPrinters.set_24bitcolors!(ctx, "38", "0", "128", "255")
    @test ctx.fg.class == "38_2"
    @test ctx.fg.hex == "0080ff"
    @test AnsiColoredPrinters.codes(ctx.fg) === (38, 2, 0, 128, 255)

    AnsiColoredPrinters.set_24bitcolors!(ctx, "48", "170", "187", "204")
    @test ctx.bg.class == "48_2"
    @test ctx.bg.hex == "abc"
    @test AnsiColoredPrinters.codes(ctx.bg) === (48, 2, 170, 187, 204)

    # 216 colors
    AnsiColoredPrinters.set_24bitcolors!(ctx, "38", "0", "0", "0")
    @test ctx.fg.class == "38_5"
    @test ctx.fg.hex == "000"
    @test AnsiColoredPrinters.codes(ctx.fg) === (38, 5, 16)

    AnsiColoredPrinters.set_24bitcolors!(ctx, "48", "0", "0", "95")
    @test ctx.bg.class == "48_5"
    @test ctx.bg.hex == "00005f"
    @test AnsiColoredPrinters.codes(ctx.bg) === (48, 5, 17)

    # grays
    AnsiColoredPrinters.set_24bitcolors!(ctx, "38", "8", "8", "8")
    @test ctx.fg.class == "38_5"
    @test ctx.fg.hex == "080808"
    @test AnsiColoredPrinters.codes(ctx.fg) === (38, 5, 232)

    AnsiColoredPrinters.set_24bitcolors!(ctx, "48", "238", "238", "238")
    @test ctx.bg.class == "48_5"
    @test ctx.bg.hex == "eee"
    @test AnsiColoredPrinters.codes(ctx.bg) === (48, 5, 255)
end
