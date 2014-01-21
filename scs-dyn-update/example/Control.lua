local oo = require "loop.base"

Control = oo.class{ volume = 50,channel=1}

function Control:__init()
  return oo.rawnew(self, {})
end

function Control:volumeUp()
	self.volume = self.volume+1
	if self.volume > 100 then
		self.volume = 100
	end
	print("volumeUp:"..self.volume)
end
function Control:volumeDown()
	self.volume = self.volume-1
	if self.volume < 0 then
		self.volume = 0
	end
	print("volumeDown:"..self.volume)
end
function Control:changeChannelUp()
	self.channel = self.channel+1
	
	print("changeChannelUp:"..self.channel)
end
function Control:changeChannelDown()
	self.channel = self.channel-1
	if self.channel < 0 then
		self.channel = 0
	end
	print("changeChannelDown:"..self.channel)
end
function Control:changeChannel(channel)
	self.channel = channel
	if self.channel < 0 then
		self.channel = 0
	end
	print("changeChannel:".. channel)
end
function Control:power()
	print("power")
end