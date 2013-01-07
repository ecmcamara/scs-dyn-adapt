--Prestar atenção na ordem dos requires....pois base.lua do scs caso não encontre nenhum orb cria o seu próprio
--Criação do componente Hello
local oo = require "loop.base"
local oil = require "oil"


--inicialização do ORB
--port e host apenas para fins do exemplo
local orb = oil.init({host="localhost",port=1090})
oil.orb = orb

local scs = require "scs.core.base"

--carga das IDLs no ORB
orb:loadidlfile("../../../../../idl/scs.idl")
orb:loadidlfile("hello.idl")

--implementação da faceta IHello
local Hello = oo.class{name = "World"}
function Hello:sayHello(str)
	--table.foreach(self.context,print)
	if str then
		print("Hello " .. str .. "!")
	else
		print('String null')
	end
end

--criação das descrições de facetas e receptáculos: Basic component
local facetDescs = {}
facetDescs.IHello = {
	name = "IHello",
	interface_name = "IDL:scs/demos/helloworld/IHello:1.0",
	class = Hello
}

local receptDescs = {}

receptDescs.IHelloReceptacle = {
	name = "IHelloReceptacle",
	interface_name = "IDL:scs/demos/helloworld/IHello:1.0",
	is_multiplex = false,
	type = 'Receptacle'
}

-- criação do ComponentId
local cpId = {
	name = "Hello1",
	major_version = 1,
	minor_version = 0,
	patch_version = 0,
	platform_spec = ""
}

--função main
oil.main(function ()
	--instrução ao ORB para que aguarde por chamadas remotas (em uma nova "thread")
	oil.newthread(orb.run,orb)

	--cria o componente
	basicComponent = scs.newComponent(facetDescs,receptDescs,cpId)
	
	oil.writeto("basic_component1.ior", orb:tostring(basicComponent.IComponent))

end)
