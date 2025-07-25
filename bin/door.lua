local crypt = f.loadfile("lib/cryptographie.lua")().slave
local console = f.loadfile("lib/console.lua")()

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
setmetatable(
    modem_handler,
    {
        __index = function()
            return function()
            end
        end
    }
)

function modem_handler.set_list(d)
    autorised = d[2]
end

function modem_handler.set_pin(d)
    pin = d[1]
end

--+-+-+-+-+ Door Logic +-+-+-+-+--

if keypad then
    keypad.setDisplay("...", 7)
    keypad.setKey({"1", "2", "3", "4", "5", "6", "7", "8", "9", "<", "0", ">"}, {7, 7, 7, 7, 7, 7, 7, 7, 7, 4, 7, 2})
    crypt.send("get_pin", "pin ?")
end

local function open()
    print("opening door...")
    if lift then
        local floor = lift.getFloorYValue(lift.getFloor())
        lift.callYValue(floor)
        while lift.getYValue() ~= floor do sleep(0.4) end
    end
    if doorCtrl then
        doorCtrl.open()
    end
    if rolldoor then
        rolldoor.open()
    end
end


local function close()
    print("closing door...")
    if doorCtrl then
        doorCtrl.close()
    end
    if rolldoor then
        rolldoor.close()
    end
    if lift then
        lift.callFloor((lift.getFloor() + 64) % 128)
    end
end
close()

local function updateDisplay()
    if keypad then
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
        open()
    else
        keypad.setDisplay("denied", 4)
        print("access denied with bad pin :".. keypadInput)
    end
    sleep(2)
    keypadInput = ""
    updateDisplay()
    close()
end

--+-+-+-+-+ Main Loop +-+-+-+-+--

function handler(e, args)
    if e == "keypad" then
        if args[2] == 10 then -- backspace
            keypadInput = keypadInput:sub(1, -2)
            updateDisplay()
        elseif args[2] == 12 then -- enter
            checkPin()
        else
            keypadInput = keypadInput .. args[3]
            updateDisplay()
        end
    elseif e == "bioReader" then
        player_uuid = args[2]
    elseif e == "magData" then
        player_uuid = args[3]
    elseif e == "rfidData" then
        player_uuid = args[4]
    elseif e == "modem_message" then
        crypt.receive(args, modem_handler)
    end

    if RFID then
        RFID.scan(2)
    end

    if player_uuid and autorised[player_uuid] then
        open()
        player_uuid = nil
        sleep(2)
        close()
    end
end

console.loop(handler)
