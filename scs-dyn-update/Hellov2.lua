local oo = require "loop.base"
local Hello = oo.class{name = "World"}
function Hello:sayHello(str)
	print("Hello " .. str .. "!!2")
end
return Hello