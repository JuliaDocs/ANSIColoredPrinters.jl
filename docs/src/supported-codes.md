# Supported Codes
```@setup ex
using AnsiColoredPrinters
```
## Bold and Faint
```@example ex
buf = IOBuffer()
print(buf, "\e[0m", "Normal ")
print(buf, "\e[1m", "Bold ")
print(buf, "\e[2m", "Faint ") # this unsets the "bold"
print(buf, "\e[0m", "Normal ")
HTMLPrinter(buf, root_class="documenter-example-output")
```

## Italic
```@example ex
buf = IOBuffer()
print(buf, "\e[0m", "Normal ")
print(buf, "\e[3m", "Italic ")
print(buf, "\e[1m", "Bold-Italic ") # this keeps the "italic"
print(buf, "\e[0m", "Normal ")
HTMLPrinter(buf, root_class="documenter-example-output")
```

## Underline and Strikethrough
```@example ex
buf = IOBuffer()
print(buf, "\e[0m", "Normal ")
print(buf, "\e[4m", " Underline ", "\e[m", " ")
print(buf, "\e[9m", " Striethrough ", "\e[m", " ")
print(buf, "\e[4;9m", " Both ", "\e[m")
HTMLPrinter(buf, root_class="documenter-example-output")
```
## Invert
The invert code swaps the foreground and background colors. However, the support
is limited. You will need to force the foreground and background colors to be
switched manually, or convert the style afterwards using JavaScript etc.

```@example ex
buf = IOBuffer()
print(buf, "\e[0m", "Normal ")
print(buf, "\e[7m", "Invert ")
print(buf, "\e[0m", "Normal ")
print(buf, "\e[7;100m", "GrayText? ") # not supported by default.css
print(buf, "\e[34m", "BlueBG? ") # not supported by default.css
print(buf, "\e[0m", "Normal ")
HTMLPrinter(buf, root_class="documenter-example-output")
```

## Conceal
```@example ex
buf = IOBuffer()
print(buf, "\e[0m", "Normal ")
print(buf, "\e[8m", "Conceal ")
print(buf, "\e[31;47m", "red ") # this is still concealed
print(buf, "\e[0m", "Normal ")
print(buf, "\e[31;47m", "red ")
print(buf, "\e[8m", "Conceal ")
print(buf, "\e[0m", "Normal ")
HTMLPrinter(buf, root_class="documenter-example-output")
```

## 16 colors
The 16 colors correspond to the color symbols which can be specified in the
argument of
[`printstyled`](https://docs.julialang.org/en/v1/base/io-network/#Base.printstyled)
(e.g. `:black`, `:red`, `:green`, `:light_blue`). Their sRGB values are
environment-dependent. This document defines their actual colors in a CSS file.

### Basic colors
```@example ex
buf = IOBuffer()
for fg in [30:37; 39] # foreground color
    for bg in [40:47; 49] # background color
        print(buf, "\e[$fg;$(bg)m  $fg; $bg ")
    end
    println(buf)
end
HTMLPrinter(buf, root_class="documenter-example-output")
```

### Light colors
```@example ex
buf = IOBuffer()
for fg in [90:97; 39] # foreground color
    for bg in [100:107; 49] # background color
        print(buf, "\e[$fg;$(bg)m  $fg;$bg ")
    end
    println(buf)
end
HTMLPrinter(buf, root_class="documenter-example-output")
```

## 256 colors
The 256 colors correspond to the integer codes which can be specified in the
argument of printstyled.

```@example ex
buf = IOBuffer()
for color in 0:15 # same as the 16 colors above.
    print(buf, "\e[38;5;$color;48;5;$(color)m  ")
    print(buf, "\e[49m", lpad(color, 3), " ")
    color % 8 == 7 && println(buf)
end
for color in 16:231 # 6 × 6 × 6 = 216 colors
    (color - 16) % 12 == 0 && println(buf)
    print(buf, "\e[38;5;$color;48;5;$(color)m  ")
    print(buf, "\e[49m", lpad(color, 3), " ")
end
println(buf)
for color in 232:255 # grayscale in 24 steps
    (color - 232) % 12 == 0 && println(buf)
    print(buf, "\e[38;5;$color;48;5;$(color)m  ")
    print(buf, "\e[49m", lpad(color, 3), " ")
end
print(buf, "\e[m")
HTMLPrinter(buf, root_class="documenter-example-output")
```
## 24-bit colors

```@example ex
buf = IOBuffer()
print(buf, " \e[48;2;56;152;38m  \n")
print(buf, "\e[48;2;203;60;51m  ")
print(buf, "\e[48;2;149;88;178m  ")
print(buf, "\e[49;38;2;64;99;216m  24-bit RGB\e[m")
HTMLPrinter(buf, root_class="documenter-example-output")
```
