os.execute("start lua basic_update.lua")
local t0 = os.clock()
while os.clock() - t0 <= 0.5 do end
os.execute("start lua client_update.lua")