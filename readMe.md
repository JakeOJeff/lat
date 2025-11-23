# LatLang

A **Framework** which compiles to Lua Love. Made in Ruby.

Syntax is inspired frp, Lua, Ruby, Python and Java

## Setup

[You must have Ruby Installed]

Clone this repo

```bash
    git clone https://github.com/JakeOJeff/lat.git
```

Write the code in a .lat file and set the input location in [Compile](.\compiler\compile.rb)

```lua 
    inputFile = "path/to/file.lat"
```

Set an Output .lua file in [Compile](.\compiler\compile.rb)

```lua
    outputFile = "path/to/file.lua"
```

Compile the code in the terminal

```
    ruby .\compiler\compile.rb
``` 