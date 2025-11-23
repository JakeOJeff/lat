local coins = 250
local incrementVal = 20
local multiplier = 2
if love.keyboard.isDown("space") then 
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
print(coins)