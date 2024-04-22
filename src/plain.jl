
struct PlainTextPrinter <: FlatModelPrinter
    buf::IO
    prevctx::SGRContext
    ctx::SGRContext
    keep_invert::Bool
    function PlainTextPrinter(buf::IO; keep_invert::Bool=true)
        new(buf, SGRContext(), SGRContext(), keep_invert)
    end
end

"""
    PlainTextPrinter(buf::IO; keep_invert=true)

Creates a printer for `MIME"text/plain"` output.

# Arguments
- `buf`: A source `IO` object containing a text with ANSI escape codes.
- `keep_invert`: If true, "invert" (SGR code 7) is printed as is.

If `keep_invert` is `false`, the color change codes with "invert" enable are
reinterpreted as explicit foreground and background color specifications.
In this case, the normal inverted foreground color is considered black (SGR code
 30) and the normal inverted background color is considered white (SGR code 47).
"""
function PlainTextPrinter end

Base.showable(::MIME"text/plain", printer::PlainTextPrinter) = isreadable(printer.buf)

function Base.show(io::IO, ::MIME"text/plain", printer::PlainTextPrinter)
    show_body(io, printer)
end

function change_state(io::IO, printer::PlainTextPrinter, ansicodes::Vector{Int})
    get(io, :color, false) || return
    if isempty(ansicodes)
        print(io, "\e[m")
    else
        if !printer.keep_invert
            # normal inverted foreground color => 30 (black)
            # normal inverted background color => 47 (white)
            replace!(ansicodes, -39 => 30, -49 => 47)
        end
        print(io, "\e[", join(ansicodes, ';'), 'm')
    end
end
