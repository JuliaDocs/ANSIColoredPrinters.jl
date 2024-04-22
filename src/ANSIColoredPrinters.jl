module ANSIColoredPrinters

import Base: ==, show, showable

export PlainTextPrinter, HTMLPrinter

abstract type AbstractPrinter end

"""
    StackModelPrinter

An abstract printer type for stack-based or tree model formats.
"""
abstract type StackModelPrinter <: AbstractPrinter end

"""
    FlatModelPrinter

An abstract printer type for non-stack-based formats.
"""
abstract type FlatModelPrinter <: AbstractPrinter end


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

include("colors.jl")
include("plain.jl")
include("html.jl")

==(a::SGRContext, b::SGRContext) = a.fg == b.fg && a.bg == b.bg && a.flags == b.flags

isnormal(ctx::SGRContext) = isnormal(ctx.fg) && isnormal(ctx.bg) && !any(ctx.flags)

formal_fg(ctx::SGRContext) = ctx.fg
formal_bg(ctx::SGRContext) = ctx.bg
actual_fg(ctx::SGRContext) = ctx.flags[7] ? flip_fg_and_bg(ctx.bg) : ctx.fg
actual_bg(ctx::SGRContext) = ctx.flags[7] ? flip_fg_and_bg(ctx.fg) : ctx.bg

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
    if printer isa StackModelPrinter
        while !isempty(printer.stack)
            pop!(printer.stack)
        end
    end
    reset(printer.ctx)
    reset(printer.prevctx)
end

function copy!(dest::SGRContext, src::SGRContext)
    dest.fg = src.fg
    dest.bg = src.bg
    dest.flags .= src.flags
end

escape_char(printer::AbstractPrinter, c::Char) = nothing

function show_body(io::IO, printer::AbstractPrinter)
    reset(printer)
    buf = printer.buf
    ctx_changed = false
    while !eof(buf)
        c = read(buf, Char)
        if c !== '\e'
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
        c = read(buf, Char)
        c === '[' || continue
        while !eof(buf)
            c = read(buf, Char)
            if '0' <= c <= '9' || c === ';' # strip spaces
                write(ansiesc, c)
            elseif c >= Char(0x40)
                break
            end
        end
        astr = String(take!(ansiesc))
        if c === 'm'
            while true
                astr = parse_sgrcodes(printer.ctx, astr)
                isempty(astr) && break
            end
        end
        ctx_changed = printer.prevctx != printer.ctx
    end

    finalize(io, printer)
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

function apply_changes(io::IO, printer::StackModelPrinter)
    stack = printer.stack
    ctx = printer.ctx
    prevctx = printer.prevctx
    invert = prevctx.flags[7] != ctx.flags[7]

    marks = zeros(Bool, length(stack))
    nstack = String[]

    for di in 1:9
        if prevctx.flags[di] != ctx.flags[di]
            di == 7 && !printer.keep_invert && continue
            class = string(di)
            marks .|= map(c -> c == class, stack)
            ctx.flags[di] && push!(nstack, class)
        end
    end
    if printer.keep_invert
        prevfg, fg = formal_fg(prevctx), formal_fg(ctx)
        prevbg, bg = formal_bg(prevctx), formal_bg(ctx)
    else
        prevfg, fg = actual_fg(prevctx), actual_fg(ctx)
        prevbg, bg = actual_bg(prevctx), actual_bg(ctx)
    end
    if prevfg != fg || (printer.keep_invert && invert)
        marks .|= map(c -> occursin(r"^(?:3[0-7]|9[0-7]|38_[25]|-39)$", c), stack)
        if fg.class == "-1"
            push!(nstack, "-39")
        elseif !isnormal(fg)
            push!(nstack, fg.class)
        end
    end
    if prevbg != bg || (printer.keep_invert && invert)
        marks .|= map(c -> occursin(r"^(?:4[0-7]|10[0-7]|48_[25]|-49)$", c), stack)
        if bg.class == "-1"
            push!(nstack, "-49")
        elseif !isnormal(bg)
            push!(nstack, bg.class)
        end
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

function apply_changes(io::IO, printer::FlatModelPrinter)
    ansicodes = Int[]

    prevctx = printer.prevctx
    ctx = printer.ctx
    prevflags = prevctx.flags
    flags = ctx.flags

    prevctx == ctx && return

    if isnormal(ctx)
        change_state(io, printer, ansicodes)
        return
    end
    if prevflags[1] & !flags[1] || prevflags[2] & !flags[2]
        if !flags[1] && !flags[2]
            push!(ansicodes, 22)
            parse_sgrcodes(prevctx, "22")
        end
    end
    if prevflags[5] & !flags[5] || prevflags[6] & !flags[6]
        if !flags[5] && !flags[6]
            push!(ansicodes, 25)
            parse_sgrcodes(prevctx, "25")
        end
    end
    if printer.keep_invert
        prevfg, fg = formal_fg(prevctx), formal_fg(ctx)
        prevbg, bg = formal_bg(prevctx), formal_bg(ctx)
    else
        prevfg, fg = actual_fg(prevctx), actual_fg(ctx)
        prevbg, bg = actual_bg(prevctx), actual_bg(ctx)
    end
    prevfg != fg && append!(ansicodes, codes(fg, true))
    prevbg != bg && append!(ansicodes, codes(bg, false))

    for i in eachindex(flags)
        prevflags[i] === flags[i] && continue
        if 1 <= i <= 2 || 5 <= i <= 6
            flags[i] && push!(ansicodes, i)
        elseif i == 7
            printer.keep_invert && push!(ansicodes, flags[7] ? 7 : 27)
        elseif i <= 9
            push!(ansicodes, flags[i] ? i : i + 20)
        end
    end

    isempty(ansicodes) || change_state(io, printer, ansicodes)
end

function finalize(io::IO, printer::StackModelPrinter)
    while !isempty(printer.stack) # force closing
        end_current_state(io, printer)
        pop!(printer.stack)
    end
end

function finalize(io::IO, printer::FlatModelPrinter)
    reset(printer.ctx)
    printer.prevctx != printer.ctx && apply_changes(io, printer)
end


function Base.show(io::IO, ::MIME"text/plain", printer::AbstractPrinter)
    reset(printer)
    if get(io, :color, false)::Bool
        write(io, printer.buf)
    end
end

end # module
