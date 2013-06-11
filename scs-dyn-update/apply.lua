local reverseArgs = {}
for k,v in ipairs(arg) do 
	reverseArgs[string.lower(v.."")] = string.lower(k.."")
end
local instructions = "Usage:\n"..
	 "\n    -ior [FileName]:\n"..
	 "        File that contains the IOR for the IComponent facet of the component to\n"..
	 "        be updated. Required\n"..
	 "\n    -facet [FileName]:\n"..
	 "        File that contains the description of the facet to be Inserted/Updated.\n"..
	 "        Required for Update and Insert\n"..
	 "\n    -action ['Insert'|'Update'|'Delete'|'RollBack']:\n"..
	 "        Action to be executed, default is Update if no value is passed. \n"..
	 "        If Deleted or Rollback the -facetName parameter is Required instead of\n"..
	 "        -facet\n"..
	 "\n    -facetName [Name]:\n"..
	 "        Name of the facet to be Removed/RolledBack. \n"..
	 "        Required for Update and Insert\n"..
	 "\n    -IDynamicUpdate:\n"..
	 "        Specify that you are passing the IOR of the IDynamicUpdate facet\n"..
	 "        NOT TESTED\n\n"..
	 "i.e.: "..arg[-1].." "..arg[0].."  -ior comp.ior -facet patch.lua\n"
			
if #arg < 4 then		
	print(instructions)
	return
end
local iorI = reverseArgs["-ior"]
local iorArg
if iorI then
	iorArg= arg[iorI+1]
end

local facetI = reverseArgs["-facet"]
local facetArg = nil
if facetI then
	facetArg =arg[facetI+1]
end

local actionI = reverseArgs["-action"]
local actionArg
if actionI then
	actionArg =arg[actionI+1]
end

local facetNameI = reverseArgs["-facetname"]
local facetNameArg
if facetNameI then
	facetNameArg =arg[facetNameI+1]
end

local IDynamicUpdateI = reverseArgs["-idynamicupdate"]
local IDynamicUpdateArg 
if IDynamicUpdateI then
	IDynamicUpdateArg =arg[IDynamicUpdateI+1]
end
if not actionArg then
	actionArg = "update"
end
--check requirements
if not iorArg or 
	(actionArg == "update" and not facetArg) or
	(actionArg == "insert" and not facetArg) or
	(actionArg == "delete" and not facetNameArg) or
	(actionArg == "rollback" and not facetNameArg) then
	print(instructions)
	return
end
--load resources

local oil = require "oil"
local primitiveComponentIOR = oil.readfrom(iorArg)
local facet = loadfile(facetArg)
if not facet then
	print("Facet file malformed. Try i.e:\n\n"..
			"return {description=\n"..
			'         {name="IHello",\n'..
			'           interface_name="IDL:scs/demos/helloworld/IHello:1.0",\n'..
			'           facet_idl=[[module scs{\n'..
            '                         module demos{\n'..
            '                           module helloworld{\n'..
            '                             interface IHello{\n'..
            '                               void sayHello(in string str);\n'..
            '                             };\n'..
            '                           };\n'..
            '                         };\n'..
            '                       };]],\n'..
			'         facet_implementation=[[[local oo=require "loop.base"\n'..
			'                                 local Hello=oo.class{name="World"}\n'..
			'                                 function Hello:sayHello(str)\n'..
			'                                   print("Hello " .. str .. "!!")\n'..
			'                                 end\n'..
			'                                 return Hello]]},\n'..
			'         patchUpCode="",patchDownCode="",key="Hello"}\n')
			return
end
facet = facet()
--for k,v in pairs(facet) do if type(v) == "table" then print(k); for i,j in pairs(v) do print(i,j) end else print(k,v) end end
local orb = oil.init()
orb:loadidlfile("../scs-idl/scs.idl")
orb:loadidlfile("../scs-idl/dynupdate.idl")

oil.verbose:level(0)
oil.main(function()
			local ExecutionWasOk = "Mission Acomplished!"
			local IDynamicUpdate
			if not IDynamicUpdateArg then -- IComponent
				local primitiveComponent = orb:newproxy(primitiveComponentIOR)
				IDynamicUpdate = primitiveComponent:getFacetByName("IDynamicUpdatable")
				IDynamicUpdate = orb:narrow(IDynamicUpdate,"IDL:scs/demos/dynupdate/IDynamicUpdatable:1.0")
			else
				IDynamicUpdate = orb:newproxy(primitiveComponentIOR)
			end
			if not IDynamicUpdate then
				print("NO IDynamicUpdate Facet :(")
				return
			end
			if actionArg == "rollback" then
				if not IDynamicUpdate:RollbackFacet(facetNameArg) then
					print("ERRO:ROLLBACK FAIL!")
					return
				else
					print("ROLLBACK SUCCEEDED!")
					return
				end
			elseif actionArg == "delete" then
				local delRet = IDynamicUpdate:DeleteFacet(facetNameArg)
				if delRet ~=  ExecutionWasOk then
					print("ERRO:DELETE FAIL!:"..delRet)
					return
				else
					print("DELETE SUCCEEDED!")
					return
				end
			elseif actionArg == "insert" then
				local inRet = IDynamicUpdate:InsertFacet(facet)
				if inRet ~=  ExecutionWasOk then
					print("ERRO:INSERT FAIL!:"..inRet)
					return
				else
					print("INSERT SUCCEEDED!")
					return
				end
			elseif actionArg == "update" then
				local upRet = IDynamicUpdate:UpdateFacet(facet)
				if upRet ~=  ExecutionWasOk then
					print("ERRO:UPDATE FAIL!:"..upRet)
					return
				else
					print("UPDATE SUCCEEDED!")
					return
				end
			end
		end)