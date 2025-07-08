local cryptographie = {}

cryptographie.json = f.loadfile("lib/json.lua")()

cryptographie.pub_key , cryptographie.pvt_key = component.data.generateKeyPair()
cryptographie.secret_key = ''
cryptographie.master_addr = '' -- TO DO

function cryptographie.signPayload(...)
    local raw = table.pack(...); raw.n = nil
    local data = component.data.encode64(cryptographie.json.encode(raw))
    local hash = component.data.sha256(data)
    local sig = component.data.ecdsa(hash, cryptographie.pvt_key)
    return data , hash , sig
end

function cryptographie.unsignPayload(data, hash, sig, pub_key)
    if pub_key then  
        if not component.data.ecdsa(hash, pub_key, sig) then
            error("Signature invalide")
        end
    end
    local decoded = cryptographie.json.decode(component.data.decode64(data))
    return decoded
end

return cryptographie