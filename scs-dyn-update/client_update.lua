local oil = require "oil"
local orb = oil.init()

orb:loadidlfile("../scs-idl/scs.idl")
orb:loadidlfile("../scs-idl/dynupdate.idl")
orb:loadidlfile("bye.idl")

oil.verbose:level(0)
oil.main(function()

	--Getting proxy to primitive component
	local primitiveComponentIOR = oil.readfrom("basic_update.ior")
	local primitiveComponent = orb:newproxy(primitiveComponentIOR)
	local DyncamicUpdatableIDL = "IDL:scs/demos/dynupdate/IDynamicUpdatable:1.0"
	local MetaInterfaceIDL = "IDL:scs/core/IMetaInterface:1.0"
	local BackDoorIDL = "IDL:scs/demos/dynupdate/IBackdoor:1.0"
	local ByeIDL = "IDL:scs/demos/byeworld/IBye:1.0"
	local FacetName = "IBye"
	local idlFile = "bye.idl"
	local v1File="Byev1.lua"
	local v2File="Byev2.lua"
	local v3File="Byev3.lua"
	local v4File="Byev4.lua"
	local key = "bye"
	local word = "foo"
	local HaltedState = "HALTED"
	local SuspendedState = "SUSPENDED"
	local ExecutionWasOk = "Mission Acomplished!"
	local finalMessage = ":GOOD BYE! All tests were fine :)"
	local patchCode1 ="_newFacet.name = _oldFacet.name"
	local patchCode2 ='_newFacet.name = "World3"'
	local patchCode3 ='_newFacet.name = "World5"'
	local patchCode4 ='_newFacet.name = "World6"'

	primitiveComponent:startup()

	if primitiveComponent then
		local IMetaInterface = primitiveComponent:getFacetByName("IMetaInterface")
		IMetaInterface = orb:narrow(IMetaInterface,MetaInterfaceIDL)
		
		--CONSOLEMODE
		--[[local IBackdoor = primitiveComponent:getFacetByName("IBackdoor")
		IBackdoor = orb:narrow(IBackdoor,BackDoorIDL)
		if IBackdoor then
		local cmd
			while true  do 
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
			end
		end]]
		local IUpdateFacet = primitiveComponent:getFacetByName("IDynamicUpdatable")
		IUpdateFacet = orb:narrow(IUpdateFacet,DyncamicUpdatableIDL)

		if IUpdateFacet then	
			--check states
			if IUpdateFacet:GetUpdateState()~= HaltedState then
				print("ERRO:UPDATE STATE INCORRECT")
				return
			end
			--change and check state
			IUpdateFacet:ChangeUpdateState(SuspendedState)
			if IUpdateFacet:GetUpdateState()~= SuspendedState then
				print("ERRO:UPDATE STATE INCORRECT")
				return
			end
			--change and check state
			IUpdateFacet:ChangeUpdateState(HaltedState)
			if IUpdateFacet:GetUpdateState()~= HaltedState then
				print("ERRO:UPDATE STATE INCORRECT")
				return
			end
			--checkfacets
			local facets = {}
			for k,v in ipairs(IMetaInterface:getFacets()) do 
				facets[v.name] = true
			end
			if facets[FacetName] then
				print("ERRO:FACET ALREADY EXISTS BEFORE INSERT")
				return
			end
			--insert Bye
			local ret =IUpdateFacet:InsertFacet({
					description={name=FacetName,
						interface_name=ByeIDL,
						facet_idl=oil.readfrom(idlFile),
						facet_implementation=oil.readfrom(v1File)},
					patchUpCode="",patchDownCode="",key=key})
			if ret ~= ExecutionWasOk then
				print("ERRO:FACET INSERT FAIL")
				return
			end
			--checkfacets
			facets = {}
			for k,v in ipairs(IMetaInterface:getFacets()) do 
				facets[v.name] = true
			end
			if not facets[FacetName] then
				print("ERRO:FACET WAS INSERTED BUT DOESN'T APPEAR ON FACET LIST")
				return
			end
			local IBye = primitiveComponent:getFacetByName(FacetName)
			IBye = orb:narrow(IBye,ByeIDL)
			if IBye then
			--checkcode
				if IBye:Test(word) ~= word then
					print("ERRO:TEST FUNCTION FAIL")
					return
				end
			--update Bye Async
				local key = IUpdateFacet:UpdateFacetAsync({
						description={name=FacetName,
							interface_name=ByeIDL,
							facet_idl="",
							facet_implementation=oil.readfrom(v2File)},
						patchUpCode="",patchDownCode="",key=""})

				if IUpdateFacet:GetAsyncRet(key) ~=ExecutionWasOk then
					print("ERRO:FACET Async UPDATE FAIL")
					return
				end
			--checkcode
				if IBye:Test(word) ~= word.."2" then
					print("ERRO:TEST FUNCTION FAIL")
					return
				end
			--update Bye Sync with patchUpCode
				ret = IUpdateFacet:UpdateFacet({
					description={name=FacetName,
						interface_name=ByeIDL,
						facet_idl="",
						facet_implementation=oil.readfrom(v3File)},
					patchUpCode=patchCode1,patchDownCode="",key=""})
				if ret ~= ExecutionWasOk then
					print("ERRO:FACET SYNC UPDATE WITH PATCH FAIL,"..ret)
					return
				end
			--checkcode
				if IBye:Test(word) ~= word.."3World2" then
					print("ERRO:TEST FUNCTION FAIL")
					return
				end
			--update Component with patchUpCode and patchDownCode
				local cpId = {
						name = "DynUpdateTest2",
						major_version = 1,
						minor_version = 0,
						patch_version = 0,
						platform_spec = ""}
				local ret =IUpdateFacet:UpdateComponent(cpId,{{
						description={name=FacetName,
							interface_name=ByeIDL,
							facet_idl="",
							facet_implementation=oil.readfrom(v4File)},
						patchUpCode=patchCode2,patchDownCode=patchCode3,key=""}})
				if ret ~=FacetName..":"..ExecutionWasOk.."\n" then
					print("ERRO:FACET Async UPDATE FAIL."..ret)
		 			return
				end
			--checkcode (patchUpCode)
				if IBye:Test(word) ~= "World3"..word.."4" then
					print("ERRO:TEST FUNCTION FAIL")
					return
				end
			--retrieve
				local retrievedFacet = IUpdateFacet:RetrieveFacet(FacetName)
				if not retrievedFacet then
					print("ERRO:RETRIEVE FAIL")
					return
				end
			--rollback with patchDownCode
				if not IUpdateFacet:RollbackFacet(FacetName) then
					print("ERRO:ROLLBACK FAIL")
					return
				end
			--checkcode (patchDownCode)
				if IBye:Test(word) ~= word.."3World5" then
					print("ERRO:TEST FUNCTION FAIL")
					return
				end
			--update to retrieved (patchUpCode & patchDownCode)
				retrievedFacet.patchUpCode = patchCode4
				ret = IUpdateFacet:UpdateFacet(retrievedFacet)
				if ret ~= ExecutionWasOk then
					print("ERRO:RETRIEVED FACET SYNC UPDATE WITH DOWN PATCH FAIL,"..ret)
					return
				end
			--checkcode (patchUpCode)
				if IBye:Test(word) ~= "World6"..word.."4" then
					print("ERRO:TEST FUNCTION FAIL")
					return
				end
			--rollback with patchDownCode
				if not IUpdateFacet:RollbackFacet(FacetName) then
					print("ERRO:ROLLBACK FAIL")
					return
				end
			--checkcode (patchDownCode)
				if IBye:Test(word) ~= word.."3World5" then
					print("ERRO:TEST FUNCTION FAIL")
					return
				end
			--rollback
				if not IUpdateFacet:RollbackFacet(FacetName) then
					print("ERRO:ROLLBACK FAIL")
					return
				end
			--checkcode
				if IBye:Test(word) ~= word.."2" then
					print("ERRO:TEST FUNCTION FAIL")
					return
				end
			--rollback
				if not IUpdateFacet:RollbackFacet(FacetName) then
					print("ERRO:ROLLBACK FAIL")
					return
				end
			--checkcode
				if IBye:Test(word) ~= word then
					print("ERRO:TEST FUNCTION FAIL")
					return
				end
			--try impossible rollback
				if IUpdateFacet:RollbackFacet(FacetName) then
					print("ERRO:IMPOSSIBLE ROLLBACK FAIL")
					return
				end
			--delete
				if IUpdateFacet:DeleteFacet(FacetName)~= ExecutionWasOk then
					print("ERRO:DELETE FAIL")
					return
				end
			--checkfacets
				facets = {}
				for k,v in ipairs(IMetaInterface:getFacets()) do 
					facets[v.name] = true
				end
				if facets[FacetName] then
					print("ERRO:FACET WAS DELETED BUT STILL APPEAR ON FACET LIST")
					return
				end
			--insert again just to say that the tests were ok :) then delete it again just for fun
				local ret =IUpdateFacet:InsertFacet({
					description={name=FacetName,
						interface_name=ByeIDL,
						facet_idl=oil.readfrom(idlFile),
						facet_implementation=oil.readfrom(v1File)},
					patchUpCode="",patchDownCode="",key=key})
				local IBye = primitiveComponent:getFacetByName(FacetName)
				IBye = orb:narrow(IBye,ByeIDL)
				IBye:sayBye(finalMessage)
				IUpdateFacet:DeleteFacet(FacetName)
			end
		end
	end
end)
