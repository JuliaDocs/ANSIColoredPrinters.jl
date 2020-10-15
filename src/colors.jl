
function short_hex(r::UInt8, g::UInt8, b::UInt8)
    rgb6 = UInt32(r) << 0x10 + UInt32(g) << 0x8 + b
    rgb6 === (rgb6 & 0x0f0f0f) * 0x11 || return string(rgb6, pad=6, base=16)
    string(UInt16(r >> 0x4) << 0x8 + UInt16(g >> 0x4) << 0x4 + b >> 0x4, pad=3, base=16)
end

function set_16colors!(ctx::SGRContext, d::AbstractString)
    class = "sgr" * d
    if d[1] === '3' || d[1] === '9'
        ctx.fg, ctx.fghex = class, ""
    else
        ctx.bg, ctx.bghex = class, ""
    end
end

function set_256colors!(ctx::SGRContext, d::AbstractString, color::AbstractString)
    fore = d[1] === '3'
    class = "sgr"
    hex = ""
    colorid = isempty(color) ? 0x0 : parse(UInt8, color)
    if colorid < 0x8
        class *= d[1] * string(colorid)
    elseif colorid < 0x10
        class *= (fore ? "9" : "10") * string(colorid - 0x8)
    else
        if colorid < 0xe8
            c = colorid - 0x10
            r = c ÷ 0x24
            g = c ÷ 0x6 % 0x6
            b = c % 0x6
            hex = string(r * 0x300 + g * 0x30 + b * 0x3, pad=3, base=16)
        else
            g = (colorid - 0xe8) * 0xa + 0x8
            hex = short_hex(g, g, g)
        end
        class *= d * "_5"
    end

    if fore
        ctx.fg, ctx.fghex = class, hex
    else
        ctx.bg, ctx.bghex = class, hex
    end
end

function set_24bitcolors!(ctx::SGRContext, d::AbstractString,
                          r::AbstractString, g::AbstractString, b::AbstractString)
    r8 = isempty(r) ? 0x0 : parse(UInt8, r)
    g8 = isempty(g) ? 0x0 : parse(UInt8, g)
    b8 = isempty(b) ? 0x0 : parse(UInt8, b)
    hex = short_hex(r8, g8, b8)
    if occursin(r"^[0369cf]{3}$", hex) || (r8 === g8 === b8 && (r8 - 8) % 10 == 0)
        class = "sgr" * d * "_5"
    else
        class = "sgr" * d * "_2"
    end
    if d == "38"
        ctx.fg, ctx.fghex = class, hex
    else
        ctx.bg, ctx.bghex = class, hex
    end
end
