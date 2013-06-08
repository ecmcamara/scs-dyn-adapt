local oo = require "loop.base"
local Hello = oo.class{name = "World"}
function Hello:sayHello(str)
	print("Hello " .. str .. "!!")
end
return Hello