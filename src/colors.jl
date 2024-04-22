
isnormal(c::SGRColor) = isempty(c.class)

is216color(c::SGRColor) = is216color(c.hex)

function is216color(hex::AbstractString)
    hex == "000" || hex == "fff" || occursin(r"(?:00|5f|87|af|d7|ff){3}$", hex)
end

function flip_fg_and_bg(c::SGRColor)
    # Note that the normal foreground color is not the normal background color.
    # For convenience, we use the class "-1" for normal inverted color.
    c.class == "" && return SGRColor("-1", c.hex)
    c.class == "-1" && return SGRColor("", c.hex)

    m = match(r"^([345]8)_([25])$", c.class)
    if m === nothing
        code = parse(Int, c.class)
        if 30 <= code <= 39
            class = string(code + 10)
        elseif 40 <= code <= 49
            class = string(code - 10)
        elseif 90 <= code <= 97
            class = string(code + 10)
        elseif 100 <= code <= 107
            class = string(code - 10)
        end
    else
        if m[1] == "3"
            class = "48_" * m[2]
        elseif m[1] == "4"
            class = "38_" * m[2]
        end
    end
    return SGRColor(class, c.hex)
end

function codes(c::SGRColor, foreground::Bool)
    if isnormal(c)
        return foreground ? (39,) : (49,)
    end
    if c.class == "-1"
        return foreground ? (-39,) : (-49,)
    end
    return codes(c)
end

function codes(c::SGRColor)
    m = match(r"^([345]8)_([25])$", c.class)
    m === nothing && return (parse(Int, c.class),)
    code, sub = m.captures
    codei = parse(Int, code)
    if sub == "5"
        if is216color(c)
            h = parse(UInt32, c.hex, base=16)
            h === 0x00000fff && return (codei, 5, 231)
            r = (h >> 0x10) % UInt8 ÷ 0x30
            g = (h >> 0x08) % UInt8 ÷ 0x30
            b = (h >> 0x00) % UInt8 ÷ 0x30
            return (codei, 5, (r * 0x24 + g * 0x6 + b) + 16)
        else
            h = parse(UInt8, c.hex[1:2], base=16)
            g = (h - 0x8) ÷ 0xa
            return (codei, 5, g + 232)
        end
    else
        if length(c.hex) == 3
            h = parse(UInt16, c.hex, base=16)
            r = (h >> 0x8)
            g = (h >> 0x4) & 0xf
            b = h & 0xf
            return (codei, 2, r * 17, g * 17, b * 17)
        else
            h = parse(UInt32, c.hex, base=16)
            r = (h >> 0x10)
            g = (h >> 0x8) & 0xff
            b = h & 0xff
            return (codei, 2, Int(r), Int(g), Int(b))
        end
    end
end

function short_hex(r::UInt8, g::UInt8, b::UInt8)
    rgb6 = UInt32(r) << 0x10 + UInt32(g) << 0x8 + b
    rgb6 === (rgb6 & 0x0f0f0f) * 0x11 || return string(rgb6, pad=6, base=16)
    string(UInt16(r >> 0x4) << 0x8 + UInt16(g >> 0x4) << 0x4 + b >> 0x4, pad=3, base=16)
end

function set_16colors!(ctx::SGRContext, d::AbstractString)
    if d[1] === '3' || d[1] === '9'
        ctx.fg = SGRColor(d)
    else
        ctx.bg = SGRColor(d)
    end
end

const SCALE_216 = UInt8[0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff]

function set_256colors!(ctx::SGRContext, d::AbstractString, color::AbstractString)
    fore = d[1] === '3'
    hex = ""
    colorid = isempty(color) ? 0x0 : parse(UInt8, color)
    if colorid < 0x8
        class = d[1] * string(colorid)
    elseif colorid < 0x10
        class = (fore ? "9" : "10") * string(colorid - 0x8)
    else
        if colorid < 0xe8
            c = colorid - 0x10
            r = SCALE_216[c ÷ 0x24 + 1]
            g = SCALE_216[c ÷ 0x6 % 0x6 + 1]
            b = SCALE_216[c % 0x6 + 1]
            hex = short_hex(r, g, b)
        else
            g = (colorid - 0xe8) * 0xa + 0x8
            hex = short_hex(g, g, g)
        end
        class = d * "_5"
    end

    if fore
        ctx.fg = SGRColor(class, hex)
    else
        ctx.bg = SGRColor(class, hex)
    end
end

function set_24bitcolors!(ctx::SGRContext, d::AbstractString,
                          r::AbstractString, g::AbstractString, b::AbstractString)
    r8 = isempty(r) ? 0x0 : parse(UInt8, r)
    g8 = isempty(g) ? 0x0 : parse(UInt8, g)
    b8 = isempty(b) ? 0x0 : parse(UInt8, b)
    hex = short_hex(r8, g8, b8)
    if is216color(hex) || (r8 === g8 === b8 && (r8 - 8) % 10 == 0)
        class = d * "_5"
    else
        class = d * "_2"
    end
    if d == "38"
        ctx.fg = SGRColor(class, hex)
    else
        ctx.bg = SGRColor(class, hex)
    end
end
