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
    print("broad [<arg1> <arg2> ... <argn>] : broadcast uncripted data")
    print("send [<arg1>  <arg2> ... <argn>] : send an encoded message to the master")
end

function command_handler.broad(d)
    print("sending :")
    print(d)
    crypt.slave.broadcast("log", d)
end

function command_handler.send(d)
    local res, err = crypt.slave.send("log", d)
    if res then print("sent !")
    else print(err) end
end


function handler(e,args)
    if e=='input_prompt' then 
        if type(args[1]) == "string" then  command_handler[args[1]](table.move(args, 2, #args, 1, {}))
        else command_handler[""](args) end
    elseif e == 'modem_message' then
        crypt.slave.receive(args, modem_handler)
    end
end

console.loop(handler)