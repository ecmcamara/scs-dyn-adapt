local oo = require "loop.base"
local Bye = oo.class{name = "World"}
function Bye:sayBye(str)
	print(self.name..": Bye ".."," .. str .. "!!4")
end
function Bye:Test(str)
	return self.name..str..4
end
return Bye