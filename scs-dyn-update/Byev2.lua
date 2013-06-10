local oo = require "loop.base"
local Bye = oo.class{name = "World2"}
function Bye:sayBye(str)
	print("Bye " .. str .. "!!2")
end
function Bye:Test(str)
	return str..2
end
return Bye