# Output Formats
```@setup ex
using ANSIColoredPrinters
```
## [Plain Text](@id plain_text)

[`PlainTextPrinter`](@ref) prints a plain text with ANSI escape codes as a plain
text (`MIME"text/plain"`). This may seem useless, but it has two major benefits.

One is the stripping of ANSI escape codes. You can get rid of ANSI escape codes
by printing a text to an `IO` object with `:color` I/O property `false`.

The other is the optimization of verbose ANSI escape codes.

### Examples
```@repl ex
src = IOBuffer();

printstyled(IOContext(src, :color => true), "light ", color=:light_cyan);
printstyled(IOContext(src, :color => true), "cyan", color=:light_cyan);

read(seekstart(src), String) # source text

printer = PlainTextPrinter(src);
repr("text/plain", printer, context = :color => false) # stripped
repr("text/plain", printer, context = :color => true) # optimized
```

!!! note
    The initial and final states are implicitly interpreted as being "Normal",
    i.e. the state with `"\e[0m"`.

## [HTML](@id html)
[`HTMLPrinter`](@ref) prints a plain text with ANSI escape codes as an HTML
fragment (`MIME"text/html"`).

See [Supported Codes](@ref) for examples.