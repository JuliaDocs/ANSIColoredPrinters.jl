
struct PlainTextPrinter <: FlatModelPrinter
    buf::IO
    prevctx::SGRContext
    ctx::SGRContext
    function PlainTextPrinter(buf::IO)
        new(buf, SGRContext(), SGRContext())
    end
end

"""
    PlainTextPrinter(buf::IO)

Creates a printer for `MIME"text/plain"` output.

# Arguments
- `buf`: A source `IO` object containing a text with ANSI escape codes.
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
        print(io, "\e[", join(ansicodes, ';'), 'm')
    end
end
