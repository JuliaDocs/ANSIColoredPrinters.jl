# ANSIColoredPrinters

ANSIColoredPrinters converts a UTF-8 text qualified by
[ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code) to another
format. Currently, only conversion to an HTML ([`HTMLPrinter`](@ref)) is
implemented.

## Installation
The package can be installed with the Julia package manager. Run:
```julia
import Pkg
Pkg.add("ANSIColoredPrinters")
```
or, from the Julia REPL, type `]` to enter the Pkg REPL mode and run:
```julia
pkg> add ANSIColoredPrinters
```

## Usage

All you need to do is to pass an `IO` object containing a UTF-8 text qualified
by ANSI escape codes as the first argument of the constructor of
[`HTMLPrinter`](@ref). On environments which support `"text/html"` display (e.g.
this Documenter's HTML output), the text is displayed as HTML with its ANSI
escape codes are translated into HTML elements.

```@example ex
using ANSIColoredPrinters
using Crayons

buf = IOBuffer()
Crayons.print_logo(buf) # this outputs ANSI escape codes.

printer = HTMLPrinter(buf, root_class="documenter-example-output")
```

Perhaps your browser is displaying a colored logo, but the `HTMLPrinter`
actually outputs HTML code that looks like:

```@example ex
htmlsrc = IOBuffer() # hide
show(htmlsrc, MIME"text/html"(), printer) # hide
print(String(take!(htmlsrc))[1:120], "...") # hide
```

In addition, the colors and text styles are controlled by the CSS in the host
document (e.g. [`default.css`](./assets/default.css)).
