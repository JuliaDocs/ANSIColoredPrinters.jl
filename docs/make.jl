using Documenter, ANSIColoredPrinters

makedocs(
    clean = false,
    modules=[ANSIColoredPrinters],
    format=Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true",
                           assets = ["assets/default.css"]),
    sitename="ANSIColoredPrinters",
    pages=[
        "Introduction" => "index.md",
        "Supported Codes" => "supported-codes.md",
        "Reference" => "reference.md",
    ]
)

deploydocs(
    repo="github.com/kimikage/ANSIColoredPrinters.jl.git",
    devbranch = "main",
    push_preview = true
)
