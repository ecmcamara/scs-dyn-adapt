local oo = require "loop.base"
local oil = require "oil"
local orb = oil.init({host="localhost",port=1069})
local IDynamicUpdatable = require "DynamicUpdatable"
local IBackdoor = require "Backdoor"
oil.orb = orb

local scs = require "scs.core.base"

oil.verbose:level(0)
orb:loadidlfile("../scs-idl/scs.idl")
orb:loadidlfile("dynupdate.idl")


--criação das descrições de facetas e receptáculos: Basic component
local facetDescs = {}
facetDescs.IDynamicUpdatable = {
	name = "IDynamicUpdatable",
	interface_name = "IDL:scs/demos/dynupdate/IDynamicUpdatable:1.0",
	class = IDynamicUpdatable
}
facetDescs.IBackdoor = {
	name = "IBackdoor",
	interface_name = "IDL:scs/demos/dynupdate/IBackdoor:1.0",
	class = IBackdoor
}
local receptDescs = {}

local cpId = {
	name = "DynUpdateTest",
	major_version = 1,
	minor_version = 0,
	patch_version = 0,
	platform_spec = ""
}

oil.main(function ()

	oil.newthread(orb.run,orb)
	basicComponent = scs.newComponent(facetDescs,receptDescs,cpId)	
	oil.writeto("basic_update.ior", orb:tostring(basicComponent.IComponent))

end)
