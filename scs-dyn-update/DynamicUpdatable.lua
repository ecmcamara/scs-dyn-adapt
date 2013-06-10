local oo = require "loop.base"
local cc = require "scs.core.ComponentContext"
local oil = require "oil"
local error =error

--implementação da faceta IDynamicUpdatable
local IDynamicUpdatable = oo.class{
	--tabela com os retorno das chamadas assíncronas
	_AsyncCalls={},
	updatingState="HALTED",
	finishedState="RESUMED",
	componentUpdating=false,
	--tabela com o registro da última atualização
	_lastUpdate={},
	--tabela que mapeia as versões anteriores das facetas
	_rollBacks={},
	--tabela que mapeia o codigo de rollback
	_downCodes={},
	--tabela que guarda as facetas deletadas
	_deletedFacets={}
}
--construtor
function IDynamicUpdatable:__init()
  return oo.rawnew(self, {})
end
--indica que iniciou uma atualização do componente
function IDynamicUpdatable:ComponentUpdateStarted()
	self:UpdateStarted()
	self.componentUpdating = true
end
--indica que terminou uma atualiação do componente
function IDynamicUpdatable:ComponentUpdateFinished()
	self.componentUpdating = false
	self:UpdateFinished()
end
--indica que iniciou uma atualização da faceta
function IDynamicUpdatable:UpdateStarted()
	if self.context and self.context._facets and self.context._facets.ILifeCycle and not componentUpdating then
		self.context._facets.ILifeCycle:changeState(self.updatingState)
	end
end
--indica que terminou uma atualiação da faceta
function IDynamicUpdatable:UpdateFinished()
	if self.context and self.context._facets and self.context._facets.ILifeCycle and not componentUpdating then
		self.context._facets.ILifeCycle:changeState(self.finishedState)
	end
end
--recupera o estado em que o componete ficará quando estiver realizando uma atualização
function IDynamicUpdatable:GetUpdateState()
	return self.updatingState
end
--altera o estado que o componente ficará enquanto estiver atualizando SUSPENDED || HALTED, Enfileira requisições ou descarta elas
function IDynamicUpdatable:ChangeUpdateState(state)
	if state == "SUSPENDED" or state == "HALTED" then
		self.updatingState=state 
	end
	return true
end
--ve se o componente está consistente
function IDynamicUpdatable:CheckComponent()
	--check for component
	if not self.context then
		return "No Component found"
	end
	--check for facet collection, membrane version 	
	if not self.context._facets then
		if not self.context._facetDescs then
			return "Facet collection not found"
		end
		self.context._facets = self.context._facetDescs
	end
	return false
end
--insere nova faceta no componente
function IDynamicUpdatable:InsertFacet(facet)
	local check = self:CheckComponent() 
	if check then
		return check
	end
	self:UpdateStarted()
	--check if there's a facet with same name
	if self.context._facets[facet.description.name] then
		self:UpdateFinished()
		return "Facet with same name already exists"
	end
	--check facet implementation code for compilation errors
	local impl,errorMessage = loadstring(facet.description.facet_implementation)
	if not impl then
		self:UpdateFinished()
		return tostring(errorMessage)
	end
	--check patchUpCode for compilation errors
	local patchUpCode,errorMessage2 = loadstring(facet.patchUpCode)
	if not patchUpCode then
		self:UpdateFinished()
		return tostring(errorMessage2)
	end
	--check for interface
	if not facet.description.facet_idl or facet.description.facet_idl =="" then
		return "The ORB needs the IDL in order to create a facet"
	end
	local statusIDL, errorMessage3 = pcall(oil.orb.loadidl,oil.orb,facet.description.facet_idl)
	if not statusIDL then
		return tostring(errorMessage3)
	end
	--instanciate new facet
	local statusImplementation,newFacet = pcall(impl)
	--check for errors
	if not statusImplementation then
		self:UpdateFinished()
		return tostring(newFacet)
	end
	--add facet
	local statusUpdate, errorMessage4 = pcall(cc.addFacet,self.context,facet.description.name,facet.description.interface_name,newFacet,facet.key)
	if not statusUpdate then
		self:UpdateFinished()
		return tostring(errorMessage4)
	end
	newFacet = self.context._facets[facet.description.name]
	--run patchUpCode
	local locals = { self = self,_newFacet=newFacet.facet_ref}
	setfenv(patchUpCode, setmetatable(locals, { __index = _G }))
	local statusPatch,errorMessage5= pcall(patchUpCode)
	if not statusPatch then
		self:UpdateFinished()
		return tostring(errorMessage5)
	end
	self._lastUpdate[newFacet] = facet
	self:UpdateFinished()
	return tostring("Mission Acomplished!")
