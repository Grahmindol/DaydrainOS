local crypt = f.loadfile("lib/cryptographie.lua")().slave
local console = f.loadfile("lib/console.lua")()

crypt.init("drone")

_osname = _osname.. " - Drone Manager"

local tunnel = component.tunnel

--+-+-+-+-+ Modem Command +-+-+-+-+--

local modem_handler = {}
setmetatable(modem_handler, {
    __index = function() return function(d)print("unknow message :") print(d)end end
})

--+-+-+-+-+ Shell Command +-+-+-+-+--

local command_handler = {}
setmetatable(command_handler, {
    __index = function(_,k) return function()print("unknow command ".. k) command_handler.help() end end
})

function command_handler.help(d)
    print("help : show this page")
end

--+-+-+-+-+ Main Loop +-+-+-+-+--

function handler(e,args)
    if e=='input_prompt' then 
        tunnel.send(table.concat(args, " "))
    elseif e == 'modem_message' then
        if args[1] == tunnel.address then
            print(args)
        else
            local res,err = crypt.receive(args, modem_handler)
            if not res then print(err) end
        end
    end
end

console.loop(handler)