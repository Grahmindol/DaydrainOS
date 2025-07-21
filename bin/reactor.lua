local crypt = f.loadfile("lib/cryptographie.lua")().slave
local console = f.loadfile("lib/console.lua")()

crypt.init("reactor")

_osname = _osname .. " - Reactor Manager"

turbines = {}
reactors = {}

for a, _ in component.list("br_turbine") do
    turbines[a] = component.proxy(a)
end

for a, _ in component.list("br_reactor") do
    reactors[a] = component.proxy(a)
    reactors[a].setAllControlRodLevels(100.0)
end

--+-+-+-+-+ Modem Command +-+-+-+-+--

local modem_handler = {}
setmetatable(modem_handler,
    {
        __index = function()
            return function(d)
                print("unknow message :")
                print(d)
            end
        end
    }
)

function modem_handler.log(d)
    print("logged : ")
    print(d)
end

--+-+-+-+-+ Shell Command +-+-+-+-+--

local command_handler = {}
setmetatable(
    command_handler,
    {
        __index = function(_, k)
            return function()
                print("unknow command " .. k)
                command_handler.help()
            end
        end
    }
)

function command_handler.help(d)
    print("help : show this page")
    print("list : show the liste of reactor and turbine")
end

function command_handler.list(d)
    print("Turbines :")
    for addr, turbine in pairs(turbines) do
        local status
        if not turbine.getConnected() then
            status = " Unvalide multi-block !"
        elseif not turbine.getActive() then
            status = " Stoped..."
        elseif not turbine.getInductorEngaged() then
            status = " Accelerating..."
        else
            status = " Generating Energy"
        end
        print(addr .. " : " .. status)
    end
    print("Reactors :")
    for addr, reactor in pairs(reactors) do
        local status
        if not reactor.getConnected() then
            status = " Unvalide multi-block !"
        elseif not reactor.getActive() then
            status = " Stoped..."
        elseif reactor.isActivelyCooled() then
            status = " Generating Steam"
        else
            status = " Generating Energy"
        end
        print(addr .. " : " .. status)
    end
end

--+-+-+-+-+ Regulation Logic +-+-+-+-+--

function regulate_turbine(turbine)
    local speed = turbine.getRotorSpeed()
    turbine.setInductorEngaged(speed > 1750)
    turbine.setActive(speed < 1850)
end

function regulate_reactor(reactor)
    if reactor.isActivelyCooled() then
        local hot_amount = (reactor.getHotFluidAmount() / reactor.getHotFluidAmountMax()) * 100.0

        if hot_amount < 20 then
            for i = 0.0, reactor.getNumberOfControlRods() - 1.0, 1.0 do
                local current = reactor.getControlRodLevel(i)
                if current >= 5.0 then
                    reactor.setControlRodLevel(i, current - 1.0)
                    break
                end
            end
        elseif hot_amount > 80 then
            for i = 0.0, reactor.getNumberOfControlRods() - 1.0, 1.0 do
                local current = reactor.getControlRodLevel(i)
                if current <= 95.0 then
                    reactor.setControlRodLevel(i, current + 1.0)
                    break
                end
            end
        end
    else
        reactor.setAllControlRodLevels(0)
    end
end

--+-+-+-+-+ Main Loop +-+-+-+-+--
local i = 0

function handler(e, args)
    if e == "input_prompt" then
        if type(args[1]) == "string" then
            command_handler[args[1]](table.move(args, 2, #args, 1, {}))
        else
            command_handler[""](args)
        end
    elseif e == "modem_message" then
        crypt.receive(args, modem_handler)
    elseif e == "component_added" then
        if args[2] == "br_turbine" then
            turbines[args[1]] = component.proxy(args[1])
            print("Info: New Turbine Connected")
        elseif args[2] == "br_reactor" then
            reactors[args[1]] = component.proxy(args[1])
            print("Info: New Reactor Connected")
        end
    elseif e == "component_removed" then
        if args[2] == "br_turbine" then
            turbines[args[1]] = nil
            print("Warn: A Turbine was disconnected")
        elseif args[2] == "br_reactor" then
            reactors[args[1]] = nil
            print("Warn: A Reactor was disconnected")
        end
    end

    if i % 10 == 0 then
        for _, turbine in pairs(turbines) do
            if turbine.getConnected() then
                regulate_turbine(turbine)
            end
        end

        for _, reactor in pairs(reactors) do
            if reactor.getConnected() then
                regulate_reactor(reactor)
            end
        end
        i = 0
    end
    i = i + 1
end

console.loop(handler)
