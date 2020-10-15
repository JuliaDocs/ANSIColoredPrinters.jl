module AnsiColoredPrinters

import Base: show, showable

export HTMLPrinter

mutable struct SGRContext
    fg::String
    fghex::String
    bg::String
    bghex::String
    d1::Vector{Bool}
    SGRContext() = new("", "", "", "", zeros(Bool, 9))
end

abstract type AbstractPrinter end

include("colors.jl")
include("html.jl")

function reset(ctx::SGRContext)
    ctx.fg, ctx.fghex = "", ""
    ctx.bg, ctx.bghex = "", ""
    ctx.d1 .= false
end

function reset(printer::AbstractPrinter)
    seekstart(printer.buf)
    while !isempty(printer.stack)
        pop!(printer.stack)
    end
    reset(printer.ctx)
    reset(printer.prevctx)
end

escape_char(printer::AbstractPrinter, c::UInt8) = nothing

function show_body(io::IO, printer::AbstractPrinter)
    reset(printer)
    buf = printer.buf
    ctx = printer.ctx

    while !eof(buf)
        c = read(buf, UInt8)
        if c !== UInt8('\e')
            apply_changes(io, printer)
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
            while !isempty(astr)
                if (m = match(r"^0?(?:;|$)", astr)) !== nothing
                    reset(ctx)
                elseif (m = match(r"^22;?", astr)) !== nothing
                    ctx.fg, ctx.bg = "", ""
                    ctx.d1[1:2] .= false
                elseif (m = match(r"^39;?", astr)) !== nothing
                    ctx.fg = ""
                elseif (m = match(r"^49;?", astr)) !== nothing
                    ctx.bg = ""
                elseif (m = match(r"^([349][0-7]|10[0-7]);?", astr)) !== nothing
                    set_16colors!(ctx, m.captures[1])
                elseif (m = match(r"^([34]8);5;(\d{0,3});?", astr)) !== nothing
                    set_256colors!(ctx, m.captures[1], m.captures[2])
                elseif (m = match(r"^([34]8);2;(\d{0,3});(\d{0,3});(\d{0,3});?",
                                  astr)) !== nothing
                    d, rs, gs, bs = m.captures
                    set_24bitcolors!(ctx, d, rs, gs, bs)
                elseif (m = match(r"^(\d);?", astr)) !== nothing
                    di = parse(Int, m.captures[1])
                    if di === 1 || di === 2
                        ctx.d1[1:2] .= (di === 1, di === 2)
                    elseif di === 5 || di === 6
                        ctx.d1[5:6] .= (di === 5, di === 6)
                    else
                        ctx.d1[di] = true
                    end
                else # unsupported
                    break
                end
                astr = astr[m.offset + lastindex(m.match):end]
            end
        end
    end

    while !isempty(printer.stack) # force closing
        end_current_state(io, printer)
        pop!(printer.stack)
    end
end

function apply_changes(io::IO, printer::HTMLPrinter)
    stack = printer.stack
    ctx = printer.ctx
    prevctx = printer.prevctx

    marks = zeros(Bool, length(stack))
    nstack = String[]
    for di = 1:9
        if prevctx.d1[di] != ctx.d1[di]
            prevctx.d1[di] = ctx.d1[di]
            class = "sgr$di"
            marks .|= map(c -> c == class, stack)
            ctx.d1[di] && push!(nstack, class)
        end
    end
    if prevctx.fg != ctx.fg || prevctx.fghex != ctx.fghex
        prevctx.fg, prevctx.fghex = ctx.fg, ctx.fghex
        marks .|= map(c -> occursin(r"^sgr(?:3[0-7]|9[0-7]|38_[25])$", c), stack)
        isempty(ctx.fg) || push!(nstack, ctx.fg)
    end
    if prevctx.bg != ctx.bg || prevctx.bghex != ctx.bghex
        prevctx.bg, prevctx.bghex = ctx.bg, ctx.bghex
        marks .|= map(c -> occursin(r"^sgr(?:4[0-7]|10[0-7]|48_[25])$", c), stack)
        isempty(ctx.bg) || push!(nstack, ctx.bg)
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
