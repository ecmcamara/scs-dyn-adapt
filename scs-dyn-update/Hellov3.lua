local oo = require "loop.base"
local Hello = oo.class{name = "World"}
function Hello:sayHello(str)
	print("Hello "..self.name.."," .. str .. "!!3")
end
return Hello