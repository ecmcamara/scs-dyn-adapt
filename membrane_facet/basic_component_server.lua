local oo = require "loop.base"
local oil = require "oil"
local orb = oil.init({host="localhost",port=1065})
oil.orb = orb

local scs = require "scs.core.base"

oil.verbose:level(0)


orb:loadidlfile("../idl/scs.idl")
orb:loadidlfile("hello.idl")

--implementação da faceta IHello
local Hello = oo.class{name = "World"}
function Hello:sayHello(str)
	print("Hello " .. str .. "!")
end

--criação das descrições de facetas e receptáculos: Basic component
local facetDescs = {}
facetDescs.IHello = {
	name = "IHello",
	interface_name = "IDL:scs/demos/helloworld/IHello:1.0",
	class = Hello
}

local receptDescs = {}

local cpId = {
	name = "Hello",
	major_version = 1,
	minor_version = 0,
	patch_version = 0,
	platform_spec = ""
}

oil.main(function ()

	oil.newthread(orb.run,orb)
	basicComponent = scs.newComponent(facetDescs,receptDescs,cpId)	
	oil.writeto("basic_component.ior", orb:tostring(basicComponent.IComponent))

end)
