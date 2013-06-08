local oil = require "oil"
local orb = oil.init()

orb:loadidlfile("../scs-idl/scs.idl")
orb:loadidlfile("dynupdate.idl")
orb:loadidlfile("hello.idl")
orb:loadidlfile("bye.idl")

oil.verbose:level(0)
oil.main(function()

	--Getting proxy to primitive component
	local primitiveComponentIOR = oil.readfrom("basic_update.ior")
	local primitiveComponent = orb:newproxy(primitiveComponentIOR)
	local DyncamicUpdatableIDL = "IDL:scs/demos/dynupdate/IDynamicUpdatable:1.0"
	local BackDoorIDL = "IDL:scs/demos/dynupdate/IBackdoor:1.0"
	local HelloIDL = "IDL:scs/demos/helloworld/IHello:1.0"
	local ByeIDL = "IDL:scs/demos/byeworld/IBye:1.0"

	primitiveComponent:startup()

	if primitiveComponent then
	
		local IHelloFacet = primitiveComponent:getFacetByName("IHello")
		IHelloFacet = orb:narrow(IHelloFacet,HelloIDL)
		if IHelloFacet then
			IHelloFacet:sayHello('Teste')
		end
		local IBackdoor = primitiveComponent:getFacetByName("IBackdoor")
		IBackdoor = orb:narrow(IBackdoor,BackDoorIDL)
		if IBackdoor then
		print(IBackdoor:Backdoor("for k,v in pairs(self._facetDescs.IHello) do print(k,v) end"))
		--[[ CONSOLEMODE
		local cmd
			while true do 
				io.write(">")
				cmd = io.read()
				if cmd == "" then
					break;
				end
				if cmd:find("=") == 1 then
					cmd = "print("..cmd:sub(2)..")"
				end
				ret = IBackdoor:Backdoor(cmd)
				if ret then
					print(ret)
				end
			end--]]
		end
		local IUpdateFacet = primitiveComponent:getFacetByName("IDynamicUpdatable")
		IUpdateFacet = orb:narrow(IUpdateFacet,DyncamicUpdatableIDL)

		if IUpdateFacet then		

			print(IUpdateFacet:GetUpdateState())
			print(IUpdateFacet:ChangeUpdateState("SUSPENDED"))
			print(IUpdateFacet:GetUpdateState())
			print(IUpdateFacet:UpdateFacet({
				description={name="IHello",
					interface_name=HelloIDL,
					facet_implementation=[[
					local oo = require "loop.base"
					local Hello = oo.class{name = "World2"}
					function Hello:sayHello(str)
						print("Hello " .. str .. "!!")
					end
					return Hello		]]},
				patchUpCode="",patchDownCode="",key=""}))

			IHelloFacet:sayHello("fu")
			IHelloFacet:sayHello("fu2")
		
			local key = IUpdateFacet:UpdateFacetAsync({
				description={name="IHello",
					interface_name=HelloIDL,
					facet_implementation=[[
					local oo = require "loop.base"
					local Hello = oo.class{name = "World2"}
					function Hello:sayHello(str)
						print("Hello " .. str .. "!! "..self.context._componentId.name.."!!")
					end
					return Hello		]]},
				patchUpCode="",patchDownCode="",key=""})
			print(key)
			print(IUpdateFacet:GetAsyncRet(key))
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
					interface_name=HelloIDL,
					facet_implementation=[[
					local oo = require "loop.base"
					local Hello = oo.class{name = "World2"}
					function Hello:sayHello(str)
						print("Hello Wtf?" .. str .. "!! "..self.context._componentId.name.."!!")
					end
					return Hello		]]},
				patchUpCode="",patchDownCode="",key=""}})
			print(ret)
		end
	end

end)
