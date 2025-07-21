local crypt = f.loadfile("lib/cryptographie.lua")().slave
local console = f.loadfile("lib/console.lua")()

crypt.init("reactor")


--+-+-+-+-+ Modem Command +-+-+-+-+--

local modem_handler = {}
setmetatable(modem_handler, {
    __index = function() return function(d)print("unknow message :") print(d)end end
})

function modem_handler.log(d)
    print("logged : ") print(d)
end

function modem_handler.activate(d)
    for	a, _ in component.list("os_alarm") do
		component.invoke(a,"activate")
	end
    print("Alarm Activated !!! ")
end

function modem_handler.deactivate(d)
    for	a, _ in component.list("os_alarm") do
		component.invoke(a,"deactivate")
	end 
    print("Alarm Deactivated !!! ")
end



while true do

    -- Gestion des messages modem
    local evt = table.pack(computer.pullSignal(0.1))
    if evt[1] == "modem_message" then
        local args = table.move(evt, 2, evt.n, 1, {})
        crypt.receive(args, modem_handler)
    end

    if component.reactor then
        local reactor = component.reactor
        if reactor.getReactorStatus() then
            print("Reactor is active")
            print("Energy produced: " .. reactor.getEnergyProducedLastTick() .. " RF")
            print("Temperature: " .. reactor.getTemperature() .. " K")
        else
            print("Reactor is inactive")
        end

end