local oil = require "oil"
local oo        = require "loop.base"
--local comp      = require "loop.component.base"
--local utils     = require "scs.core.utils"
--local help      = require "scs.auxiliar.componenthelp"
--local scs       = require "scs.core.base"
--local scsprops  = require "scs.auxiliar.componentproperties"
local ComponentContext = require "scs.core.ComponentContext"

-- loading properties to check openbus and OiL requirements
--[[local props = {}
--utils.Utils:readProperties(props, "../container/Properties.txt")

-- OiL configuration
local oilconf = { tcpoptions = {reuseaddr = true} }

if props.host then
  oilconf.host = props.host.value
end
if props.port then
  oilconf.port = tonumber(props.port.value)
end
if props.interception then
  oilconf.flavor = props.interception.value
end
--~ Uncoment the following lines for verbose output
--~ if props.oilverbose then
--~   oil.verbose:level(tonumber(props.oilverbose.value))
--~ end
]]--
-- inicialização do ORB
local orb = oil.init()
oil.orb = orb

-----------------------------------------------------------
--------------------- suspender class ---------------------
-----------------------------------------------------------

local Suspender = oo.class{

  -- SCS util object --
  --utils           = utils.Utils,

  -- Keys colection, keeps tracks of objects being requested --
  keys            = {},

  -- Each component status --
  status          = {},

  ----------------------------
  -- Servant request tables --
  ----------------------------

  -- Enqueued tasks for suspended components ----------------
  requestsQueue   = {},

  -- Number of request being processed by each servant ------
  incomingCalls = {},

  -- Number of requests currently required by each servant --
  outcomingCalls = {},

  -----------------------------
  -- Servant possible status --
  -----------------------------

  -- HALTED: Servants does not receive any requests -------------
  HALTED          =  1,

  -- SUSPENDED: Requests are enqueued until servant is resumed --
  SUSPENDED       = -1,

  -- RESUMED: Servant is running normally -----------------------
  RESUMED         =  0,


  --------------------------------------------------------------------------------
  -- Suspending request modes (used in method Suspender:suspend(servant, mode)) --
  --------------------------------------------------------------------------------

  -- SYNCHRONOUS: Awaits until servant is not receiving request
  SYNCHRONOUS     =  1,

  -- ASYNCHRONOUS: Suspends the servant only if the it has no incoming and outcoming calls
  ASYNCHRONOUS   =  0

}


--
-- Description: Instantiates a component suspender tool
-- Return Value: A Suspender object
--
function Suspender:__init()
  local self           = oo.rawnew(self, {})
  self.keys            = {}
  self.status          = {}
  self.requestsQueue   = {}
  self.incomingCalls   = {}
  self.outcomingCalls  = {}
  return self
end

--
-- Description: Registers a servant for further status manipulation
-- Parameter key: The servant identifier
-- Return Value: true if the servant was succesfully registered, false otherwise
--
function Suspender:register(key)
  assert(key ~= nil, "Trying to register a nil key")
  if (self.isRegistered(key)) then return true end
  --self.utils:verbosePrint("Suspension::Suspender::register Registering object of id: " .. key)
  self.keys[key]           = key
  self.status[key]         = self.RESUMED
  self.requestsQueue[key]  = {}
  self.incomingCalls[key]  = 0
  self.outcomingCalls[key] = 0
  print("calls[" .. key .. "] == " .. self.incomingCalls[key])
  return self.isRegistered(key)
end


--
-- Description: Checks if an object is registered
-- Parameter key: The object identifier
-- Return Value: true if the servant is registered, false otherwise
--
function Suspender:isRegistered(key)
  assert(key ~= nil, "Key being checked is nil")
  --self.utils:verbosePrint("Suspension::Suspender::isRegistered Checking whether object of key" .. key .. " is registered")
  return (self.keys[key] ~= nil)  -- Just checks key collection
end

--
-- Description: Suspends a SCS component synchronously. This means that this function blocks until the component is in a safe state (has no outcoming or incoming calls)
-- Parameter component: The SCS component
-- Return value: true if the component was suspended; false otherwise
--
function Suspender:suspendComponent(component)
  self.suspendComponent(component, self.SYNCHRONOUS)
end

--
-- Description: Suspends a SCS component
-- Parameter component: The SCS component
-- Parameter mode: The suspension mode. Specified in the Suspender class
-- Return value: true if the component was suspended; false otherwise
--
function Suspender:suspendComponent(component, mode)
  assert(component ~= nil, "Suspension::Suspender::suspendComponent component parameter is nil")
  assert(mode ~= nil, "Suspension::Suspender::suspendComponent mode parameter is nil")
  local servants = component.getServants()  -- TODO: Change this
  for _, servant in ipairs(servants) do
    self.suspend(servant, mode)
  end
  return true
end

--
-- Description: Resumes the execution of a SCS component
-- Parameter component: The SCS component
-- Return value: true if the component is running again, false otherwise
--
function Suspender:resumeComponent(component)
  assert(component ~= nil, "Suspension::Suspender::resumeComponent component parameter is nil")
  local servants = component.getServants()  -- TODO: Change this
  for _, servant in ipairs(servants) do
    self.resume(servant)
  end
  return true
