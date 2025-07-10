local crypt = f.loadfile("lib/cryptographie.lua")().master
local console = f.loadfile("lib/console.lua")()
print = console.print
local autorised = {["name"]= {}, ["uuid"] = {}}


--+-+-+-+-+ Modem Command +-+-+-+-+--

local modem_handler = {}
setmetatable(modem_handler, {
    __index = function() return function(d)print("unknow message :") print(d)end end
})

function modem_handler.log(d)
    print("logged : ") print(d)
end

function modem_handler.get_list(d)
    crypt.send(d[1], "set_list", autorised.name, autorised.uuid)
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
    print("add <name> : add a name to the list of authorized users")
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

function command_handler.add(d)
    if #d < 1 then
        print("add : missing name")
        return
    end

    local name = d[1]

    print("use biometric reader")

    local _, _, player_uuid = e.pullFiltered(function(e) return e == "bioReader" end)

    print(player_uuid)
    print("put a card in the writer")

    e.pullFiltered(function(e) return e == "cardInsert" end)
    
    component.os_cardwriter.write(player_uuid..name, name, true, 7)

    autorised[player_uuid] = true
    autorised[name] = true
    print("added " .. name .. " to the list of authorized users")

    autorised.name[name] = true
    autorised.uuid[player_uuid] = true
    crypt.broadcast("set_list", autorised.name, autorised.uuid)
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