local x = (200 + 25)
local y = (225 + x)
function add(a,b) return (a + b) end
z = add(x,y)
love.graphics.draw(player,x,y)