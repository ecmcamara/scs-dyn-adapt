local error         = error
local module        = module
local require       = require
local assert        = assert
local print         = print
local pairs         = pairs
local table         = table
local setmetatable 	= setmetatable
local ipairs		= ipairs
local os 			= os
local tostring 		= tostring

local scs       = require "scs.core.base"
local oo        = require "loop.base"

-- If we stored a broker instance previously, use it. If not, use the default broker
local oil = oil
local orb = oil.orb or oil.init()

--------------------------------------------------------------------------------

module "scs.core.composite"

--------------------------------------------------------------------------------

local _scs_version = "1.0"
local _scs_core_package  = "scs/core/"

-- Implementation of the IReceptacles Interface from scs.idl
--
Receptacles = oo.class{}

function Receptacles:__init()
  return oo.rawnew(self, {_nextConnId = 0, _maxConnections = 100, _numConnections = 0})
end

--
-- Description: Connects an object to the specified receptacle.
-- Parameter receptacle: The receptacle's name that corresponds to the interface implemented by the
--             provided object.
-- Parameter object: The CORBA object that implements the expected interface.
-- Return Value: The connection's identifier.
--
function Receptacles:connect(receptacle, object)

	local context = self.context
	local desc = context._receptacleDescs[receptacle]
 
	if not desc then 
		error{ "IDL:scs/core/InvalidName:1.0", name = receptacle }
	end
  
	if not object then 
		error{ "IDL:scs/core/InvalidConnection:1.0" }
	end
  
	local status, err = oil.pcall(object._is_a, object, desc.interface_name)
	if not (status and err) then
		error{ "IDL:scs/core/InvalidConnection:1.0" }
	end
	
	object = context._orb:narrow(object, desc.interface_name)

	if (self._numConnections > self._maxConnections) then
		error{ "IDL:scs/core/ExceededConnectionLimit:1.0" }
	end

	if not desc.is_multiplex and #(desc.connections) > 0 then
		error{ "IDL:scs/core/AlreadyConnected:1.0" }
	end
	
	local internalSubcomponents = context._receptacleBindingHash[receptacle]
	
	print('Sending connections...')

	for i,v in pairs(internalSubcomponents)
	do
		
		local cmp = context._orb:narrow(v.subcomponent,"IDL:scs/core/IComponent:1.0")
		local receptacles = context._orb:narrow(cmp:getFacetByName("IReceptacles"))
		
		
		local objToSend = context._orb:newservant(object)
		objToSend._component = function() return nil end
		
		print('Sending connection...')
		local connId = receptacles:connect(v.name,objToSend)
		print('Connection sent')
		local internal = {}
		internal["subcomponent"] = cmp
		internal["connectionId"] = connId
		
		table.insert(desc._internalConnections,internal)
		
	end
	
	self._nextConnId = self._nextConnId + 1
	desc.connections[self._nextConnId] = {id = self._nextConnId, objref = object}
	context._receptsByConId[self._nextConnId] = desc
	self._numConnections = self._numConnections + 1

	if not desc.is_multiplex then
	   context[receptacle] = object
	end

  return self._nextConnId
  
end

--
-- Description: Disconnects an object from a receptacle.
-- Parameter connId: The connection's identifier.
--
function Receptacles:disconnect(connId)
  local context = self.context
  local desc = context._receptsByConId[connId]

  if not context._receptacleDescs[desc.name] then
    error{ "IDL:scs/core/NoConnection:1.0" }
  end

  if not desc then
    error{ "IDL:scs/core/InvalidConnection:1.0" }
  end
  
  --if desc.isExposedReceptacle then
  
	--disconnect all internal receptacles
	
	--for _,v in ipairs(desc.subcomponents)
	--do
		
	--	receptacle = v['component']:getFacetByName("IReceptacles")
	--	receptacle = orb:narrow(receptacle,"IDL:".._scs_core_package.."IReceptacles:".._scs_version)
	--	receptacle:disconnect(desc._bindingSet[v['id']])

	--end
	
	--end

	--if not desc.is_multiplex then
	--context[desc.name] = nil
	--end
	--desc.connections[connId] = nil
	--self._numConnections = self._numConnections - 1
end

