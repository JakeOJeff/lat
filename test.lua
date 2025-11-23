local coins = 250
local incrementVal = 20
local multiplier = 2
if love.keyboard.isDown("space") then incrementCoin(3) end
if (a == 2 or a == 3 or a == 5) then  end
function incrementCoin(externalMultiplier)
  coins = (coins + ((incrementVal * multiplier) * externalMultiplier))
  return coins 
end
print(coins)