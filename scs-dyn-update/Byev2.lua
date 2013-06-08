local oo = require "loop.base"
local Bye = oo.class{name = "World"}
function Bye:sayBye(str)
	print("Bye " .. str .. "!!2")
end
return Bye