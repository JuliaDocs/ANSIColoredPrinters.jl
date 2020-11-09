using Test, ANSIColoredPrinters

function repr_color(printer::PlainTextPrinter)
    result = repr("text/plain", printer, context = :color => true)
    get(ENV, "JULIA_DEBUG", "") == "" || println(result)
    take!(printer.buf)
    return result
end

@testset "no color" begin
    buf = IOBuffer()
    printer = PlainTextPrinter(buf)
    print(buf, "\e[36m", " CyanFG ")
    print(buf, "\e[39m", " Normal ")
    result = repr("text/plain", printer)
    @test result == " CyanFG  Normal "
end

@testset "single modification" begin
    buf = IOBuffer()
    printer = PlainTextPrinter(buf)

    @testset "bold/faint" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[1m", " Bold ")
        print(buf, "\e[2m", " Faint ")
        print(buf, "\e[22m", " Normal ")
        @test repr_color(printer) == " Normal \e[1m Bold \e[2m Faint \e[m Normal "
    end

    @testset "fg/bg" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[36m", " CyanFG ")
        print(buf, "\e[39;44m", " BlueBG ")
        print(buf, "\e[49m", " Normal ")
        @test repr_color(printer) == " Normal \e[36m CyanFG \e[39;44m BlueBG \e[m Normal "
    end

    @testset "blink" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[5m", " Blink ")
        print(buf, "\e[6m", " RapidBlink ")
        print(buf, "\e[25m", " Normal ")
        @test repr_color(printer) == " Normal \e[5m Blink \e[6m RapidBlink \e[m Normal "
    end
end

@testset "nested modification" begin
    buf = IOBuffer()
    printer = PlainTextPrinter(buf)

    @testset "bold/italic" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[1m", " Bold ")
        print(buf, "\e[3m", " Bold-Italic ")
        print(buf, "\e[23m", " Bold ")
        print(buf, "\e[0m", " Normal ")
        result = repr_color(printer)
        @test result == " Normal \e[1m Bold \e[3m Bold-Italic \e[23m Bold \e[m Normal "

        print(buf, "\e[3m", " Italic ")
        print(buf, "\e[1m", " Bold-Italic ")
        print(buf, "\e[22m", " Italic ")
        print(buf, "\e[0m", " Normal ")
        result = repr_color(printer)
        @test result == "\e[3m Italic \e[1m Bold-Italic \e[22m Italic \e[m Normal "
    end

    @testset "bold/fg" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[1m", " Bold ")
        print(buf, "\e[36m", " Bold-CyanFG ")
        print(buf, "\e[39m", " Bold ")
        print(buf, "\e[0m", " Normal ")
        result = repr_color(printer)
        @test result == " Normal \e[1m Bold \e[36m Bold-CyanFG \e[39m Bold \e[m Normal "
    end

    @testset "strike/blink" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[9m", " Strike ")
        print(buf, "\e[5m", " Strike-Blink ")
        print(buf, "\e[25m", " Strike ")
        print(buf, "\e[29m", " Normal ")
        result = repr_color(printer)
        @test result == " Normal \e[9m Strike \e[5m Strike-Blink \e[25m Strike \e[m Normal "
    end

    @testset "fg/bg" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[96m", " LightCyanFG ")
        print(buf, "\e[45m", " LightCyanFG-MagentaBG ")
        print(buf, "\e[49m", " LightCyanFG ")
        print(buf, "\e[39m", " Normal ")
        result = repr_color(printer)
        @test result == " Normal \e[96m LightCyanFG \e[45m LightCyanFG-MagentaBG " *
                        "\e[49m LightCyanFG \e[m Normal "
    end
end

@testset "overlapped modification" begin
    buf = IOBuffer()
    printer = PlainTextPrinter(buf)

    @testset "bold/fg" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[1m", " Bold ")
        print(buf, "\e[36m", " Bold-CyanFG ")
        print(buf, "\e[22;36m", " CyanFG ")
        print(buf, "\e[39m", " Normal ")
        result = repr_color(printer)
        @test result == " Normal \e[1m Bold \e[36m Bold-CyanFG " *
                        "\e[22;36m CyanFG \e[m Normal "
    end

    @testset "fg/bg" begin
        print(buf, "\e[0m", " Normal ")
        print(buf, "\e[96m", " LightCyanFG ")
        print(buf, "\e[45m", " LightCyanFG-MagentaBG ")
        print(buf, "\e[39m", " MagentaBG ")
        print(buf, "\e[49m", " Normal ")
        result = repr_color(printer)
        @test result == " Normal \e[96m LightCyanFG \e[45m LightCyanFG-MagentaBG " *
                        "\e[39m MagentaBG \e[m Normal "
    end
end

@testset "force reset" begin
    buf = IOBuffer()
    printer = PlainTextPrinter(buf)

    print(buf, "\e[7m", " Invert ")
    print(buf, "\e[8m", " Conceal ")
    @test repr_color(printer) == "\e[7m Invert \e[8m Conceal \e[m"
end

@testset "256 colors" begin
    buf = IOBuffer()
    printer = PlainTextPrinter(buf)

    print(buf, "\e[38;5;4m", " Blue(FG) ")
    print(buf, "\e[48;5;16m", " #000(BG) ")
    print(buf, "\e[38;5;110m", " #87afd7(FG) ")
    print(buf, "\e[48;5;255m", " #eee(BG) ")

    result = repr_color(printer)
    @test result == "\e[34m Blue(FG) \e[48;5;16m #000(BG) " *
                    "\e[38;5;110m #87afd7(FG) \e[48;5;255m #eee(BG) \e[m"
end

@testset "24-bit colors" begin
    buf = IOBuffer()
    printer = PlainTextPrinter(buf)

    print(buf, "\e[38;2;0;128;255m", " #0080ff(FG) ")
    print(buf, "\e[48;2;238;238;238m", " #eee(BG) ")
    print(buf, "\e[38;2;170;187;204m", " #abc(FG) ")

    result = repr_color(printer)
    @test result == "\e[38;2;0;128;255m #0080ff(FG) \e[48;5;255m #eee(BG) " *
                    "\e[38;2;170;187;204m #abc(FG) \e[m"
end