end
function IDynamicUpdatable:RetrieveFacet(facetName)
	local check = self:CheckComponent() 
	if  check then
		return error(check)
	end
	local newFacet = self.context._facets[facetName]
	return self._lastUpdate[newFacet]
end
--atualiza a faceta
function IDynamicUpdatable:UpdateFacet(facet)
	local check = self:CheckComponent() 
	if check then
		return check
	end
	self:UpdateStarted()
	--check if there's a facet with same name
	if not self.context._facets[facet.description.name] then
		self:UpdateFinished()
		return "No Facet with same name"
	--check if the Interface match
	elseif not self.context._facets[facet.description.name].interface_name == 
	facet.description.interface_name then
		self:UpdateFinished()
		return "Interface doesn't match"
	end
	--check facet implementation code for compilation errors
	local impl,errorMessage = loadstring(facet.description.facet_implementation)
	if not impl then
		self:UpdateFinished()
		return tostring(errorMessage)
	end
	--check patchUpCode for compilation errors
	local patchUpCode,errorMessage2 = loadstring(facet.patchUpCode)
	if not patchUpCode then
		self:UpdateFinished()
		return tostring(errorMessage2)
	end
	--check patchDownCode for compilation errors
	local patchDownCode,errorMessage3 = loadstring(facet.patchDownCode)
	if not patchDownCode then
		self:UpdateFinished()
		return tostring(errorMessage3)
	end
	--instanciate new facet
	local statusImplementation,newFacet = pcall(impl)
	--check for errors
	if not statusImplementation then
		self:UpdateFinished()
		return tostring(newFacet)
	end
	--save old facet
	local oldFacet = self.context._facets[facet.description.name]
	--update facet
	local statusUpdate, errorMessage4 = pcall(cc.updateFacet,self.context,facet.description.name,newFacet)
	if not statusUpdate then
		self:UpdateFinished()
		return tostring(errorMessage4)
	end
	newFacet = self.context._facets[facet.description.name]
	--run patchUpCode
	local locals = { self = self,_oldFacet=oldFacet.facet_ref,_newFacet=newFacet.facet_ref}
	setfenv(patchUpCode, setmetatable(locals, { __index = _G }))
	local statusPatch,errorMessage5= pcall(patchUpCode)
	if not statusPatch then
		self:UpdateFinished()
		return tostring(errorMessage5)
	end
	self._rollBacks[newFacet] = oldFacet
	self._downCodes[newFacet] = patchDownCode
	self._lastUpdate[newFacet] = facet
	self:UpdateFinished()
	return tostring("Mission Acomplished!")
end

function IDynamicUpdatable:DeleteFacet(facetName)
	local check = self:CheckComponent() 
	if check then
		return check
	end
	self:UpdateStarted()
	--check if there's a facet with same name
	if not self.context._facets[facetName] then
		self:UpdateFinished()
		return "No Facet with same name"
	end
	--save old facet
	local oldFacet = self.context._facets[facetName]
	local statusUpdate, errorMessage = pcall(cc.removeFacet,self.context,facetName)
	if not statusUpdate then
		self:UpdateFinished()
		return tostring(errorMessage)
	end
	self._deletedFacets[facetName] = oldFacet
	self:UpdateFinished()
	return tostring("Mission Acomplished!")
