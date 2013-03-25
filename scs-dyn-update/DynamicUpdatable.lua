local oo = require "loop.base"
local cc = require "scs.core.ComponentContext"
local oil = require "oil"

--implementação da faceta IDynamicUpdatable
local IDynamicUpdatable = oo.class{_UpdateFacetAsync={},_UpdateComponentAsync={}, updatingState="HALTED",finishedState="RESUMED",componentUpdating=false}

function IDynamicUpdatable:__init()
  return oo.rawnew(self, {})
end

function IDynamicUpdatable:ComponentUpdateStarted()
	self:UpdateStarted()
	componentUpdating = true
end
function IDynamicUpdatable:ComponentUpdateFinished()
	componentUpdating = false
	self:UpdateFinished()
end
function IDynamicUpdatable:UpdateStarted()
	if self.context and self.context._facets and self.context._facets.ILifeCycle and not componentUpdating then
		self.context._facets.ILifeCycle:changeState(self.updatingState)
	end
end

function IDynamicUpdatable:UpdateFinished()
	if self.context and self.context._facets and self.context._facets.ILifeCycle and not componentUpdating then
		self.context._facets.ILifeCycle:changeState(self.finishedState)
	end
end


function IDynamicUpdatable:GetUpdateState()
	return self.updatingState
end
function IDynamicUpdatable:ChangeUpdateState(state)
	if state == "SUSPENDED" or state == "HALTED" then
		self.updatingState=state 
	end
	return true
end
function IDynamicUpdatable:UpdateFacet(facet)
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
	--check patch code for compilation errors
	local patchCode,errorMessage2 = loadstring(facet.patchCode)
	if not patchCode then
		self:UpdateFinished()
		return tostring(errorMessage2)
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
	--run patchCode
	local locals = { self = self,_oldFacet=oldFacet,_newFacet=newFacet}
	setfenv(patchCode, setmetatable(locals, { __index = _G }))
	local statusPatch,errorMessage5= pcall(patchCode)
	if not statusPatch then
		self:UpdateFinished()
		return tostring(errorMessage5)
	end
	self:UpdateFinished()
	return tostring("Mission Acomplished!")
end

function IDynamicUpdatable:UpdateFacetAsync(facet)
	local ret = #self._UpdateFacetAsync
	self._UpdateFacetAsync[#self._UpdateFacetAsync] = "Not Yet"
	
	oil.newthread(function() 
		self._UpdateFacetAsync[ret]= self:UpdateFacet(facet) end)
	return ret..""
end

function IDynamicUpdatable:GetUpdateFacetAsyncRet(key)
	local i = tonumber(key)
	local ret = self._UpdateFacetAsync[i]
	if ret then
		return ret
	else 
		return "Invalid Key"
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

function IDynamicUpdatable:UpdateComponentAsync(newId,facets)
	local ret = #self._UpdateComponentAsync
	self._UpdateComponentAsync[#self._UpdateComponentAsync] = "Not Yet"
	oil.newthread(function() 
		self._UpdateComponentAsync[ret]= self:UpdateComponent(newId,facets) end)
	return ret..""
end

function IDynamicUpdatable:GetUpdateComponentAsyncRet(key)
	local i = tonumber(key)
	local ret = self._UpdateComponentAsync[i]
	if ret then
		return ret
	else 
		return "Invalid Key"
	end
end

--fim

return IDynamicUpdatable