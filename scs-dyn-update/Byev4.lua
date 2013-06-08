local oo = require "loop.base"
local Bye = oo.class{name = "World"}
function Bye:sayBye(str)
	print(name..": Bye ".."," .. str .. "!!4")
end
return Bye