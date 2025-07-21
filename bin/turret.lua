local crypt = f.loadfile("lib/cryptographie.lua")().slave

crypt.init("turret")

local entd = component.os_entdetector
local turret = component.os_energyturret
local nfog = component.os_nanofog_terminal

local autorised = {}

crypt.send("get_list", "liste ?")

--+-+-+-+-+ Modem Command +-+-+-+-+--

local modem_handler = {}
setmetatable(modem_handler, {
    __index = function() return function() end end
})

function modem_handler.set_list(d)
    autorised = d[1]
end

if entd == nil then
    error("Entity Detector component not found.")
end

if not (nfog or turret) then 
    error("nfog or turret component not found.")
end

if turret then
    turret.powerOn()
    turret.extendShaft(2)
    turret.setArmed(true)
end

--+-+-+-+-+ Main Loop +-+-+-+-+--

local cible = nil

while true do
    local detected = entd.scanPlayers(64)

    local evt = table.pack(e.pullFiltered(0.1,function(e) return e == "modem_message" end))
    if evt.n > 0 then
        local args = table.move(evt, 2, evt.n, 1, {})
        crypt.receive(args, modem_handler)
    end
    

    local found = false
    for _, player in ipairs(detected) do
        if not autorised[player.name] then
            if not cible then
                crypt.send("log", "Unauthorized access attempt by " .. player.name)
            end
            cible = player
            found = true
            break
        end
    end
    if not found then cible = nil end

    if cible then
        if turret then
            local azimuth = math.atan2(cible.x, -cible.z)
            local elevation = math.atan2(cible.y, cible.range)
            turret.moveToRadians(azimuth, elevation)
            if turret.isReady() then
                turret.fire()
            end
        end

        if nfog then 
            nfog.set(cible.x,cible.y,cible.z,"gold_block")
            nfog.setFilter(cible.x,cible.y,cible.z,"player", true,true)
        end
    elseif nfog then 
        nfog.resetAll()
    end
end