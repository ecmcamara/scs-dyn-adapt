local oo = require "loop.base"
local oil = require "oil"
local orb = oil.init({host="localhost",port=1069})
local cc = require "scs.core.ComponentContext"
oil.orb = orb

local scs = require "scs.core.base"

oil.verbose:level(0)


orb:loadidlfile("../scs-idl/scs.idl")

orb:loadidlfile("IDynamicUpdate.idl")


orb:loadidlfile("hello.idl")

--implementação da faceta IHello
local Hello = oo.class{name = "World"}
function Hello:sayHello(str)
	print("Hello " .. str .. "!")
end
--fim

--implementação da faceta IDynamicUpdate
local IDynamicUpdatable = oo.class{}
function IDynamicUpdatable:Backdoor(str)
	local f,e = loadstring(str)
	if not f then
		return tostring(e)
	else
		local locals = { self = self}
		setfenv(f, setmetatable(locals, { __index = _G }))
		local status,ret = pcall(f)
		return tostring(ret)
	end
end
function IDynamicUpdatable:UpdateFacet(name,impl)
if not self.context._facets then
self.context._facets = self.context._facetDescs
end
	local f,e = loadstring(impl)
	if not f then
		return tostring(e)
	else
		local locals = { self = self}
		setfenv(f, setmetatable(locals, { __index = _G }))
		local status,ret = pcall(f)
		if status then
		local status2, ret2 = pcall(cc.updateFacet,self.context,name,ret)
		return tostring(ret2)
		else
		return tostring(ret)
		end
	end
end
--fim

--criação das descrições de facetas e receptáculos: Basic component
local facetDescs = {}
facetDescs.IDynamicUpdatable = {
	name = "IDynamicUpdatable",
	interface_name = "IDL:scs/demos/dynupdate/IDynamicUpdatable:1.0",
	class = IDynamicUpdatable
}
facetDescs.IHello = {
	name = "IHello",
	interface_name = "IDL:scs/demos/helloworld/IHello:1.0",
	class = Hello,
	key ="Hi"
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
