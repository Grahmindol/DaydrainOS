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
        local move

        -- Détermine l'orientation du drone
        for side = 2, 5 do
            if d.detect(side) then
                move = ({
                    [2] = function(x, y, z) d.move(z, y, x) end,   -- -Z
                    [3] = function(x, y, z) d.move(-z, y, x) end,  -- +Z
                    [4] = function(x, y, z) d.move(x, y, z) end,   -- -X
                    [5] = function(x, y, z) d.move(-x, y, z) end   -- +X
                })[side]
                break
            end
        end

        d.setAcceleration(0.5)
        
        -- Petit délai de stabilisation
        local function move_and_wait(x, y, z)
            move(x, y, z)
            while d.getOffset() > 0.3 do sleep(0.05) end
            coroutine.yield(true)
        end

        move_and_wait(1, 0, -4)  -- descente initiale

        -- Pattern de serpentin (4 lignes)
        for _ = 1, 4 do
            for _ = 1, 8 do move_and_wait(1, 0, 0) end
            move_and_wait(0, 0, 1)
            for _ = 1, 8 do move_and_wait(-1, 0, 0) end
            move_and_wait(0, 0, 1)
        end

        -- Retour au point de départ
        for _ = 1, 8 do move_and_wait(1, 0, 0) end
        move_and_wait(-8, 0, -8)
    end)
end

-- Gestion des événements "farm" et "home"
local traveler = function()end
function handler(e, args)
    if e == "farm" then
        while not astar.go_to_waypoint("farm", args[2]) do
            d.setStatusText("scanning farm")
        end

        d.setStatusText("farming")
        traveler = get_traveler()
        d.select(tonumber(args[1]) or 1)

    elseif e == "home" then
        while not astar.go_to_waypoint(string.sub(t.getChannel(), 1, 8)) do
            d.setStatusText("scanning home")
        end
        d.setStatusText("waiting")
        traveler = function()end 
    end

    if traveler() then 
        d.place(0)      -- tente de replanter
    else 
        traveler = function()end 
    end
end

-- Boucle principale
loop(handler)