end

--
-- Description: Halts a SCS component, ignoring all of its calls
-- Parameter component: The SCS component
-- Return value: true if the component is halted, false otherwise
--
function Suspender:haltComponent(component)
  assert(component ~= nil, "Suspension::Suspender::haltComponent component parameter is nil")
  local servants = component.getServants()  -- TODO: Change this
  for _, servant in ipairs(servants) do
    self.halt(servant)
  end
  return true
end

--
-- Parameter target: The targe to be suspended. Can be either a component or a servant
-- Return Value: True if the component was suspended, false otherwise
--
function Suspender:suspend(servant)
  return self.suspend(servant, self.SYNCHRONOUS)
end

--
-- Description: Suspends a component, enqueuing its calls.
-- Parameter mode: The suspending mode. Defined in the Suspender class (modes ASYNCHRONOUS and SYNCHRONOUS)
-- Return Value: True if the component was suspended, false otherwise
--
function Suspender:suspend(servant, mode)
  assert(servant ~= nil, "Suspension::Suspender::suspend servant parameter nil")
  assert(mode == self.SYNCHRONOUS or mode == self.ASYNCHRONOUS, "Suspending mode is invalid. Use Suspender.SYNCHRONOUS or Suspender.ASYNCHRONOUS instead")
 -- self.utils:verbosePrint("Suspension::Suspender::suspend Suspending servant " .. servant)
  if (not self.isRegistered(servant)) then self.register(servant) end  --TODO: Check whether this line or the following is the right one to be used
  --assert(self.isRegistered(servant), "Servant " .. servant .. " not registered")

  self.status[servant] = self.SUSPENDED  -- Blocks outcoming and incoming calls

  -- Servant is requiring or responding requests, and ASYNCHRONOUS mode was required, returns false
  if (mode == self.ASYNCHRONOUS and (self.incomingCalls[servant] ~= 0 or self.outcomingCalls[servant] ~= 0)) then
    return false
  end

  -- Waits until outcoming and incoming requests are over
  repeat
    oil.sleep(1)
  until (self.incomingCalls[servant] == 0 and self.outcomingCalls[servant] == 0)
  return true
end

--
-- Description: Halts a servant, ignoring all of its calls
-- Parameter servant: The servant
-- Return value:
--
function Suspender:halt(servant)
  assert(servant ~= nil, "Suspension::Suspender::halt servant parameter nil")
  --self.utils:verbosePrint("Suspension::Suspender::halt Halting servant")
  if (not self.isRegistered(servant)) then self.register(servant) end  --TODO: Check whether this line or the following is the right one to be used
  --assert(self.isRegistered(servant), "Servant " .. servant .. " not registered")
  -- TODO: raise excepetions if there were any calls enqueued
  -- TODO: Destroy every suspended call
  self.requestsQueue[servant] = nil  -- Ignores enqueued calls
  self.status[servant] = self.HALTED
end

