oil = require "oil"
local orb = oil.init()

oil.main(function()
  orb:loadidlfile(os.getenv("IDL_PATH") .. "/scs.idl")
  orb:loadidlfile("idl/IRemoteInput.idl")

  -- loading Remote reference
  local f = assert(io.open("remote.ior", "r"), "Error opening remote IComponente's IOR file!")
  local ior = f:read("*all")
  f:close()
  
  --get IComponent reference
  local remoteIComponent = orb:newproxy(ior, "synchronous", "IDL:scs/core/IComponent:1.0")
  
  --get facet reference
  local remote = remoteIComponent:getFacetByName("RemoteInput")
  remote = orb:narrow(remote)
  
 --use
  remote:buttonPress("+")

end)
