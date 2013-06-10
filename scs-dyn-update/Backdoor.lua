local oo = require "loop.base"
local oil = require "oil"

--implementação da faceta IBackdoor
local Backdoor = oo.class{_BackdoorAsync={}}

function Backdoor:__init()
  return oo.rawnew(self, {})
end
--string Backdoor (in string code);
function Backdoor:Backdoor(str)
	local f,e = loadstring(str)
	if not f then
		return tostring(e)
	else
	    local p = ""
		local serverprint = print
		local print = function (s) p = p..tostring(s).."\n" end
		local locals = { self = self.context, print=print, serverprint = serverprint}
		setfenv(f, setmetatable(locals, { __index = _G }))
		local status,ret = pcall(f)
		if ret then p = p .."\n".. ret end
		return tostring(p)
	end
end
--string BackdoorAsync (in string code);
function Backdoor:BackdoorAsync(str)
	local ret = #self._BackdoorAsync
	self._BackdoorAsync[#self._BackdoorAsync] = "Not Yet"
	oil.newthread(function() 
		self._BackdoorAsync[ret]= self:Backdoor(str) end)
	return ret..""
end
--string GetBackdoorAsyncRet (in string key);
function Backdoor:GetBackdoorAsyncRet(key)
	local i = tonumber(key)
	local ret = self._BackdoorAsync[i]
	if ret then
		return ret
	else 
		return "Invalid Key"
	end
end

return Backdoor