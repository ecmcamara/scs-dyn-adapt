oil = require "oil"
require "socket"
local orb = oil.init()
function round2(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

oil.main(function()
  orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
  orb:loadidlfile("idl/hello.idl")

  -- loading Remote reference
  local f = assert(io.open("hello.ior", "r"), "Error opening remote IComponente's IOR file!")
  local ior = f:read("*all")
  f:close()
  
  --get IComponent reference
  local Hello = orb:newproxy(ior, "synchronous", "IDL:scs/demos/helloworld/Hello:1.0")
  
  --get facet reference
  Hello = orb:narrow(Hello)
  for j=1,11 do
  local sum = 0
  local maxi = 0
  local mini = 1
  for i=1,10000 do
  local t1 =socket.gettime()
  Hello:sayHello()
  local t2 =socket.gettime()
  t1 = round2(t1*10000)
  t2 = round2(t2*10000)
  local dif = round2(t2-t1)/10
  if dif < mini then
   mini = dif
  end
  if dif > maxi then
   maxi = dif
  end
  --print(dif)
  sum = sum +dif
  --print("Milliseconds: " .. dif)
  end
  print("min:"..mini)
  print("max:"..maxi)
  print("total:"..sum)
  end

end)
