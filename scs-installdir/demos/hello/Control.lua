local oo = require "loop.base"

Control = oo.class{}

function Control:__init()
  return oo.rawnew(self, {})
end

function Control:volumeUp()
	print("volumeUp")
end
function Control:volumeDown()
	print("volumeDown")
end
function Control:changeChannelUp()
	print("changeChannelUp")
end
function Control:changeChannelDown()
	print("changeChannelDown")
end
function Control:changeChannel(channel)
	print("changeChannel".. channel)
end
function Control:power()
	print("power")
end