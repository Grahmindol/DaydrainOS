local d = component.drone
local t = component.tunnel
local n = component.navigation

d.setStatusText("hello world")
d.setAcceleration(1)

-- Aller au point de départ (home)
while not astar.go_to_waypoint(string.sub(t.getChannel(), 1, 8)) do
    d.setStatusText("going to home")
end

d.setStatusText("waiting")

-- Coroutine de déplacement farming
local function get_traveler()
    return coroutine.wrap(function()
        local move, swing

        -- Détermine l'orientation du drone
        for side = 2, 5 do
            if d.detect(side) then
                move = ({
                    [2] = function(x, y, z) d.move(z, y, x) end,   -- -Z
                    [3] = function(x, y, z) d.move(-z, y, -x) end,  -- +Z
                    [4] = function(x, y, z) d.move(x, y, z) end,   -- -X
                    [5] = function(x, y, z) d.move(-x, y, z) end   -- +X
                })[side]
                swing = ({
                    [2] = function(s) d.swing(s > 3 and s-2 or s+2) end,   -- -Z
                    [3] = function(s) d.swing(7 - s) end,  -- +Z
                    [4] = function(s) d.swing(s) end,   -- -X
                    [5] = function(s) d.swing(s == 5 and 4 or s == 4 and 5 or s) end   -- x -> -x
                })[side]
                break
            end
        end
        
        -- Petit délai de stabilisation
        local function move_and_wait(x, y, z)
            move(x, y, z)
            while d.getOffset() > 0.1 do sleep(0.05) end
            coroutine.yield(true)
        end
        move(0,-1,-4)
        local _,y,_ = n.getPosition()
        d.move(0,math.floor(y) - y + 1.1,0)
        d.setAcceleration(0.3)
        while d.getOffset() > 0.3 do sleep(0.05) end
        swing(5) move_and_wait(1, 0, 0)  -- descente initiale

        -- Pattern de serpentin (4 lignes)
        for _ = 1, 4 do
            for _ = 1, 8 do swing(5) move_and_wait(1, 0, 0) end
            swing(3) move_and_wait(0, 0, 1)
            for _ = 1, 8 do swing(4) move_and_wait(-1, 0, 0) end
            swing(3) move_and_wait(0, 0, 1)
        end

        -- Retour au point de départ
        for _ = 1, 8 do swing(5) move_and_wait(1, 0, 0) end
        d.setAcceleration(2)
        move(-9, 0, -8)
    end)
end

local function is_inventory_ok()
    if d.count() == 1 then 
        for i = 1, d.inventorySize() do 
            if d.compareTo(i) and i ~= d.select() then
                local sel = d.select()
                d.select(i)
                d.transferTo(sel)
                d.select(sel)
                break
            end
        end 
    elseif d.count() == 0 then 
        return false
    end
    for i = 1, d.inventorySize() do 
        if d.space(i) > 0 then
            return true
        end
    end
    return false
end

-- Gestion des événements "farm" et "home"
local traveler = function()end
local is_farming = false
function handler(e, args)
    if e == "farm" then
        d.setStatusText("wait inv")
        while not is_inventory_ok() do sleep(0.05) end

        while not astar.go_to_waypoint("farm", args[2]) do
            d.setStatusText("scanning farm")
        end

        d.setStatusText("farming")
        traveler = get_traveler()
        is_farming = true
        d.select(tonumber(args[1]) or 1)

    elseif e == "home" then
        while not astar.go_to_waypoint(string.sub(t.getChannel(), 1, 8)) do
            d.setStatusText("scanning home")
        end
        d.setStatusText("waiting")
        traveler = function()end 
        is_farming = false
    end

    if is_farming then
        if not is_inventory_ok() then
            d.move(0,1,0) -- to be sure tho not be in culture
            astar.record_moves()
            
            while not astar.go_to_waypoint(string.sub(t.getChannel(), 1, 8)) do
                d.setStatusText("scanning home")
            end
            d.setStatusText("wait inv")
            while not is_inventory_ok() do sleep(0.05) end
            d.setStatusText("return farming")
            astar.rollback_moves()
            d.move(0,-1,0)
            d.setAcceleration(0.3)
            d.setStatusText("farming")
        end
        if traveler() then 
            d.place(0)      -- tente de replanter
        else
            is_farming = false
            traveler = function()end 
            t.send("farming finisht")
        end
    end
end

-- Boucle principale
loop(handler)
