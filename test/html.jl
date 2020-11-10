using Test, ANSIColoredPrinters

function repr_html(printer::HTMLPrinter)
    result = repr("text/html", printer)
    take!(printer.buf)
    return result
end

@testset "plain" begin
    buf = IOBuffer()
    printer = HTMLPrinter(buf)

    print(buf, "This is a plain text.")
    @test repr_html(printer) == "<pre>This is a plain text.</pre>"
end

@testset "escape" begin
    buf = IOBuffer()
    printer = HTMLPrinter(buf)

    print(buf, "\"HTMLWriter\" uses '<pre>' & '<span>' elements.")
    result = repr_html(printer)
    @test result == "<pre>&quot;HTMLWriter&quot; uses &#39;&lt;pre&gt;&#39; &amp; " *
                    "&#39;&lt;span&gt;&#39; elements.</pre>"
end

@testset "single modification" begin
    buf = IOBuffer()
    printer = HTMLPrinter(buf)

    @testset "bold/faint" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[1m", " Bold ")
        print(buf, "\e[2m", " Faint ")
        print(buf, "\e[22m", " Normal ")
        result = repr_html(printer)
        @test result == """<pre> Normal <span class="sgr1"> Bold </span>""" *
                        """<span class="sgr2"> Faint </span> Normal </pre>"""
    end

    @testset "fg/bg" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[36m", " CyanFG ")
        print(buf, "\e[39;44m", " BlueBG ")
        print(buf, "\e[49m", " Normal ")
        result = repr_html(printer)
        @test result == """<pre> Normal <span class="sgr36"> CyanFG </span>""" *
                        """<span class="sgr44"> BlueBG </span> Normal </pre>"""
    end

    @testset "blink" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[5m", " Blink ")
        print(buf, "\e[6m", " RapidBlink ")
        print(buf, "\e[25m", " Normal ")
        result = repr_html(printer)
        @test result == """<pre> Normal <span class="sgr5"> Blink </span>""" *
                        """<span class="sgr6"> RapidBlink </span> Normal </pre>"""
    end
end

@testset "nested modification" begin
    buf = IOBuffer()
    printer = HTMLPrinter(buf)

    @testset "bold/italic" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[1m", " Bold ")
        print(buf, "\e[3m", " Bold-Italic ")
        print(buf, "\e[23m", " Bold ")
        print(buf, "\e[0m", " Normal ")
        result = repr_html(printer)
        @test result == """<pre> Normal <span class="sgr1"> Bold """ *
                        """<span class="sgr3"> Bold-Italic </span>""" *
                        """ Bold </span> Normal </pre>"""

        print(buf, "\e[3m", " Italic ")
        print(buf, "\e[1m", " Bold-Italic ")
        print(buf, "\e[22m", " Italic ")
        print(buf, "\e[0m", " Normal ")
        result = repr_html(printer)
        @test result == """<pre><span class="sgr3"> Italic """ *
                        """<span class="sgr1"> Bold-Italic </span>""" *
                        """ Italic </span> Normal </pre>"""
    end

    @testset "bold/fg" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[1m", " Bold ")
        print(buf, "\e[36m", " Bold-CyanFG ")
        print(buf, "\e[39m", " Bold ")
        print(buf, "\e[0m", " Normal ")
        result = repr_html(printer)
        @test result == """<pre> Normal <span class="sgr1"> Bold """ *
                        """<span class="sgr36"> Bold-CyanFG </span>""" *
                        """ Bold </span> Normal </pre>"""
    end

    @testset "strike/blink" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[9m", " Strike ")
        print(buf, "\e[5m", " Strike-Blink ")
        print(buf, "\e[25m", " Strike ")
        print(buf, "\e[29m", " Normal ")
        result = repr_html(printer)
        @test result == """<pre> Normal <span class="sgr9"> Strike """ *
                        """<span class="sgr5"> Strike-Blink </span>""" *
                        """ Strike </span> Normal </pre>"""
    end

    @testset "fg/bg" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[96m", " LightCyanFG ")
        print(buf, "\e[45m", " LightCyanFG-MagentaBG ")
        print(buf, "\e[49m", " LightCyanFG ")
        print(buf, "\e[39m", " Normal ")
        result = repr_html(printer)
        @test result == """<pre> Normal <span class="sgr96"> LightCyanFG """ *
                        """<span class="sgr45"> LightCyanFG-MagentaBG </span>""" *
                        """ LightCyanFG </span> Normal </pre>"""
    end
end

@testset "overlapped modification" begin
    buf = IOBuffer()
    printer = HTMLPrinter(buf)

    @testset "bold/fg" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[1m", " Bold ")
        print(buf, "\e[36m", " Bold-CyanFG ")
        print(buf, "\e[22;36m", " CyanFG ")
        print(buf, "\e[39m", " Normal ")
        result = repr_html(printer)
        @test result == """<pre> Normal <span class="sgr1"> Bold """ *
                        """<span class="sgr36"> Bold-CyanFG </span></span>""" *
                        """<span class="sgr36"> CyanFG </span> Normal </pre>"""
    end

    @testset "fg/bg" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[96m", " LightCyanFG ")
        print(buf, "\e[45m", " LightCyanFG-MagentaBG ")
        print(buf, "\e[39m", " MagentaBG ")
        print(buf, "\e[49m", " Normal ")
        result = repr_html(printer)
        @test result == """<pre> Normal <span class="sgr96"> LightCyanFG """ *
                        """<span class="sgr45"> LightCyanFG-MagentaBG </span></span>""" *
                        """<span class="sgr45"> MagentaBG </span> Normal </pre>"""
    end
end

@testset "force reset" begin
    buf = IOBuffer()
    printer = HTMLPrinter(buf)

    print(buf, "\e[7m", " Invert ")
    print(buf, "\e[8m", " Conceal ")
    result = repr_html(printer)
    @test result == """<pre><span class="sgr7"> Invert <span class="sgr8"> Conceal """ *
                    """</span></span></pre>"""
end

@testset "256 colors" begin
    buf = IOBuffer()
    printer = HTMLPrinter(buf)

    print(buf, "\e[38;5;4m", " Blue(FG) ")
    print(buf, "\e[48;5;16m", " #000(BG) ")
    print(buf, "\e[38;5;110m", " #87afd7(FG) ")
    print(buf, "\e[48;5;255m", " #eee(BG) ")

    result = repr_html(printer)
    @test result == """<pre><span class="sgr34"> Blue(FG) """ *
                    """<span class="sgr48_5" style="background:#000"> #000(BG) """ *
                    """</span></span><span class="sgr48_5" style="background:#000">""" *
                    """<span class="sgr38_5" style="color:#87afd7"> #87afd7(FG) """ *
                    """</span></span><span class="sgr38_5" style="color:#87afd7">""" *
                    """<span class="sgr48_5" style="background:#eee"> #eee(BG) """ *
                    """</span></span></pre>"""
end

@testset "24-bit colors" begin
    buf = IOBuffer()
    printer = HTMLPrinter(buf)

    print(buf, "\e[38;2;0;128;255m", " #0080ff(FG) ")
    print(buf, "\e[48;2;238;238;238m", " #eee(BG) ")
    print(buf, "\e[38;2;170;187;204m", " #abc(FG) ")

    result = repr_html(printer)
    @test result == """<pre><span class="sgr38_2" style="color:#0080ff"> #0080ff(FG) """ *
                    """<span class="sgr48_5" style="background:#eee"> #eee(BG) """ *
                    """</span></span><span class="sgr48_5" style="background:#eee">""" *
                    """<span class="sgr38_2" style="color:#abc"> #abc(FG) """ *
                    """</span></span></pre>"""
end

@testset "callback" begin
    @testset "use default" begin
        counter = 0
        function cb(io, printer, tag, attrs)
            startswith(tag, "/") && return nothing
            push!(attrs, :id => tag * string(counter))
            counter += 1
            return nothing
        end

        buf = IOBuffer()
        printer = HTMLPrinter(buf, root_class = "root test", root_tag = "code", callback = cb)

        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[38;5;255m", " #eee(FG) ")
        print(buf, "\e[0m", " Normal ")

        result = repr_html(printer)
        @test result == """<code class="root test" id="code0"> Normal """ *
                        """<span class="sgr38_5" id="span1" style="color:#eee">""" *
                        """ #eee(FG) </span> Normal </code>"""
    end

    @testset "prevent default" begin
        dom = Tuple[(:rootnode, Tuple[])]
        function cb(io, printer, tag, attrs)
            text = String(take!(io))
            parent = dom[end]
            children = parent[end]
            isempty(text) || push!(children, (:textnode, text))

            if startswith(tag, "/")
                pop!(dom)
            else
                parent = (Symbol(tag), attrs, Tuple[])
                push!(children, parent)
                push!(dom, parent)
            end
            return true
        end

        buf = IOBuffer()
        printer = HTMLPrinter(buf, callback = cb)

        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[38;5;255m", " #eee(FG) ")
        print(buf, "\e[0m", " Normal ")

        result = repr_html(printer)
        @test result == ""
        @test dom[1] ==
                (:rootnode, Tuple[
                    (:pre, Dict{Symbol,String}(), Tuple[
                        (:textnode, " Normal "),
                        (:span, Dict(:class => "sgr38_5", :style => "color:#eee"), Tuple[
                            (:textnode, " #eee(FG) ")
                        ]),
                        (:textnode, " Normal ")
                    ])
                ])
    end
end
