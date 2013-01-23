local oil = require "oil"
local orb = oil.init()

orb:loadidlfile("../scs-idl/scs.idl")
orb:loadidlfile("IDynamicUpdate.idl")
orb:loadidlfile("hello.idl")

oil.verbose:level(0)
oil.main(function()

	--Getting proxy to primitive component
	local primitiveComponentIOR = oil.readfrom("basic_update.ior")
	local primitiveComponent = orb:newproxy(primitiveComponentIOR)

	primitiveComponent:startup()

	if primitiveComponent then
	

		local IHelloFacet = primitiveComponent:getFacetByName("IHello")
		IHelloFacet = orb:narrow(IHelloFacet,"IDL:scs/demos/helloworld/IHello:1.0")
		if IHelloFacet then
			IHelloFacet:sayHello('Teste')
		end

		local IUpdateFacet = primitiveComponent:getFacetByName("IDynamicUpdatable")
		IUpdateFacet = orb:narrow(IUpdateFacet,"IDL:scs/demos/dynupdate/IDynamicUpdatable:1.0")
		
		print(IUpdateFacet:UpdateFacet("IHello",[[
		    local oo = require "loop.base"
			local Hello = oo.class{name = "World2"}
			function Hello:sayHello(str)
				print("Hello " .. str .. "!!")
			end
			return Hello
		]]))
		print(IHelloFacet:sayHello("fu"))
		
	end

end)
