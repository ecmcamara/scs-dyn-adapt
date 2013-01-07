--Prestar aten��o na ordem dos requires....pois base.lua do scs caso n�o encontre nenhum orb cria o seu pr�prio
--Cria��o do componente Hello
local oo = require "loop.base"
local oil = require "oil"


--inicializa��o do ORB
--port e host apenas para fins do exemplo
local orb = oil.init({host="localhost",port=1090})
oil.orb = orb

local scs = require "scs.core.base"

--carga das IDLs no ORB
orb:loadidlfile("../../../../../idl/scs.idl")
orb:loadidlfile("hello.idl")

--implementa��o da faceta IHello
local Hello = oo.class{name = "World"}
function Hello:sayHello(str)
	--table.foreach(self.context,print)
	if str then
		print("Hello " .. str .. "!")
	else
		print('String null')
	end
end

--cria��o das descri��es de facetas e recept�culos: Basic component
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

-- cria��o do ComponentId
local cpId = {
	name = "Hello1",
	major_version = 1,
	minor_version = 0,
	patch_version = 0,
	platform_spec = ""
}

--fun��o main
oil.main(function ()
	--instru��o ao ORB para que aguarde por chamadas remotas (em uma nova "thread")
	oil.newthread(orb.run,orb)

	--cria o componente
	basicComponent = scs.newComponent(facetDescs,receptDescs,cpId)
	
	oil.writeto("basic_component1.ior", orb:tostring(basicComponent.IComponent))

end)
