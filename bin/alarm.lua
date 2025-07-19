local crypt = f.loadfile("lib/cryptographie.lua")().slave
local console = f.loadfile("lib/console.lua")()

crypt.init("alarm")

_osname = _osname.. " - Alarm Manager"



--+-+-+-+-+ Modem Command +-+-+-+-+--

local modem_handler = {}
setmetatable(modem_handler, {
    __index = function() return function(d)print("unknow message :") print(d)end end
})

function modem_handler.log(d)
    print("logged : ") print(d)
end

function modem_handler.activate(d)
    local res, err
    for	a, _ in component.list("os_alarm") do
		res, err = component.invoke(a,"activate")
	end
    print("Alarm Activated !!! ")
end

function modem_handler.deactivate(d)
    for	a, _ in component.list("os_alarm") do
		component.invoke(a,"deactivate")
	end 
    print("Alarm Deactivated !!! ")
end

--+-+-+-+-+ Shell Command +-+-+-+-+--

local command_handler = {}
setmetatable(command_handler, {
    __index = function(_,k) return function()print("unknow command ".. k) command_handler.help() end end
})

function command_handler.help(d)
    print("help : show this page")
    print("broad [<arg1> <arg2> ... <argn>] : broadcast uncripted data")
    print("act :  activates the alarm")
    print("dact : deactivates the alarm")
end

function command_handler.broad(d)
    local res, err = crypt.broadcast("log", table.unpack(d))
    if res then print("sent !")
    else print(err) end
end

function command_handler.send(d)
    local res, err = crypt.send("log",  table.unpack(d))
    if res then print("sent !")
    else print(err) end
end

command_handler.act = modem_handler.activate
command_handler.dact = modem_handler.deactivate

function handler(e,args)
    if e=='input_prompt' then 
        if type(args[1]) == "string" then  command_handler[args[1]](table.move(args, 2, #args, 1, {}))
        else command_handler[""](args) end
    elseif e == 'modem_message' then
        crypt.receive(args, modem_handler)
    end 
end

console.loop(handler)