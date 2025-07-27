local t = component.proxy(component.list("tunnel")())
t.setWakeMessage("WAKEUP", true)

-- ========== DRONE INIT START ========== --

--+-+-+-+-+ Component +-+-+-+-+--
setmetatable(component, { __index = function(_, k) return component.getPrimary(k) end })
local _component_primaries = {}
function component.setPrimary(dev, addr)
  for k,v in component.list() do
    if k == addr and v == dev then
      _component_primaries[dev] = component.proxy(addr)
    end
  end
end
function component.getPrimary(dev)
  if _component_primaries[dev] == nil then
    for k, v in component.list() do
      if v == dev then component.setPrimary(v,k) break end
    end
  end
  return _component_primaries[dev]
end

--+-+-+-+-+ Error +-+-+-+-+--
std_error = error
function error(...)
  t.send("error", ...)
  computer.shutdown()
end

function print(...)
  t.send("log", ...)
end

function sleep(timeout)
  checkArg(1, timeout, "number", "nil")
  local deadline = computer.uptime() + (timeout or 0)
  repeat
    computer.pullSignal(deadline - computer.uptime())
  until computer.uptime() >= deadline
end

-- ========== INIT END ========== --

function loop(handler)
    while true do
        local evt = table.pack(computer.pullSignal(0.4))
        if evt[1] == "modem_message" then
            if evt[6] == "WAKEUP" then 
                computer.shutdown(true)
            else
                handler(evt[6], table.move(evt, 7, #evt, 1, {}))
            end
        end
        handler(evt[1], table.move(evt, 2, #evt, 1, {}))
    end
end

return true