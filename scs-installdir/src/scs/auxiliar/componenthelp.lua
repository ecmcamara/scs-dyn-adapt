--
-- SCS
-- help.lua
-- Description: Help class
-- Version: 1.0
--

local oo = require "loop.base"
local Log = require "scs.util.Log"
local assert = assert

--------------------------------------------------------------------------------

module "scs.auxiliar.componenthelp"

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ComponentHelp Class
--------------------------------------------------------------------------------

CpnHelp = oo.class{
  componentName = "",
  helpInfo = "",
}

function CpnHelp:__init()
  return oo.rawnew(self, {})
end

--
-- Description: Returns the component's help.
-- Parameter componentId: Component's identifier.
-- Return Value: String containing help.
-- Throws: IDL:ComponentNotFound IDL:HelpInfoNotAvailable exceptions
--
function CpnHelp:getHelpInfo(componentId)
  Log:info(self.componentName .. "::ComponentHelp::GetHelpInfo")
  local nameVersion = self.context.utils:getNameVersion(componentId)
  assert(self.helpInfo ~= "", "IDL:scs/auxiliar/HelpInfoNotAvailable:1.0")
  --local f = assert( io.open(nameVersion .. ".hlp", "r"),
  --          "IDL:HelpInfoNotAvailable")
  --local string ret = f:read("*all")
  --f:close()
  Log:info(self.componentName .. "::ComponentHelp::GetHelpInfo : Finished.")
  return self.helpInfo
end

