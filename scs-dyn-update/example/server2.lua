local oil = require "oil"
local ComponentContext = require "scs.core.ComponentContext"
local orb = oil.init()

oil.main(function()
  -- load IDL
  orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
  orb:loadidlfile("idl/IRemoteInput.idl")
  orb:loadidlfile("idl/IControl.idl")
  oil.newthread(orb.run, orb)

  -- load implementation
  dofile("RemoteInput.lua")
  
  --create RemoteController component
  local RemoteComponentId = { name = "RemoteController", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local RemoteInstance = ComponentContext(orb, RemoteComponentId)
  RemoteInstance:addFacet("RemoteInput", "IDL:IRemoteInput:1.0", RemoteInput())
  RemoteInstance:addReceptacle("IControlRec", "IDL:IControl:1.0", false)
  
  --load TV component
  
  local f = assert(io.open("tv.ior", "r"), "Error opening TV IOR file!")
  local ior = f:read("*all")
  f:close()

  local TVIComponent = orb:newproxy(ior, "synchronous", "IDL:scs/core/IComponent:1.0")
  --connect TV's Control facet on RemoteController's Receptacle
  local RemoteIReceptacles = RemoteInstance.IComponent:getFacetByName("IReceptacles")
  RemoteIReceptacles = orb:narrow(RemoteIReceptacles)
  local TVControl = TVIComponent:getFacetByName("Control")
  TVControl = orb:narrow(TVControl)
  RemoteIReceptacles:connect("IControlRec", TVControl)
  
  --save Remote IComponent reference   
  oil.writeto("remote.ior", orb:tostring(RemoteInstance.IComponent))
  

end)