--
-- Description: Provides information about all the current connections of a receptacle.
-- Parameter receptacle: The receptacle's name.
-- Return Value: All current connections of the specified receptacle.
--
function Receptacles:getConnections(receptacle)
  self = self.context
  if self._receptacleDescs[receptacle] then
    return utils:convertToArray(self._receptacleDescs[receptacle].connections)
  end
  error{ "IDL:scs/core/InvalidName:1.0", name = receptacle }
end

local function fillCompositeComponentDescriptions(facetDescs)
  
  local hasCC = false
  
  if not facetDescs then
	facetDescs = {}
  end
 
  for name, desc in pairs(facetDescs) do
    if desc.interface_name == "IDL:".._scs_core_package.."IContentController:".._scs_version then
      hasCC = true
	elseif desc.interface_name == "IDL:".._scs_core_package.."IContentReceptacles:".._scs_version then
      hasIR = true
    end
  end
  
  -- did not include IContentController
  if not hasCC then
    -- checks if the name IContentController can be used
    if facetDescs.IContentController then
      return false
    end
    facetDescs.IContentController = {}
    facetDescs.IContentController.name                      = "IContentController"
    facetDescs.IContentController.interface_name            = "IDL:".._scs_core_package.."IContentController:".._scs_version
    facetDescs.IContentController.class                     = ContentController
  end
  
  -- did not include IReceptacles
  if not hasIR then
    -- checks if the name IReceptacles can be used
    if facetDescs.IReceptacles then
      return false
    end
    facetDescs.IReceptacles = {}
    facetDescs.IReceptacles.name                    = "IReceptacles"
    facetDescs.IReceptacles.interface_name          = "IDL:".._scs_core_package.."IReceptacles:".._scs_version
    facetDescs.IReceptacles.class                   = Receptacles
  end
  
  return true
end

function newCompositeComponent(facetDescs, receptDescs, componentId)
  
  if not fillCompositeComponentDescriptions(facetDescs) then
    return nil
  end
  
  instance = scs.newComponent(facetDescs,recptDescs,componentId)
  
  if not instance then
	return nil
  end
  
  instance._id = os.time();
  instance._membershipId = 0;
  instance._facetBindingId = 0;
  instance._receptacleBindingId = 0;
  instance._componentSet = {}
  instance._facetBindingHash = {}
  instance._receptacleBindingHash = {}
  instance._receptacleBinding = {}

  return instance
  
end

--
-- ContentController
-- Implementation of the IContentController Interface from scs.idl
--
ContentController = oo.class{}

function ContentController:__init()
  return oo.rawnew(self, {})
end

function ContentController:getId()

	context = self.context
	
	return tostring(context._id)
end

function ContentController:addSubComponent(component)

	context = self.context

	local membershipId = context._membershipId
	context._membershipId = membershipId + 1	
	
	scFacet = component:getFacetByName("ISuperComponent") 
	scFacet = context._orb:narrow(scFacet,"IDL:scs/core/ISuperComponent:1.0")
	
	--context.IComponent:getFacetByName("IMetaInterface") 
	scFacet:addSuperComponent(context.IComponent)
		
	context._componentSet[membershipId] = component
	
	return membershipId
	
end

function ContentController:removeSubComponent(membershipId)

	context = self.context
	
	local subcomponent = self:findComponent(membership)
	
	if not subcomponent then
		--TODO: throws ComponentNotFoundException
	end
	
	--TODO: Remove composite component of subcomponent

	context._componentSet[membershipId] = nil
	
end

function ContentController:getSubComponents()
	
	subComponents = {}

	self = self.context
	
	if(self._componentSet) then
		
		for _,component in pairs (self._componentSet)
		do
			table.insert(subComponents,component)
		end
		
		return subComponents
	end
	
	return subComponents
end

function ContentController:findComponent(membershipId)
	
	context = self.context
	
	local subcomponent = nil
		
	if context._componentSet[membershipId] then
		subcomponent = context._componentSet[membershipId]
	end
		
	return subcomponent
	
end

