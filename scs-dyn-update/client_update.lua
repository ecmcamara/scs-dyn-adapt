local oil = require "oil"
local orb = oil.init()

orb:loadidlfile("../scs-idl/scs.idl")
orb:loadidlfile("dynupdate.idl")
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
		local IBackdoor = primitiveComponent:getFacetByName("IBackdoor")
		IBackdoor = orb:narrow(IBackdoor,"IDL:scs/demos/dynupdate/IBackdoor:1.0")
		if IBackdoor then
		--IBackdoor:Backdoor("for k,v in pairs(self.context) do print(k,v) end")
			IBackdoor:Backdoor("print('Wtf!')")
		end

		local IUpdateFacet = primitiveComponent:getFacetByName("IDynamicUpdatable")
		IUpdateFacet = orb:narrow(IUpdateFacet,"IDL:scs/demos/dynupdate/IDynamicUpdatable:1.0")

		if IUpdateFacet then		

			print(IUpdateFacet:UpdateFacet({
				description={name="IHello",
					interface_name="IDL:scs/demos/helloworld/IHello:1.0",
					facet_implementation=[[
					local oo = require "loop.base"
					local Hello = oo.class{name = "World2"}
					function Hello:sayHello(str)
						print("Hello " .. str .. "!!")
					end
					return Hello		]]},
				patchCode=""}))

			IHelloFacet:sayHello("fu")
			IHelloFacet:sayHello("fu2")
		
			local key = IUpdateFacet:UpdateFacetAsync({
				description={name="IHello",
					interface_name="IDL:scs/demos/helloworld/IHello:1.0",
					facet_implementation=[[
					local oo = require "loop.base"
					local Hello = oo.class{name = "World2"}
					function Hello:sayHello(str)
						print("Hello " .. str .. "!! "..self.context._componentId.name.."!!")
					end
					return Hello		]]},
				patchCode=""})
			print(key)
			print(IUpdateFacet:GetUpdateFacetAsyncRet(key))
			IHelloFacet:sayHello("fu")
			IHelloFacet:sayHello("fu2")
			local cpId = {
				name = "DynUpdateTest2",
				major_version = 1,
				minor_version = 0,
				patch_version = 0,
				platform_spec = ""
			}

			local ret =IUpdateFacet:UpdateComponent(cpId,{{
				description={name="IHello",
					interface_name="IDL:scs/demos/helloworld/IHello:1.0",
					facet_implementation=[[
					local oo = require "loop.base"
					local Hello = oo.class{name = "World2"}
					function Hello:sayHello(str)
						print("Hello Wtf?" .. str .. "!! "..self.context._componentId.name.."!!")
					end
					return Hello		]]},
				patchCode=""}})
			print(ret)
		end
	end

end)
