local crypt = f.loadfile("lib/cryptographie.lua")().master
local console = f.loadfile("lib/console.lua")()
print = console.print
local autorised = {["name"]= {}, ["uuid"] = {}}
local pin = "a"

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

function modem_handler.get_pin(d)
    crypt.send(d[1], "set_pin", pin)
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
    print("send_to <role> [<arg1> <arg2> ... <argn>] : encode and send data to all slave with the given role")
    print("add <name> : add a name to the list of authorized users")
    print("pin <pin> : set the pin to use with the keypad, must be between 4 and 8 characters")
    print("flash : flashes GML Drone BIOS data to an eeprom")
end

function command_handler.send_to(d)
    local res, err = crypt.send_to_role(d[1], "log", table.unpack(table.move(d, 2, #d, 1, {})))
    if res then print("sent !")
    else print(err) end
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

function command_handler.flash(d)
    if not component.os_cardwriter then 
        print("Put an empty eeprom in the conputer")
        print("Press any key to continue")
        e.pull("key_down")
        if component.eeprom then 
            print("flashing !")
            component.eeprom.set(f.readfile("bin/drone/bios.lua"))
            component.eeprom.setLabel("GML Slave BIOS")
            component.eeprom.makeReadonly(component.eeprom.getChecksum())
            print("done !")
        else 
            print("no eeprom aborting !")
        end 
    else 
        print("Put an empty eeprom in the card writer")
        print("Press any key to continue")
        e.pull("key_down")
        print("flashing !")
        local res, err = component.os_cardwriter.flash(f.readfile("bin/drone/bios.lua"), "GML Slave BIOS", true)
        if not res then 
            print("ERROR :" .. err)
            print("aborting !")
        else 
            print("done !")
        end
    end
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
    
    component.os_cardwriter.write(player_uuid, name, true, 7)

    autorised[player_uuid] = true
    autorised[name] = true
    print("added " .. name .. " to the list of authorized users")

    autorised.name[name] = true
    autorised.uuid[player_uuid] = true
    crypt.broadcast("set_list", autorised.name, autorised.uuid)
end

function command_handler.pin(d)
    if #d < 1 then
        print("set_pin : missing pin")
        return
    end

    if #d[1] < 4 or #d[1] > 8 then
        print("set_pin : pin must be between 4 and 8 characters")
        return
    end
    pin = d[1]
    crypt.send_to_role("door","set_pin", pin)
    print("pin set to " .. pin)
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