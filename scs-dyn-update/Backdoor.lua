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
		setfenv(f, setmetatable({ self = self.context}, { __index = _G }))
		local _,ret = pcall(f)
		return ret
	end
end
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