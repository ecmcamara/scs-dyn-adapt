local oil = require "oil"
local orb = oil.init()

orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
orb:loadidlfile(os.getenv("IDL_PATH") .. "/dynupdate.idl")

oil.verbose:level(0)
oil.main(function()
	--Getting proxy to TV component
	local TVComponentIOR = oil.readfrom("tv.ior")
	local TVComponent = orb:newproxy(TVComponentIOR)
	
	local ExecutionWasOk = "Mission Acomplished!"

	if TVComponent then
		local IUpdateFacet = TVComponent:getFacetByName("IDynamicUpdatable")
		IUpdateFacet = orb:narrow(IUpdateFacet,"IDL:scs/demos/dynupdate/IDynamicUpdatable:1.0")

		if IUpdateFacet then	
		
		local updateKey,_ = pcall(IUpdateFacet.startUpdate)
		if not updateKey then
			updateKey =""
			--return 
		end
		
		local ret = IUpdateFacet:UpdateFacet(updateKey,
					{description={name="Control",
						interface_name="IDL:IControl:1.0",
						facet_idl=oil.readfrom("idl/IControl.idl"),
						facet_implementation=oil.readfrom("Controlv2.lua")},
					patchUpCode="",patchDownCode="",key="Control"})
			
			if ret ~= ExecutionWasOk then
				print("ERRO:FACET INSERT FAIL\n"..ret)
				IUpdateFacet:FinishUpdate()
				return
			end
			
			print("SUCCESS:FACET UPDATED")
			IUpdateFacet:FinishUpdate()
			
		end
	end
end)
