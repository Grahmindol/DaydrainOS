local console = f.loadfile("lib/console.lua")()


print = console.print

function handler(e,args)
    if e=='input_prompt' then 
        
        print("Commande lue :")
        for k, v in pairs(args) do
            print("args[" .. k .. "] = '" .. v .. "'")
        end
    elseif e == 'modem_message' then
        
    end

end

console.loop(handler)