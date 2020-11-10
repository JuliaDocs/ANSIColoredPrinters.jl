# ANSIColoredPrinters

ANSIColoredPrinters converts a text qualified by
[ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code) to another
format. Currently, [plain text](@ref plain_text) and [HTML](@ref html) output
are supported.

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

All you need to do is to pass an `IO` object, which contains a text qualified
with ANSI escape codes as the first argument of the constructor of a printer
(e.g. [`HTMLPrinter`](@ref)).

On environments which support `MIME"text/html"` display (e.g. this Documenter's
HTML output), the text is displayed as HTML with its ANSI escape codes are
translated into HTML elements by [`HTMLPrinter`](@ref).

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
print(String(take!(htmlsrc))[1:119], "...") # hide
```

In addition, the colors and text styles are controlled by the CSS in the host
document (e.g. [`default.css`](./assets/default.css)).