--
-- Description: Resumes a servant execution. If the servant has previous enqueued calls, all of these are dispatched to the servant
-- Parameter servant: The servants
-- Return value:
--
function Suspender:resume(servant)
  assert(servant ~= nil, "Suspension::Suspender::resume servant parameter nil")
 -- self.utils:verbosePrint("Suspension::Suspender::resume Resuming servant")
  if (not self.isRegistered(servant)) then self.register(servant) end  --TODO: Check whether this line or the following is the right one to be used
  --assert(self.isRegistered(servant), "Servant " .. servant .. " not registered")

  -- Current servant status
  local servantStatus = self.status[servant]

  -- Component already running, nothing to do
  if (servantStatus == self.RESUMED) then
  --  self.utils:verbosePrint("Suspension::Suspender::resume Servant " .. servant .. " already running")
  elseif (self.status[servant] == self.SUSPENDED) then  -- Component was suspended
	-- Dequeues blocked calls and yields them
    local requestQueue = self.requestsQueue[servant]
    repeat
      local task = table.remove(requestQueue, 1)
	  task:resume()
    until(#requestQueue == 0)

	-- Change status
	self.status[servant] = self.RESUMED

  elseif (self.status[servant] == self.HALTED) then  -- Component was halted
    -- Change status only
	self.status[servant] = self.RESUMED
  end
end

--
-- Description: Auxiliary method. Process a request to a servant, both outcoming and incoming
-- Parameter request: The request
--
function Suspender:processRequest(request)
  assert(request ~= nil, "suspension::Suspender::processrequest Request is nil")
 -- self.utils:verbosePrint("suspension::Suspender::processrequest Processing request")

  -- Gets the requested servant
  local servant = request.servant

  self.register(servant)

  -- Checks servant integrity
  assert(servant ~= nil, "suspension::Suspender::processrequest Servant is nil")

  -- Gets the servant current status
  local servantStatus = self.status[servant]

  -- Checks if component is not running
  if (servantStatus ~= self.RESUMED) then
    -- Suspends call until resumed
    if (servantStatus == self.SUSPENDED) then
	  local currentTask = oil.tasks.current
	  currentTask:suspend()
	elseif (servantStatus == self.HALTED) then
	  -- TODO: DESTROY CALL
	end
  end
end

-------------------------------------------------------------
-------------------- Server interceptor  --------------------
-------------------------------------------------------------

--
-- Description: Interceptor method. Intercepts all clients requests on the server side
-- Parameter request: Described in http://oil.luaforge.net/manual/basics/brokers.html#setserverinterceptor
--
function Suspender:receiverequest(request)
 -- self.utils:verbosePrint("suspension::Suspender::receiverequest Intercepting request")

  -- Process the request
  oil.pcall(self.processRequest, request)--self.processRequest(request)

  print("INC " .. type(self.incomingCalls[servant]))
  -- Accounts the incoming request
  self.incomingCalls[servant] = self.incomingCalls[request.servant] + 1
end

--
-- Description: Interceptor method. Intercepts all clients requests
-- Parameter reply: Described in http://oil.luaforge.net/manual/basics/brokers.html#setserverinterceptor
--
function Suspender:sendreply(reply)
--  self.utils:verbosePrint("Suspension::Suspender::sendreply Sending intercepted reply")

  local servant = reply.servant

  -- Accounts the terminated request
  self.incomingCalls[servant] = self.incomingCalls[servant] - 1
end

-------------------------------------------------------------
-------------------- Client interceptor  --------------------
-------------------------------------------------------------

--
-- Description: Interceptor method. Intercepts outcoming calls in order to achieve a safe point
-- Parameter request: Described in http://oil.luaforge.net/manual/basics/brokers.html#setserverinterceptor
--
function Suspender:sendrequest(request)
  assert(request ~= nil, "suspension::Suspender::processrequest Request is nil")
 -- self.utils:verbosePrint("suspension::Suspender::sendrequest Sending request")

  -- Process the request
  --self.processRequest(request)
  --self.utils:verbosePrint("suspension::Suspender::processrequest Processing request")

  for k, v in ipairs(request.service_context) do print(k, v) end

  --print("tipo da chave: " .. )

  -- Gets the requested servant
  local servant = request.servant

  -- Checks servant integrity
  assert(servant ~= nil, "suspension::Suspender::processrequest Servant is nil")

  -- Gets the servant current status
  local servantStatus = self.status[servant]

  -- Checks if component is not running
  if (servantStatus ~= self.RESUMED) then
    -- Suspends call until resumed
    if (servantStatus == self.SUSPENDED) then
	  local currentTask = oil.tasks.current
	  currentTask:suspend()
	elseif (servantStatus == self.HALTED) then
	  -- TODO: DESTROY CALL
	end
  end


  -- Accounts the request
  self.outcomingCalls[servant] = self.outcomingCalls[servant] + 1
end

--
-- Description: Interceptor method. Intercepts all clients requests
-- Parameter reply: Described in http://oil.luaforge.net/manual/basics/brokers.html#setserverinterceptor
--
function Suspender:receivereply(reply)
 -- self.utils:verbosePrint("suspension::Suspender::receivereply Receiving reply")

  -- Gets the requested servant
  local servant = reply.servant

  -- Accounts the request ending
  self.outcomingCalls[servant] = self.outcomingCalls[servant] - 1
end



require "hello"

-- carga das IDLs no ORB
orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
orb:loadidlfile("idl/hello.idl" )

-- função main
oil.main(function()
  -- Instrução ao ORB para que aguarde por chamadas remotas (em uma nova "thread")
  oil.newthread(orb.run, orb)

  -- Sets the Suspender class as the interceptor
  orb:setserverinterceptor(Suspender)
  --orb:setclientinterceptor(Suspender)

  -- Cria o componente e escreve sua configuração IOR no próprio diretório
   dofile("Hello.lua")
  local componentId = { name = "Hello", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local instance = ComponentContext(orb, componentId)
  instance:addFacet("Hello", "IDL:scs/demos/helloworld/Hello:1.0", Hello())
  if (instance == nil) then print ("nil hello instance") end
  oil.writeto("hello.ior", orb:tostring(instance.Hello))
  --[[local iHelloIOR = oil.readfrom("hello.ior")
  if (iHelloIOR == nil) then print("Error while reading IOR file") else print ("Read IOR file") end

  -- obtenção das facetas IHello e IComponent
  local iHelloFacet = orb:newproxy(iHelloIOR, "IDL:scs/demos/helloworld/Hello:1.0")
  -- precisamos utilizar o método narrow pois estamos recebendo um org.omg.CORBA. Object
  --local icFacet = orb:narrow(iHelloFacet:_component())

  -- inicialização do componente
  --icFacet:startup()
  --print(icFacet)

  print("Saying hello")
  iHelloFacet:sayHello()
  iHelloFacet:sayHello()
  iHelloFacet:sayHello()
  iHelloFacet:sayHello()]]--
end)
