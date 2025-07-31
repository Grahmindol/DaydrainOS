local t = component.proxy(component.list("tunnel")())

while true do
    local evt = {computer.pullSignal()}
    if evt[1] == "modem_message" then
        local cmd = evt[6]
        local f, err = load(cmd, "=code", "t", _G)
        if f then
            local result = {pcall(f)}
            local ok = table.remove(result, 1)
            if ok then
                t.send("result", table.unpack(result))
            else
                t.send("error", table.unpack(result))
            end
        else
            t.send("error", err)
        end
    else
        t.send("event", table.unpack(evt))
    end
end