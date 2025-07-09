local crypt = f.loadfile("lib/cryptographie.lua")()
local doorCtrl = component.os_doorcontroller

local magreader = component.os_magreader
local RFID = component.os_rfidreader
local biometric = component.os_biometric
local keypad = component.os_keypad
local rolldoor = component.os_rolldoorcontroller

local autorise = {["L01cAyral"] = true,
    ["dff1eb74-719a-401c-b79e-1c2d484f0896"] = true, }
local pin = "1234"
local keypadInput = ""

if doorCtrl == nil or rolldoor == nil then
    error("Door Controller component not found.")
elseif rolldoor ~= nil then
    rolldoor.setSpeed(3)
end


if keypad ~= nil then
    keypad.setDisplay("...", 7)
    keypad.setKey({"1", "2", "3", "4", "5", "6", "7", "8", "9", "<", "0", ">"},
        {7, 7, 7, 7, 7, 7, 7, 7, 7, 4, 7, 2})
end

if doorCtrl ~= nil then
    doorCtrl.close()
end

if rolldoor ~= nil then
    rolldoor.close()
end

function updateDisplay()
    local displayString = ""
    for i = 1, #keypadInput do
        displayString = displayString .. "*"
    end
    
    keypad.setDisplay(displayString, 7)

end

function checkPin()
    if keypadInput == pin then
        keypad.setDisplay("granted", 2)
        if doorCtrl ~= nil then
            doorCtrl.open()
        end
                
        if rolldoor ~= nil then        
            rolldoor.open()
        end
        
    
    else
        keypad.setDisplay("denied", 4)
    end
    sleep(2)
    keypadInput = ""

end


while true do
    if RFID ~= nil then
        RFID.scan(3)
    end
    
    local evt = table.pack(computer.pullSignal(0.4))
    
    if evt.n > 0 then
        
        if evt[1] == 'keypad' then
            if evt[3] == 10 then --backspace
                keypadInput = keypadInput:sub(1, -2)
                updateDisplay()
            
            elseif evt[3] == 12 then --enter
                checkPin()
            
            else
                keypadInput = keypadInput .. evt[4]
            end
            
            updateDisplay()
        
        else
            local name = evt[3]
            if autorise[name] then
                if doorCtrl ~= nil then
                    doorCtrl.open()
                end
                
                if rolldoor ~= nil then
                    rolldoor.open()
                end
                sleep(2)
            end
        
        end
        
        if doorCtrl ~= nil then
            doorCtrl.close()
        end
        
        if rolldoor ~= nil then
            rolldoor.close()
        end
    
    end
end
