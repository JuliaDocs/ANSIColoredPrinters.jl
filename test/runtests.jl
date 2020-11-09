using Test, ANSIColoredPrinters

@testset "colors" begin
    include("colors.jl")
end
@testset "PlainTextPrinter" begin
    include("plain.jl")
end
@testset "HTMLPrinter" begin
    include("html.jl")
end
