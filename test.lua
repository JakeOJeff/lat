local x = (200 + 25)
local y = (225 + x)
function add(a,b) return (a + b) end
z = add(x,y)
love.graphics.#<struct Token type=:identifier, value="draw">(#<struct VarRefNode value="player">,#<struct VarRefNode value="x">,#<struct VarRefNode value="y">)