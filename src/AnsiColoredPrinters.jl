module AnsiColoredPrinters

import Base: show, showable

export HTMLPrinter

struct SGRColor
    class::String
    hex::String
    SGRColor(class::AbstractString="", hex::AbstractString="") = new(class, hex)
end

mutable struct SGRContext
    fg::SGRColor
    bg::SGRColor
    flags::BitVector
    SGRContext() = new(SGRColor(), SGRColor(), falses(128))
end

abstract type AbstractPrinter end

include("colors.jl")
include("html.jl")

function reset_color(ctx::SGRContext)
    ctx.fg = SGRColor()
    ctx.bg = SGRColor()
end

function reset(ctx::SGRContext)
    reset_color(ctx)
    ctx.flags .= false
end

function reset(printer::AbstractPrinter)
    seekstart(printer.buf)
    while !isempty(printer.stack)
        pop!(printer.stack)
    end
    reset(printer.ctx)
    reset(printer.prevctx)
end

function copy!(dest::SGRContext, src::SGRContext)
    dest.fg = src.fg
    dest.bg = src.bg
    dest.flags .= src.flags
end

escape_char(printer::AbstractPrinter, c::UInt8) = nothing

function show_body(io::IO, printer::AbstractPrinter)
    reset(printer)
    buf = printer.buf
    ctx_changed = false
    while !eof(buf)
        c = read(buf, UInt8)
        if c !== UInt8('\e')
            if ctx_changed
                apply_changes(io, printer)
                copy!(printer.prevctx, printer.ctx)
                ctx_changed = false
            end
            ec = escape_char(printer, c)
            write(io, ec === nothing ? c : ec)
            continue
        end
        ansiesc = IOBuffer()
        c = read(buf, UInt8)
        c === UInt8('[') || continue
        while !eof(buf)
            c = read(buf, UInt8)
            if UInt8('0') <= c <= UInt8('9') || c == UInt8(';') # strip spaces
                write(ansiesc, c)
            elseif c >= 0x40
                break
            end
        end
        astr = String(take!(ansiesc))
        m = nothing
        if c === UInt8('m')
            while true
                astr = parse_sgrcodes(printer.ctx, astr)
                isempty(astr) && break
            end
        end
        ctx_changed = printer.prevctx != printer.ctx
    end

    while !isempty(printer.stack) # force closing
        end_current_state(io, printer)
        pop!(printer.stack)
    end
end

function parse_sgrcodes(ctx::SGRContext, astr::AbstractString)
    if (m = match(r"^0?(?:;|$)", astr)) !== nothing
        reset(ctx)
    elseif (m = match(r"^22;?", astr)) !== nothing
        reset_color(ctx)
        ctx.flags[1:2] .= false
    elseif (m = match(r"^2([3-57-9]);?", astr)) !== nothing
        di = parse(Int, m.captures[1])
        ctx.flags[di] = false
        ctx.flags[di + (di === 5)] = false
    elseif (m = match(r"^39;?", astr)) !== nothing
        ctx.fg = SGRColor()
    elseif (m = match(r"^49;?", astr)) !== nothing
        ctx.bg = SGRColor()
    elseif (m = match(r"^([349][0-7]|10[0-7]);?", astr)) !== nothing
        set_16colors!(ctx, m.captures[1])
    elseif (m = match(r"^([345]8);5;(\d{0,3});?", astr)) !== nothing
        d, col = m.captures
        d != "58" && set_256colors!(ctx, d, col) # code 58 is not yet supported
    elseif (m = match(r"^([345]8);2;(\d{0,3});(\d{0,3});(\d{0,3});?", astr)) !== nothing
        d, rs, gs, bs = m.captures
        d != "58" && set_24bitcolors!(ctx, d, rs, gs, bs) # code 58 is not yet supported
    elseif (m = match(r"^(\d);?", astr)) !== nothing
        di = parse(Int, m.captures[1])
        if di === 1 || di === 2
            ctx.flags[1:2] .= (di === 1, di === 2)
        elseif di === 5 || di === 6
            ctx.flags[5:6] .= (di === 5, di === 6)
        else
            ctx.flags[di] = true
        end
    elseif (m = match(r"^(\d+);?", astr)) !== nothing
        # unsupported
    else # unknown
        return ""
    end
    return astr[m.offset + lastindex(m.match):end]
end

function apply_changes(io::IO, printer::HTMLPrinter)
    stack = printer.stack
    ctx = printer.ctx
    prevctx = printer.prevctx
    invert = prevctx.flags[7] != ctx.flags[7]

    marks = zeros(Bool, length(stack))
    nstack = String[]

    for di = 1:9
        if prevctx.flags[di] != ctx.flags[di]
            class = string(di)
            marks .|= map(c -> c == class, stack)
            ctx.flags[di] && push!(nstack, class)
        end
    end
    if prevctx.fg != ctx.fg || invert
        marks .|= map(c -> occursin(r"^(?:3[0-7]|9[0-7]|38_[25])$", c), stack)
        isnormal(ctx.fg) || push!(nstack, ctx.fg.class)
    end
    if prevctx.bg != ctx.bg || invert
        marks .|= map(c -> occursin(r"^(?:4[0-7]|10[0-7]|48_[25])$", c), stack)
        isnormal(ctx.bg) || push!(nstack, ctx.bg.class)
    end
    poplevel = findfirst(marks)
    if poplevel !== nothing
        while length(stack) >= poplevel
            end_current_state(io, printer)
            class = pop!(stack)
            pop!(marks) || push!(nstack, class)
        end
    end
    while !isempty(nstack)
        class = pop!(nstack)
        push!(stack, class)
        start_new_state(io, printer)
    end
end

function Base.show(io::IO, ::MIME"text/plain", printer::AbstractPrinter)
    reset(printer)
    if get(io, :color, false)::Bool
        write(io, printer.buf)
    end
end

end # module
