using Test, ANSIColoredPrinters

@testset "plain" begin
    buf = IOBuffer()
    print(buf, "This is a plain text.")

    hp = HTMLPrinter(buf)

    io = IOBuffer()
    show(io, MIME"text/html"(), hp)
    @test "<pre>\nThis is a plain text.</pre>" == String(take!(io))
end

@testset "escape" begin
    buf = IOBuffer()
    print(buf, "\"HTMLWriter\" uses '<pre>' & '<span>' elements.")

    hp = HTMLPrinter(buf)

    io = IOBuffer()
    show(io, MIME"text/html"(), hp)
    @test "<pre>\n&quot;HTMLWriter&quot; uses &#39;&lt;pre&gt;&#39; &amp; " *
          "&#39;&lt;span&gt;&#39; elements.</pre>" == String(take!(io))
end