function ContentController:bindFacet(membershipId,internalFacetName,externalFacetName)

	context = self.context

	local subcomponent = self:findComponent(membershipId)
	if not subcomponent then
		--TODO: throws ComponentNotFoundException
		print('Component not found!')
	end
	
	local internalFacet = subcomponent:getFacetByName(internalFacetName)
	if not internalFacet then
		--TODO: FacetNotAvailableInComponent
		print('Facet not available in subcomponent')
	end
	
	local facetInComposite = context[externalFacetName] 
	if facetInComposite then
		--TODO: FacetAlreadyExistsException
		print('Facet already exposed')
	end

	local metaFacet = subcomponent:getFacetByName("IMetaInterface")
	metaFacet = orb:narrow(metaFacet,"IDL:".._scs_core_package.."IMetaInterface:".._scs_version)
					
	local descriptions = metaFacet:getFacetsByName({internalFacetName})
	local interfaceName = descriptions[1].interface_name
	local facetRef = orb:narrow(descriptions[1].facet_ref)
	local bindingId = context._facetBindingId
							
	context._facetDescs[externalFacetName] = {}	
	context._facetDescs[externalFacetName].name = externalFacetName
	context._facetDescs[externalFacetName].interface_name = interfaceName
	context._facetDescs[externalFacetName].facet_ref = orb:newservant(facetRef)
	context._facetBindingHash[bindingId] = externalFacetName
	context._facetBindingId = bindingId + 1
	context[externalFacetName] = context._facetDescs[externalFacetName].facet_ref	
	context._facetDescs[externalFacetName].facet_ref._component = function() return context.IComponent end
	
	return bindingId
	
end

function ContentController:unbindFacet(bindingId)

	context = self.context
	
	local facetName = context._facetBindingHash[bindingId]
	
	if facetName then
			
		local status, err = oil.pcall(context._orb.deactivate, context._orb, context._facetDescs[facetName].facet_ref)
		local errFacets = {}
	
		if not status then
			errFacets[name] = err
		else
			context._facetDescs[facetName] = nil
			context[facetName]  = nil
		end
	
	end
			
	
	
end

function ContentController:bindReceptacle(membershipId,internalReceptacleName,externalReceptacleName)

	context = self.context
		
	local subcomponent = self:findComponent(membershipId)
	if not subcomponent then
		--TODO: throws ComponentNotFoundException
		print('Component not found!')
	end
	
	local metaFacet = orb:narrow(subcomponent:getFacetByName("IMetaInterface"))
	if not metaFacet then
		--TODO: throws ReceptacleNotAvailableInComponent
		print("Receptacle Not Available in Component")
	end
	
	if not context._receptacleDescs[externalReceptacleName] then	
	
		local description = metaFacet:getReceptaclesByName({internalReceptacleName})
		local interfaceName = description[1].interface_name
		local isMultiplex = description[1].is_multiplex
		local connections = description[1].connections or {}
		
		context._receptacleDescs[externalReceptacleName] = {}
		context._receptacleDescs[externalReceptacleName].name = name
		context._receptacleDescs[externalReceptacleName].interface_name = interfaceName
		context._receptacleDescs[externalReceptacleName].is_multiplex = is_multiplex
		context._receptacleDescs[externalReceptacleName].connections = connections
		context._receptacleDescs[externalReceptacleName]._internalConnections = {}
		context._receptacleBindingHash[externalReceptacleName] =  {}
	end
	
	internal = {}
	internal["name"] = internalReceptacleName
	internal["subcomponent"] = subcomponent
	table.insert(context._receptacleBindingHash[externalReceptacleName],internal)
	
	local bindingId = context._receptacleBindingId
	context._receptacleBindingId = context._receptacleBindingId + 1
	
	context._receptacleBinding[bindingId] = externalReceptacleName

    
	return bindingId
end

function ContentController:unbindReceptacle(bindingId)

	context = self.context
	
	local receptacleName = context._receptacleBinding[bindingId]
	local receptacle = context._receptacleDescs[receptacleName]
	local internalConnections = receptacle._internalConnections
	
	if not receptacle then
		error{ "IDL:scs/core/NoConnection:1.0" }
	end

	if not receptacle.is_multiplex then
		context[receptacleName] = nil
	end
	
	context._receptacleDescs[receptacleName] = nil
		
	for i,v in pairs(receptacle._internalConnections)
	do
		local cmp = v.subcomponent
		local receptacles = context._orb:narrow(cmp:getFacetByName("IReceptacles"))
		receptacles:disconnect(v.connectionId)
	end

end