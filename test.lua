local coins = 250
local incrementVal = 20
local multiplier = 2
if love.keyboard.isDown("space") then incrementCoin(3) end
function incrementCoin(externalMultiplier) return coins = (coins + ((incrementVal * multiplier) * externalMultiplier)) end
print(coins)