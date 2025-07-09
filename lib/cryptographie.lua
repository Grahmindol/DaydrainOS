local crypt = {}

component.modem.open(1)

crypt.json = f.loadfile("lib/json.lua")()

crypt.pub_key , crypt.pvt_key = component.data.generateKeyPair()

crypt.slave = {}

function crypt.slave.init()
    local data = crypt.pack("sign_up", crypt.pub_key.serialize())
    local hash , sig = crypt.signPayload(data)
    component.modem.broadcast(1, data , hash , sig)
    local evt
    while true do 
        evt = table.pack(computer.pullSignal(0.4))
        if evt then
            data = crypt.unpack(evt[6])
            if data[1] == "pub_key" then break; end 
        end
    end
    local key, err = component.data.deserializeKey(data[2], "ec-public")
    if not key then error("ERROR :".. err) end
    crypt.master_addr = evt[3]
    crypt.secret_key = component.data.sha256(component.data.ecdh(crypt.pvt_key, key)):sub(1, 16)
end

function crypt.isUUID(str)
    return type(str) == "string"
       and str:match("^[0-9a-fA-F]{8}%-[0-9a-fA-F]{4}%-[0-9a-fA-F]{4}%-[0-9a-fA-F]{4}%-[0-9a-fA-F]{12}$") ~= nil
end

function crypt.pack(...)
    local raw = table.pack(...); raw.n = nil
    return component.data.encode64(crypt.json.encode(raw))
end

function crypt.unpack(data)
    return crypt.json.decode(component.data.decode64(data))
end

function crypt.signPayload(data)
    local hash = component.data.sha256(data)
    local sig = component.data.ecdsa(hash, crypt.pvt_key)
    return hash , sig
end

function crypt.verify(data, hash, sig, pub_key)  
    if hash ~= component.data.sha256(data) then
        return false, "Hash invalide"
    end
    if not component.data.ecdsa(hash, pub_key, sig) then
        return false, "Signature invalide"
    end
    return true, "validated"
end

return crypt