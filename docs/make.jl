using Documenter, AnsiColoredPrinters

makedocs(
    clean = false,
    modules=[AnsiColoredPrinters],
    format=Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true",
                           assets = ["assets/default.css"]),
    sitename="AnsiColoredPrinters",
    pages=[
        "Introduction" => "index.md",
        "Supported Codes" => "supported-codes.md",
        "Reference" => "reference.md",
    ]
)

deploydocs(
    repo="github.com/kimikage/AnsiColoredPrinters.jl.git",
    devbranch = "main",
    push_preview = true
)
