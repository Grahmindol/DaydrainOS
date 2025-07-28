local d = component.drone 
local t = component.tunnel
local n = component.navigation

d.setStatusText("hello world")

while not astar.go_to_waypoint(string.sub(t.getChannel(), 1, 8)) do 
    d.setStatusText("going to home")
end

d.setStatusText("waiting")

local in_farm = false

function handler(e,args)
    if e == "farm" then 
        while not astar.go_to_waypoint("farm") do 
            d.setStatusText("going to farm")
        end
        in_farm = true 
        d.setStatusText("farming")
    elseif e == "home" then 
        while not astar.go_to_waypoint(string.sub(t.getChannel(), 1, 8)) do 
            d.setStatusText("going to home")
        end
        in_farm = false 
        d.setStatusText("waiting")
    end
end

loop(handler)