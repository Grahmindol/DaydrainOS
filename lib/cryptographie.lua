local crypt = {}

component.modem.open(1)

crypt.json = f.loadfile("lib/json.lua")()

crypt.pub_key , crypt.pvt_key = component.data.generateKeyPair()


--+-+-+-+-+ General Methode +-+-+-+-+-- 

function crypt.serialize(...)
    local raw = table.pack(...); raw.n = nil
    return component.data.encode64(crypt.json.encode(raw))
end

function crypt.deserialize(data)
    return crypt.json.decode(component.data.decode64(data))
end

function crypt.sign(data)
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

function crypt.encodeData(data, key)
    local iv = component.data.random(16)
    local encrypted = component.data.encrypt(data, key, iv)
    return encrypted .. iv -- On colle IV à la fin pour le récupérer facilement
end

function crypt.decodeData(data, key)
    local len = #data
    local iv = data:sub(len - 15, len)
    local ciphertext = data:sub(1, len - 16)
    return component.data.decrypt(ciphertext, key, iv)
end

--+-+-+-+-+ Slave method +-+-+-+-+--
crypt.slave = {}

function crypt.slave.init()
    local data = crypt.serialize("sign_up", crypt.pub_key.serialize())
    local hash , sig = crypt.sign(data)
    component.modem.broadcast(1, data , hash , sig)
    local evt
    while true do 
        evt = table.pack(computer.pullSignal(0.4))
        if evt then
            data = crypt.deserialize(evt[6])
            if data[1] == "pub_key" then break; end 
        end
    end
    local key, err = component.data.deserializeKey(data[2], "ec-public")
    if not key then error("ERROR :".. err) end
    crypt.master_addr = evt[3]
    crypt.master_pub_key = key
    crypt.secret_key = component.data.sha256(component.data.ecdh(crypt.pvt_key, key)):sub(1, 16)
end

function crypt.slave.send(...)
    local pack = crypt.serialize(...)
    local data = crypt.encodeData(pack, crypt.secret_key)
    local hash , sig = crypt.sign(data)
    component.modem.send(crypt.master_addr, 1, data, hash, sig, true)
end

function crypt.slave.broadcast(...)
    local data = crypt.serialize(...)
    local hash , sig = crypt.sign(data)
    component.modem.broadcast(1, data, hash, sig)
end

function crypt.slave.receive(args, handler)
    if args[2] ~= crypt.master_addr then return nil , "not a master message" end
    local trusted , err =  crypt.verify(args[5], args[6], args[7], crypt.master_pub_key)  
    if not trusted then return nil , err end
    
    local data
    if args[8] then 
        data = crypt.decodeData(args[5], crypt.secret_key)
    else 
        data = args[5] 
    end
    local cmd = crypt.deserialize(data)

    if type(cmd[1]) == "string" then 
        local param = table.move(cmd, 2, #cmd, 1, {})
        handler[cmd[1]](param)
    else 
        handler[""](table.move(cmd, 1, #cmd, 2, {args[2]})) 
    end 

    return true
end

--+-+-+-+-+ Master method +-+-+-+-+--

crypt.master = {}


crypt.master.slave_keys = {}
setmetatable(crypt.master.slave_keys, {
  __index = function(t, key)
    for k, v in pairs(t) do
      if k:sub(1, #key) == key then
        return v
      end
    end
    return nil -- si pas trouvé
  end
})

function crypt.master.init()

end

function crypt.master.send(addr, ...)
    local keys = crypt.master.slave_keys[addr]
    if not keys then return false, "unknow slave" end
    local pack = crypt.serialize(...)
    local data = crypt.encodeData(pack, keys.secret)
    local hash , sig = crypt.sign(data)
    component.modem.send(keys.full_addr, 1, data, hash, sig, true)
    return true
end

function crypt.master.broadcast(...)
    local data = crypt.serialize(...)
    local hash , sig = crypt.sign(data)
    component.modem.broadcast(1, data, hash, sig)
end

function crypt.master.register_slave(addr, serialized_key)
    local key, err = component.data.deserializeKey(serialized_key, "ec-public")
    if not key then return nil, err end
    local shared = component.data.sha256(component.data.ecdh(crypt.pvt_key, key)):sub(1, 16)
    crypt.master.slave_keys[addr] = {["secret"] = shared, ["pub_key"] = key, ["full_addr"] = addr}
    local data = crypt.serialize("pub_key", crypt.pub_key.serialize())
    local hash , sig = crypt.sign(data)
    component.modem.send(addr, 1, data , hash , sig)
    return nil, "new slave :" .. addr -- it's not an error but with it we can log
end

function crypt.master.receive(args, handler)
    local keys = crypt.master.slave_keys[args[2]]
    if not keys then -- it-s very dangerous  
        local cmd = crypt.deserialize(args[5])
        if cmd[1] == "sign_up" then 
            return crypt.master.register_slave(args[2], cmd[2])
        end
        return nil, "unauth message !"
    end

    local trusted , err =  crypt.verify(args[5], args[6], args[7], keys.pub_key)  
    if not trusted then return nil , err end
    
    local data
    if args[8] then 
        data = crypt.decodeData(args[5], keys.secret)
    else 
        data = args[5] 
    end
    local cmd = crypt.deserialize(data)

    if type(cmd[1]) == "string" then 
        local param = table.move(cmd, 2, #cmd, 1, {})
        handler[cmd[1]](param)
    else 
        handler[""](table.move(cmd, 1, #cmd, 2, {args[2]})) 
    end 

    return true
end

return crypt