end
function IDynamicUpdatable:RollbackFacet(facetName)
	local check = self:CheckComponent() 
	if check then
		return false
	end
	self:UpdateStarted()
	--check if the facet still exists or has been deleted
	if not self.context._facets[facetName] then
		if not _deletedFacets[facetName] then
			self:UpdateFinished()
			return false
		end
		local statusUpdate, errorMessage = pcall(cc.addFacet,self.context,facetName,self._deletedFacets[facetName].interface_name,self._deletedFacets[facetName].facet_ref,self._deletedFacets[facetName].key)
		if not statusUpdate then
			self:UpdateFinished()
			return false
		end
		self._deletedFacets[facetName] = nil
		self:UpdateFinished()
		return true
	end
	local oldFacet = self.context._facets[facetName]
	--facet exists, check forward version
	if not self._rollBacks[oldFacet] then
		self:UpdateFinished()
		return false
	else
		--execute patchDownCode and change facet
		--_rollBacks[oldFacet]
		--_downCodes[oldFacet]
		local newFacet = self._rollBacks[oldFacet]
		local statusUpdate, errorMessage4 = pcall(cc.updateFacet,self.context,facetName,newFacet.facet_ref)
		if not statusUpdate then
		print(statusUpdate,errorMessage4)
			self:UpdateFinished()
			return false
		end
		
		--update the reference on rollbacktable
		local rollback = self._rollBacks[newFacet]
		local downCode = self._downCodes[newFacet]
		local lastUpdate= self._lastUpdate[newFacet]
		self._downCodes[newFacet] = nil
		self._rollBacks[newFacet] = nil
		self._lastUpdate[newFacet] = nil
		newFacet = self.context._facets[facetName]
		self._rollBacks[newFacet] = rollback
		self._downCodes[newFacet] = downCode
		self._lastUpdate[newFacet] = lastUpdate
		--run patchDownCode
		local locals = { self = self,_oldFacet=oldFacet.facet_ref,_newFacet=newFacet.facet_ref}
		setfenv(self._downCodes[oldFacet], setmetatable(locals, { __index = _G }))
		local statusPatch,errorMessage5= pcall(self._downCodes[oldFacet])
			if not statusPatch then
			self:UpdateFinished()
			return false
		end
		self:UpdateFinished()
		return true
	end
end

function IDynamicUpdatable:UpdateComponent(newId,facets)	
	self:ComponentUpdateStarted()
	self.context._componentId = newId
	local ret = ""
	for k,v in ipairs(facets) do
		ret = ret.. v.description.name ..":".. self:UpdateFacet(v).."\n"
	end
	self:ComponentUpdateFinished()
	return ret
end  

function IDynamicUpdatable:InsertFacetAsync(facet)
	local ret = #self._AsyncCalls
	self._AsyncCalls[#self._AsyncCalls] = "Not Yet"
	
	oil.newthread(function() 
		self._AsyncCalls[ret]= self:InsertFacet(facet) end)
	return ret..""
end

function IDynamicUpdatable:UpdateFacetAsync(facet)
	local ret = #self._AsyncCalls
	self._AsyncCalls[#self._AsyncCalls] = "Not Yet"
	
	oil.newthread(function() 
		self._AsyncCalls[ret]= self:UpdateFacet(facet) end)
	return ret..""
end
function IDynamicUpdatable:DeleteFacetAsync(facet)
	local ret = #self._AsyncCalls
	self._AsyncCalls[#self._AsyncCalls] = "Not Yet"
	
	oil.newthread(function() 
		self._AsyncCalls[ret]= self:DeleteFacet(facet) end)
	return ret..""
end


function IDynamicUpdatable:UpdateComponentAsync(newId,facets)
	local ret = #self._AsyncCalls
	self._AsyncCalls[#self._AsyncCalls] = "Not Yet"
	oil.newthread(function() 
		self._AsyncCalls[ret]= self:UpdateComponent(newId,facets) end)
	return ret..""
end

function IDynamicUpdatable:GetAsyncRet(key)
	local i = tonumber(key)
	local ret = self._AsyncCalls[i]
	if ret then
		return ret
	else 
		return "Invalid Key"
	end
end

--fim

return IDynamicUpdatable