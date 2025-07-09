local crypt = f.loadfile("lib/cryptographie.lua")()
--crypt.slave.init()
local entd = component.os_entdetector
local turret = component.os_energyturret
local autorise = { "" }

if entd == nil then
    error("Entity Detector component not found.")
end

turret.powerOn()
turret.extendShaft(2)
turret.setArmed(true)

local function contient(liste, valeur)
    for _, v in ipairs(liste) do
        if v == valeur then
            return true
        end
    end
    return false
end

local cible = nil


while true do
    entd.scanPlayers(64)
    local cibleTemp = nil
    local event
    repeat
        event = table.pack(computer.pullSignal(0.05))
        if event[1] == 'entityDetect' then
            local name, distance, x, y, z = table.unpack(event, 3, 7)
            y = y - 0.5
            if not contient(autorise, name) then
                if not cibleTemp or distance < cibleTemp.distance then
                    cibleTemp = { x = x, y = y, z = z, distance = distance }
                end
            end
        end
    until not event[1] or event[1] ~= 'entityDetect'
    cible = cibleTemp -- Met à jour la cible (ou nil si aucune)

    if cible then
        local azimuth = math.atan2(cible.x, -cible.z)
        local elevation = math.atan2(cible.y, cible.distance)
        turret.moveToRadians(azimuth, elevation)
        if turret.isReady() then
            turret.fire()
        end
        cible = nil -- On réinitialise pour la prochaine cible
    end
end
