local oo = require "loop.base"

Control = oo.class{ volume = 50,channel=1}

function Control:__init()
  return oo.rawnew(self, {})
end

function Control:volumeUp()
	self.volume = self.volume+2
	if self.volume > 100 then
		self.volume = 100
	end
	print("volumeUpv2:"..self.volume)
end
function Control:volumeDown()
	self.volume = self.volume-2
	if self.volume < 0 then
		self.volume = 0
	end
	print("volumeDownv2:"..self.volume)
end
function Control:changeChannelUp()
	self.channel = self.channel+1
	
	print("changeChannelUpv2:"..self.channel)
end
function Control:changeChannelDown()
	self.channel = self.channel-1
	if self.channel < 0 then
		self.channel = 0
	end
	print("changeChannelDownv2:"..self.channel)
end
function Control:changeChannel(channel)
	self.channel = channel
	if self.channel < 0 then
		self.channel = 0
	end
	print("changeChannelv2:".. channel)
end
function Control:power()
	print("powerv2")
end