_osname = 'Daydrain OS'
_osversion = '0.0.1'

-- ========== INIT START ========== --
--+-+-+-+-+ Require +-+-+-+-+--
function require(pkg)
  if type(pkg) ~= 'string' then return nil end
  return _ENV[pkg] or _G[pkg]
end
--+-+-+-+-+ Component +-+-+-+-+--
setmetatable(component, { __index = function(_, k) return component.getPrimary(k) end })
fsaddr = component.invoke(component.list("eeprom")(), "getData")
local _component_primaries = {}
_component_primaries['filesystem'] = component.proxy(fsaddr)
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

--+-+-+-+-+ Filesystem +-+-+-+-+--
f = {
  addr = fsaddr,
  setBootAddress = function(addr) f.addr = addr end,
  open = component.filesystem.open,
  read = function(handle) return component.filesystem.read(handle, math.huge) end,
  write = component.filesystem.write,
  close = component.filesystem.close,
  list = function(dir) return component.filesystem.list(dir or '/') end,
  mkdir = component.filesystem.makeDirectory,
  rename = component.filesystem.rename,
  remove = component.filesystem.remove,
  readfile = function(file)
    local hdl, err = f.open(file, 'r')
    if not hdl then error(err) end
    local buffer = ''
    repeat
      local data, err_read = f.read(hdl)
      if not data and err_read then error(err_read) end
      buffer = buffer .. (data or '')
    until not data
    f.close(hdl)
    return buffer
  end,
  loadfile = function(file) return load(f.readfile(file), '=' .. file) end,
  runfile = function(file, argc, args)
    local prog, err = f.loadfile(file .. ".lua")
    if prog then
      local res = table.pack(xpcall(prog, function(...) return debug.traceback() end, argc, args))
      if res[1] then
        return table.unpack(res, 2, res.n)
      else
        error(res[2])
      end
    else
      error(err)
    end
  end,
}
f.load = f.loadfile
f.run = f.runfile
--+-+-+-+-+ Event +-+-+-+-+--
local function b(c,...)
    local d=table.pack(...)
    if c==nil and d.n==0 then
        return nil
    end
    return function(...)
        local e=table.pack(...)
        if c and not(type(e[1])=="string"and e[1]:match(c))then
            return false
        end
        for f=1,d.n do
            if d[f]~=nil and d[f]~=e[f+1]then
                return false end
        end
        return true
    end
end

e={
    pull = function(...)
        local g=table.pack(...)
        if type(g[1])=="string"then
            return e.pullFiltered(b(...))
        else
            checkArg(1,g[1],"number","nil")
            checkArg(2,g[2],"string","nil")
            return e.pullFiltered(g[1],b(select(2,...)))
        end
    end,

    pullFiltered = function(...)
        local g=table.pack(...)
        local h,d=math.huge
        if type(g[1])=="function"then
            d=g[1]
        else
            checkArg(1,g[1],"number","nil")
            checkArg(2,g[2],"function","nil")
            h=g[1]
            d=g[2]
        end
        repeat
            local f=table.pack(computer.pullSignal(h))
            if f.n>0 then
                if not(h or d)or d==nil or d(table.unpack(f,1,f.n))then
                    return table.unpack(f,1,f.n)
                end
            end
        until f.n==0
    end,

}
--+-+-+-+-+ Error +-+-+-+-+--
std_error = error
function error(msg)
  local hdl, errf = f.open('error_log.txt', 'w')
  if hdl then
    f.write(hdl, msg .. '\n')
  end
  f.close(hdl)
  if component.list('gpu')() and component.list('screen')() then
    local gpu = component.gpu
    local screen = component.screen
    gpu.setResolution(80, 25)
    gpu.fill(1, 1, 80, 25, ' ')
    gpu.setForeground(0xFF0000)
    gpu.setBackground(0x000000)

    local lines = (function(str, maxlen)
      local t = {}
      for line in str:gmatch("([^\n]*)\n?") do
        while #line > maxlen do
          local part = line:sub(1, maxlen)
          table.insert(t, part)
          line = line:sub(maxlen + 1)
        end
        if line ~= "" then
          table.insert(t, line)
        end
      end
      return t
    end)(msg, 80)
    for i, line in ipairs(lines) do
      gpu.set(1, i, line)
    end
    gpu.setForeground(0xFFFFFF)
    repeat
      local e, addr, char, code = computer.pullSignal()
    until e == 'key_down' and code == 28
    computer.shutdown(true)
  end
  
  computer.shutdown()
end

function sleep(timeout)
  checkArg(1, timeout, "number", "nil")
  local deadline = computer.uptime() + (timeout or 0)
  repeat
    computer.pullSignal(deadline - computer.uptime())
  until computer.uptime() >= deadline
end
-- ========== INIT END ========== --

if (not component.data) or (not component.modem)  or (not component.data.deserializeKey) then 
  error("Data Card III & Network Card are required !") 
end
component.modem.setWakeMessage("WAKEUP", true)

-- autorun
if  component.openlight then
    f.runfile('bin/light')
  elseif component.os_alarm then
    f.runfile('bin/alarm')
  elseif component.os_doorcontroller or component.os_rolldoorcontroller or component.lift then
    f.runfile('bin/door')
  elseif component.os_energyturret or component.os_nanofog_terminal then
    f.runfile('bin/turret')
  elseif component.openprinter then
    f.runfile('bin/printer')  
  elseif component.draconic_reactor then
    f.runfile('bin/draconic') 
  elseif component.br_reactor or component.br_turbine then
    f.runfile('bin/reactor')
  elseif component.me_interface or component.me_controller then
    f.runfile('bin/me_network')
  elseif component.tunnel then
    f.runfile('bin/drone')
  elseif component.gpu then
    f.runfile('bin/serveur') 
end


computer.shutdown()