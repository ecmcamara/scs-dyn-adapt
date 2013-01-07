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
	
	--Getting proxy to connector component
	local connectorComponentIOR = oil.readfrom("connector.ior")
	local connectorComponent = orb:newproxy(connectorComponentIOR)
	
	--Getting proxy to composite component
	local contentControllerIOR = oil.readfrom("content_controller.ior")
	local contentControllerComponent = orb:newproxy(contentControllerIOR)
	contentControllerComponent = orb:narrow(contentControllerComponent,"IDL:scs/core/IComponent:1.0")

	primitiveComponent:startup()
	connectorComponent:startup()

	if primitiveComponent then
	
		local compositeFacet  = contentControllerComponent:getFacetByName("IContentController")
		compositeFacet = orb:narrow(compositeFacet,"IDL:scs/core/IContentController:1.0")
		
		compositeFacet:addSubComponent(primitiveComponent)
		compositeFacet:addSubComponent(connectorComponent)
		
		local connectorReceptacle = connectorComponent:getFacet("IDL:scs/core/IReceptacles:1.0")
		connectorReceptacle = orb:narrow(connectorReceptacle,"IDL:scs/core/IReceptacles:1.0")
		
		local primitiveComponent =  primitiveComponent:getFacet("IDL:scs/demos/helloworld/IHello:1.0")
		primitiveComponent = orb:narrow( primitiveComponent, "IDL:scs/demos/helloworld/IHello:1.0")
		
		connectorReceptacle:connect("IHello",primitiveComponent)
		
		compositeFacet:bindFacet(1,'IHello','IExternalHello')
		
		local exposeFacet = contentControllerComponent:getFacetByName('IExternalHello')
		exposeFacet = orb:narrow(exposeFacet,"IDL:scs/demos/helloworld/IHello:1.0")
		
		if exposeFacet then
			exposeFacet:sayHello('Teste')
		end
		
	end

end)
