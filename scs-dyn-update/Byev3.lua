local oo = require "loop.base"
local Bye = oo.class{name = "World"}
function Bye:sayBye(str)
	print("Bye "..self.name.."," .. str .. "!!3")
end
function Bye:Test(str)
	return str.."3"..self.name
end
return Bye