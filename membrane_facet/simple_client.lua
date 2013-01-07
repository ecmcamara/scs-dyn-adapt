local oil = require "oil"
local orb = oil.init()

orb:loadidlfile("../../../../../idl/scs.idl")
orb:loadidlfile("../../../../../idl/membrane.idl")
oil.verbose:level(0)
oil.main(function()

	local iComponentIOR = oil.readfrom("basic_component.ior")
	local iBasicComponent = orb:newproxy(iComponentIOR)

	iBasicComponent:startup()
	
	local facet = orb:narrow(iBasicComponent:getFacetByName('IHello'))

	facet:sayHello('Teste')


end)
