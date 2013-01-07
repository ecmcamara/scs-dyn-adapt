local print = print
local coroutine = coroutine
local loadfile = loadfile
local assert = assert
local oop = require "loop.simple"
local protected = require "oil.kernel.base.Proxies.protected"
local oil = require "oil"
local utils     = require "scs.core.utils"

local DATA_DIR = os.getenv("OPENBUS_DATADIR")

module ("scs.util.OilUtilities", oop.class)

local utils = utils()

function existent(self, proxy)

  --recarregar timeouts de erro (para tempo ser din�mico em tempo de execu��o)
  local timeOut = assert(loadfile(DATA_DIR .."/conf/FTTimeOutConfiguration.lua"))()

  --Tempo total em caso de falha = sleep * MAX_TIMES
  local MAX_TIMES = timeOut.non_existent.MAX_TIMES
  local timeToTrie = 1
  local threadTime = timeOut.non_existent.sleep
  local parent = oil.tasks.current
  local executedOK, not_exists = nil, nil
  local thread = coroutine.create(function()
        if proxy.__manager.invoker == protected then
          executedOK, not_exists = proxy:_non_existent()
        else
          executedOK, not_exists = oil.pcall(proxy._non_existent, proxy)
        end
        oil.tasks:resume(parent)
  end)

  oil.tasks:resume(thread)
  if executedOK == nil then
    oil.tasks:suspend(threadTime*MAX_TIMES)
    if executedOK == nil then
      oil.tasks:remove(thread)
      return false, "call timeout"
    end
  end
  if executedOK and not not_exists then
    return true, true
  else
    return false, not_exists
  end
end


