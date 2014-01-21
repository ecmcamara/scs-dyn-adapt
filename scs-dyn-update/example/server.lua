local oil = require "oil"
local ComponentContext = require "scs.core.ComponentContext"
local orb = oil.init()
--remove S
local IDynamicUpdatable = require "DynamicUpdatable"
--remove E

oil.main(function()
  -- load IDL
  orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
  orb:loadidlfile("idl/IControl.idl")
   --remove S
  orb:loadidlfile("../../scs-idl/dynupdate.idl")
  --remove E
  oil.newthread(orb.run, orb)

  -- load implementation
  dofile("Control.lua")
  
  --create TV component
  local TVcomponentId = { name = "TV", major_version = 1, minor_version = 0, patch_version = 0, platform_spec = "" }
  local TVinstance = ComponentContext(orb, TVcomponentId)
  TVinstance:addFacet("Control", "IDL:IControl:1.0", Control(),"Control")
  
   --remove S
  TVinstance:addFacet("IDynamicUpdatable","IDL:scs/demos/dynupdate/IDynamicUpdatable:1.0", IDynamicUpdatable)
  --remove E
  
  --save TV IComponent reference   
  oil.writeto("tv.ior", orb:tostring(TVinstance.IComponent))
  

end)

