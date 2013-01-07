local oo = require "loop.base"
local oil = require "oil"
local orb = oil.init({host="localhost",port=1040})
oil.orb = orb

local scs = require "scs.core.composite"

orb:loadidlfile("../idl/composite.idl")

-- criação do ComponentId
local cpId = {
	name = "Composite Component",
	major_version = 1,
	minor_version = 0,
	patch_version = 0,
	platform_spec = ""
}


oil.verbose:level(0)
oil.main(function ()

	oil.newthread(orb.run,orb)
	instance = scs.newCompositeComponent({},{},cpId)
	oil.writeto("content_controller.ior",orb:tostring(instance.IComponent))

end)
