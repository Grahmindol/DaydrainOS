local crypt = f.loadfile("lib/cryptographie.lua")().master
local console = f.loadfile("lib/console.lua")()
print = console.print

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
    print("send <addr> [<arg1> <arg2> ... <argn>] : encode and send data")
end

function command_handler.broad(d)
    local res, err = crypt.broadcast("log", table.unpack(d))
    if res then print("sent !")
    else print(err) end
end

function command_handler.send(d)
    local res, err = crypt.send(d[1], "log", table.unpack(table.move(d, 2, #d, 1, {})))
    if res then print("sent !")
    else print(err) end
end

--+-+-+-+-+ Main loop +-+-+-+-+--

function handler(e,args)
    if e=='input_prompt' then 
        if type(args[1]) == "string" then  command_handler[args[1]](table.move(args, 2, #args, 1, {}))
        else command_handler[""](args) end
    elseif e == 'modem_message' then
        local res,err = crypt.receive(args, modem_handler)
        if not res then print(err) end
    end
end

console.loop(handler)