local crypt = f.loadfile("lib/cryptographie.lua")()
local console = f.loadfile("lib/console.lua")()
_osname = _osname.. " - Ligh Manager"
crypt.slave.init()


--+-+-+-+-+ Modem Command +-+-+-+-+--

local modem_handler = {}
setmetatable(modem_handler, {
    __index = function() return function(d)print("unknow message :") print(d)end end
})

function modem_handler.log(d)
    print("logged : ") print(d)
end

--+-+-+-+-+ Shell Command +-+-+-+-+--

local command_handler = {}
setmetatable(command_handler, {
    __index = function(_,k) return function()print("unknow command ".. k) command_handler.help() end end
})

function command_handler.help(d)
    print("help : show this page")
    print("broad <arg1> [<arg2> ... <argn>] : broadcast uncripted data")
end

function command_handler.broad(d)
    print("sending :")
    print(d)
    local data = crypt.pack("log", d)
    local hash , sig = crypt.signPayload(data)
    component.modem.broadcast(1, data , hash , sig)
end


function handler(e,args)
    if e=='input_prompt' then 
        if type(args[1]) == "string" then  command_handler[args[1]](table.move(args, 2, #args, 1, {}))
        else command_handler[""](args) end
    elseif e == 'modem_message' then
        data = crypt.unpack(args[5])
        if type(data[1]) == "string" then modem_handler[data[1]](table.move(data, 2, #data, 2, {args[2]}));
        else modem_handler[""](table.move(data, 1, #data, 2, {args[2]})) end
    end
end

console.loop(handler)