local oil = require "oil"
local orb = oil.init()

orb:loadidlfile("../idl/scs.idl")
orb:loadidlfile("../idl/composite.idl")
orb:loadidlfile("hello.idl")
oil.verbose:level(0)
oil.main(function()

	--Getting proxy to primitive component
	local primitiveComponentIOR = oil.readfrom("basic_component.ior")
	local primitiveComponent = orb:newproxy(primitiveComponentIOR)

	--Getting proxy to composite component
	local contentControllerIOR = oil.readfrom("content_controller.ior")
	local contentControllerComponent = orb:newproxy(contentControllerIOR)
	contentControllerComponent = orb:narrow(contentControllerComponent,"IDL:scs/core/IComponent:1.0")

	primitiveComponent:startup()
	contentControllerComponent:startup()

	if primitiveComponent then
	
		scOfPrimitive = primitiveComponent:getFacetByName("ISuperComponent")
		scOfPrimitive = orb:narrow(scOfPrimitive,"IDL:scs/core/ISuperComponent:1.0")
		
		print(scOfPrimitive:getSuperComponents())
		local compositeFacet  = contentControllerComponent:getFacetByName("IContentController")
		compositeFacet = orb:narrow(compositeFacet,"IDL:scs/core/IContentController:1.0")
	
		print('Composite component id: '..compositeFacet:getId())
		print(compositeFacet:addSubComponent(primitiveComponent))
		print(compositeFacet:findComponent(0))
		
		--[[
			compositeFacet:unbindFacet(0)
			print(compositeFacet:removeSubComponent(0))
		]]
		print(compositeFacet:bindFacet(0,'IHello','IExternalHello'))
		
		local exposeFacet = contentControllerComponent:getFacetByName('IExternalHello')
		exposeFacet = orb:narrow(exposeFacet,"IDL:scs/demos/helloworld/IHello:1.0")
		
		if exposeFacet then
			exposeFacet:sayHello('Teste')
		end
		
	end

end)
