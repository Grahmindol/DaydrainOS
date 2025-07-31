local crypt = f.loadfile("lib/cryptographie.lua")().slave
local console = f.loadfile("lib/console.lua")()

--crypt.init("drone")

_osname = _osname.. " - Drone Manager"

local tunnel = component.tunnel
tunnel.send("WAKEUP")
sleep(0.5)

local field_queue = {}
local waypoints = {}
setmetatable(waypoints,{__call = function(t) pairs(t) end})

for addr,_ in component.list("waypoint") do 
    local waypoint = component.proxy(addr)

    if string.sub(waypoint.getLabel(),1,4) == "home" then  
        waypoint.setLabel("home-"..string.sub(tunnel.getChannel(), 1, 8))
    elseif string.sub(waypoint.getLabel(),1,5) == "field" then
        waypoint.setLabel("field-"..string.sub(addr, 1, 8))
        table.insert(field_queue,string.sub(addr, 1, 8))
    elseif string.sub(waypoint.getLabel(),1,4) == "line" then
        waypoint.setLabel("line-"..string.sub(addr, 1, 8))
        table.insert(field_queue,string.sub(addr, 1, 8))
    end

    waypoints[addr] = waypoint
end

tunnel.send(f.readfile("bin/drone/core.lua"))
tunnel.send(f.readfile("bin/drone/lua-star.lua"))


tunnel.send(f.readfile("bin/drone/crop_farmer.lua"))

--+-+-+-+-+ Main Loop +-+-+-+-+--

function handler(e,args)
    if e=='input_prompt' then 
        tunnel.send(table.unpack(args))
    elseif e == 'modem_message' then
        if args[1] == tunnel.address then
            args = table.move(args, 5, #args, 1, {})
            if args[1] == "available" then 
                local field = table.remove(field_queue)
                table.insert(field_queue,1,field)
                tunnel.send("farm",field,1)
            end
            print(args)
        else
            local res,err = crypt.receive(args, modem_handler)
            if not res then print(err) end
        end
    end
end

tunnel.send("farm",field_queue[1],1)
console.loop(handler)