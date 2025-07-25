local crypt = f.loadfile("lib/cryptographie.lua")().slave

crypt.init("door")

_osname = _osname .. " - Door Manager"

local doorCtrl = component.os_doorcontroller
local rolldoor = component.os_rolldoorcontroller
local magreader = component.os_magreader
local RFID = component.os_rfidreader
local biometric = component.os_biometric
local keypad = component.os_keypad
local lift = component.lift

local autorised = {}
local pin = "mots de passe non tapable sur le keypad"
local keypadInput = ""
local player_uuid

crypt.send("get_list", "liste ?")

--+-+-+-+-+ Modem Command +-+-+-+-+--

local modem_handler = {}
setmetatable(modem_handler, {
    __index = function() return function() end end
})

function modem_handler.set_list(d)
    autorised = d[2]
end

function modem_handler.set_pin(d)
    pin = d[1]
end

--+-+-+-+-+ Door Logic +-+-+-+-+--

if keypad then
    keypad.setDisplay("...", 7)
    keypad.setKey({"1", "2", "3", "4", "5", "6", "7", "8", "9", "<", "0", ">"},
        {7, 7, 7, 7, 7, 7, 7, 7, 7, 4, 7, 2})
    crypt.send("get_pin", "pin ?")
end

if doorCtrl then
    doorCtrl.close()
end

if rolldoor then
    rolldoor.setSpeed(3)
    rolldoor.close()
end

local function updateDisplay()
    if keypad  then
        local displayString = ""
        for i = 1, #keypadInput do
            displayString = displayString .. "*"
        end
        keypad.setDisplay(displayString, 7)
    end
end

local function checkPin()
    if keypadInput == pin then
        keypad.setDisplay("granted", 2)
        if doorCtrl then
            doorCtrl.open()
        end
        if rolldoor then
            rolldoor.open()
        end
        if lift then
            lift.callFloor(lift.getFloor())
            sleep(3)
        end
    else
        keypad.setDisplay("denied", 4)
    end
    sleep(2)
    keypadInput = ""
    updateDisplay()
    if doorCtrl then
        doorCtrl.close()
    end
    if rolldoor then
        rolldoor.close()
    end
    if lift then
        lift.callFloor((lift.getFloor()+64)%128)
    end
end

--+-+-+-+-+ Main Loop +-+-+-+-+--

while true do
    if RFID then
        RFID.scan(2)
    end

    local evt = table.pack(computer.pullSignal(0.4))

    if evt.n > 0 then
        if evt[1] == 'keypad' then
            if evt[3] == 10 then -- backspace
                keypadInput = keypadInput:sub(1, -2)
                updateDisplay()
            elseif evt[3] == 12 then -- enter
                checkPin()
            else
                keypadInput = keypadInput .. evt[4]
                updateDisplay()
            end
        elseif evt[1] == 'bioReader' then
            player_uuid = evt[3]
        elseif evt[1] == 'magData' then
            player_uuid = evt[4]
        elseif evt[1] == 'rfidData' then
            player_uuid = evt[5]
        elseif evt[1] == 'modem_message' then
            local args = table.move(evt, 2, evt.n, 1, {})
            crypt.receive(args, modem_handler)
        end

        if autorised[player_uuid] then
            if doorCtrl then
                doorCtrl.open()
            end
            if rolldoor then
                rolldoor.open()
            end
            if lift then
                lift.callFloor(lift.getFloor())
                sleep(3)
            end
            player_uuid = nil
            sleep(2)
            if doorCtrl then
                doorCtrl.close()
            end
            if rolldoor then
                rolldoor.close()
            end
            if lift then
                lift.callFloor((lift.getFloor()+64)%128)
            end
        end
    end
end
