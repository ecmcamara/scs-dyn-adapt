local oo = require "loop.base"

RemoteInput = oo.class{}

function RemoteInput:__init()
  return oo.rawnew(self, {})
end

function RemoteInput:buttonPress(button)
  for i,v in ipairs(self.context.IReceptacles:getConnections("IControlRec")) do
	local tv = v.objref
		if button =="+" then
			tv:volumeUp()
		elseif button == "-" then
			tv:volumeDown()
		elseif button == ">" then
			tv:changeChannelUp()
		elseif button == "<" then
			tv:changeChannelDown()
		elseif button == "O" then
			tv:power()
		else
			local channel = tonumber(button)
			if channel then
				tv:changeChannel(channel)
			end
		end
  end
end

