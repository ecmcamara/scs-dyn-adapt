local oo = require "loop.base"
local oil = require "oil"
local orb = oil.init({host="localhost",port=1020})
oil.orb = orb

local scs = require "scs.core.base"

orb:loadidlfile("../idl/scs.idl")
orb:loadidlfile("hello.idl")

local Hello = oo.class{name = "World"}

function Hello:sayHello(str)

	local subcomponents = self.context["IHello"]
	
	for i,v in pairs(subcomponents)
	do
		v = orb:narrow(v.objref,"IDL:scs/demos/helloworld/IHello:1.0")
		v:sayHello(str)
	end
end

local facetDescs = {}
facetDescs.IHello = {
	name = "IHello",
	interface_name = "IDL:scs/demos/helloworld/IHello:1.0",
	class = Hello
}

local receptDescs = {}
receptDescs.IHello = {
	name = "IHello",
	interface_name = "IDL:scs/demos/helloworld/IHello:1.0",
	is_multiplex = true,
	type = 'ListReceptacle'
}

-- criação do ComponentId
local cpId = {
	name = "IHello_connector",
	major_version = 1,
	minor_version = 0,
	patch_version = 0,
	platform_spec = ""
}

oil.verbose:level(0)
oil.main(function ()

	oil.newthread(orb.run,orb)
	
	connector = scs.newComponent(facetDescs,receptDescs,cpId)
	oil.writeto("connector.ior",orb:tostring(connector.IComponent))

end)
