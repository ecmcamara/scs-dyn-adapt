local oo = require "loop.base"
local Hello = oo.class{name = "World"}
function Hello:sayHello(str)
	print(self.name..": Hello ".."," .. str .. "!!4")
end
return Hello