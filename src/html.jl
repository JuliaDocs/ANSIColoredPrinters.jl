
struct HTMLPrinter <: StackModelPrinter
    buf::IO
    stack::Vector{String}
    prevctx::SGRContext
    ctx::SGRContext
    root_class::String
    root_tag::String
    callback::Any
    function HTMLPrinter(buf::IO;
                         root_class::AbstractString = "",
                         root_tag::AbstractString = "pre",
                         callback::Any = nothing)
        new(buf, String[], SGRContext(), SGRContext(),
            String(root_class), String(root_tag), callback)
    end
end

"""
    HTMLPrinter(buf::IO; root_class="", root_tag="pre", callback=nothing)

Creates a printer for `MIME"text/html"` output.

# Arguments
- `buf`: A source `IO` object containing a text with ANSI escape codes.
- `root_class`: The `class` attribute value for the root element.
- `root_tag`: The tag name for the root element.
- `callback`: A callback method (see below).

# Callback method

    callback(io::IO, printer::HTMLPrinter, tag::String, attrs::Dict{Symbol, String})

The `callback` method will be called just before writing HTML tags.

## Callback arguments
- `io`: The destination `IO` object.
- `printer`: The `HTMLPrinter` in use.
- `tag`: The HTML tag to be written. For closing tags, they have the prefix "/".
- `attrs`: A dictionary consisting of pairs of a `Symbol` for the attributes
  (e.g. `:class`, `:style`) and the `String` for its value.

## Callback return value
If the return value is `nothing`, the printer writes the HTML tag to the `io`
according to the `tag` and the `attrs` after the call. If the return value is
not `nothing`, this default writing will be prevented.
"""
function HTMLPrinter end

Base.showable(::MIME"text/html", printer::HTMLPrinter) = isreadable(printer.buf)

const HTML_ESC_CHARS = Dict{Char, String}(
    '\'' => "&#39;",
    '\"' => "&quot;",
    '<' => "&lt;",
    '>' => "&gt;",
    '&' => "&amp;",
)

escape_char(::HTMLPrinter, c::Char) = get(HTML_ESC_CHARS, c, nothing)

function Base.show(io::IO, ::MIME"text/html", printer::HTMLPrinter)
    tag = printer.root_tag
    attrs = Dict{Symbol, String}()
    isempty(printer.root_class) || push!(attrs, :class => printer.root_class)

    write_htmltag(io, printer, printer.root_tag, attrs)

    show_body(io, printer)

    write_htmltag(io, printer, "/" * printer.root_tag)
end

function start_new_state(io::IO, printer::HTMLPrinter)
    class = printer.stack[end]
    ctx = printer.ctx
    attrs = Dict{Symbol, String}(:class => "sgr" * class)

    if occursin(r"^38_[25]$", class)
        push!(attrs, :style => "color:#" * ctx.fg.hex)
    elseif occursin(r"^48_[25]$", class)
        push!(attrs, :style => "background:#" * ctx.bg.hex)
    end

    write_htmltag(io, printer, "span", attrs)
end

function end_current_state(io::IO, printer::HTMLPrinter)
    write_htmltag(io, printer, "/span", )
end

function write_htmltag(io::IO, printer::HTMLPrinter,
                       tag::String, attrs::Dict{Symbol, String} = Dict{Symbol, String}())
    if printer.callback !== nothing
        result = printer.callback(io, printer, tag, attrs)
        result === nothing || return
    end
    write(io, "<", tag)
    for k in sort!(collect(keys(attrs)))
        v = attrs[k]
        isempty(v) && continue
        write(io, " ", k, "=\"", v, "\"")
    end
    write(io, ">")
end
