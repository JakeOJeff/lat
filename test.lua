local coins = 250
local incrementVal = 20
local multiplier = 2
if love.keyboard.isDown("space") then
  incrementCoin(3)
elseif love.keyboard.isDown("w") then
  incrementCoin(3)
end

function incrementCoin(externalMultiplier)
  coins = (coins + ((incrementVal * multiplier) * externalMultiplier))
  return coins 
end
while true do 
  
end
if 10 == score then
 print("perfect")
elseif 5 == score then
 print("ok")
end

self.write = 5
self:write(wow)
print(coins)


local name = {}
name.__index = name

function name:new()
  local instance = setmetatable({}, self)
  hello = 5
  return instance
end

function name:hi(x,y)
  x = 5
  y = 5
end
