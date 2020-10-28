"""
    HTMLPrinter(buf::IO; root_class="")


"""
struct HTMLPrinter <: AbstractPrinter
    buf::IO
    stack::Vector{String}
    prevctx::SGRContext
    ctx::SGRContext
    root_class::String
    function HTMLPrinter(buf::IO; root_class::AbstractString="")
        new(buf, String[], SGRContext(), SGRContext(), String(root_class))
    end
end

Base.showable(::MIME"text/html", printer::HTMLPrinter) = isreadable(printer.buf)

const HTML_ESC_CHARS = Dict{UInt8, String}(
    UInt8('\'') => "&apos;",
    UInt8('\"') => "&quot;",
    UInt8('<') => "&lt;",
    UInt8('>') => "&gt;",
    UInt8('&') => "&amp;",
)

escape_char(::HTMLPrinter, c::UInt8) = get(HTML_ESC_CHARS, c, nothing)

function Base.show(io::IO, ::MIME"text/html", printer::HTMLPrinter)
    if isempty(printer.root_class)
        write(io, "<pre>\n")
    else
        write(io, "<pre class=\"", printer.root_class, "\">\n")
    end
    show_body(io, printer)
    write(io, "</pre>")
end

function start_new_state(io::IO, printer::HTMLPrinter)
    class = printer.stack[end]
    ctx = printer.ctx
    if occursin(r"^38_[25]$", class)
        write(io, "<span class=\"sgr", class, "\" style=\"color:#", ctx.fg.hex, "\">")
    elseif occursin(r"^48_[25]$", class)
        write(io, "<span class=\"sgr", class, "\" style=\"background:#", ctx.bg.hex, "\">")
    else
        write(io, "<span class=\"sgr", class, "\">")
    end
end

end_current_state(io::IO, printer::HTMLPrinter) = write(io, "</span>")
