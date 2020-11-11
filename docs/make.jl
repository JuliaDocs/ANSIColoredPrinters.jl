using Documenter, ANSIColoredPrinters

makedocs(
    clean = false,
    checkdocs = :exports,
    modules=[ANSIColoredPrinters],
    format=Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true",
                           assets = ["assets/default.css"]),
    sitename="ANSIColoredPrinters",
    pages=[
        "Introduction" => "index.md",
        "Output Formats" => "output-formats.md",
        "Supported Codes" => "supported-codes.md",
        "Reference" => "reference.md",
    ]
)

deploydocs(
    repo="github.com/JuliaDocs/ANSIColoredPrinters.jl.git",
    devbranch = "main",
    push_preview = true
)
