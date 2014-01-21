local oil = require "oil"
local ComponentContext = require "scs.core.ComponentContext"
local orb = oil.init()

oil.main(function()
  -- load IDL
  orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
  orb:loadidlfile("idl/IControl.idl")
  oil.newthread(orb.run, orb)

  -- load implementation
  dofile("Control.lua")
  
  --create TV component
  local TVcomponentId = { name = "TV", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local TVinstance = ComponentContext(orb, TVcomponentId)
  TVinstance:addFacet("Control", "IDL:IControl:1.0", Control(),"Control")
 
  
  --save TV IComponent reference   
  oil.writeto("tv.ior", orb:tostring(TVinstance.IComponent))
  

end)

