local crypt = f.loadfile("lib/cryptographie.lua")().slave
local console = f.loadfile("lib/console.lua")()

--crypt.init("drone")

_osname = _osname.. " - Drone Manager"

local tunnel = component.tunnel
tunnel.send("WAKEUP")
sleep(0.5)

local waypoint = component.waypoint

if waypoint then  
    waypoint.setLabel(string.sub(tunnel.getChannel(), 1, 8))
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
            print(table.move(args, 5, #args, 1, {}))
        else
            local res,err = crypt.receive(args, modem_handler)
            if not res then print(err) end
        end
    end
end

console.loop(handler)