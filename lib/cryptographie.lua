local crypt = {}

-- TO DO LIST
-- man-in-the-middle au moment de l’init (crypt.slave.init()).
-- gestion d’expiration / renouvellement de clés
-- protection anti-spam

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
    local time = string.format("%016X", math.floor(10 * os.time()))
    local hash = component.data.sha256(data..time)
    local sig = component.data.ecdsa(hash, crypt.pvt_key)
    return hash , sig, time
end

function crypt.verify(data, hash, sig, time, pub_key, last_time) 
    if time <= last_time then
        return false, "Time invalide"
    end 
    if hash ~= component.data.sha256(data..time) then
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
    local hash , sig, time = crypt.sign(data)
    component.modem.broadcast(1, data , hash , sig, time)
    local evt
    while true do 
        evt = table.pack(computer.pullSignal(0.4))
        if evt.n > 0 then
            data, err = crypt.deserialize(evt[6])
            if data and data[1] == "pub_key" then break; 
            else error(err) end 
        end
    end
    local key, err = component.data.deserializeKey(data[2], "ec-public")
    if not key then error("ERROR :".. err) end
    crypt.master_addr = evt[3]
    crypt.master_pub_key = key
    crypt.master_last_time = ""
    crypt.secret_key = component.data.sha256(component.data.ecdh(crypt.pvt_key, key)):sub(1, 16)
end

function crypt.slave.send(...)
    local pack = crypt.serialize(...)
    local data = crypt.encodeData(pack, crypt.secret_key)
    local hash , sig, time = crypt.sign(data)
    return component.modem.send(crypt.master_addr, 1, data, hash, sig, time, true)
end                                   

function crypt.slave.broadcast(...)
    local data = crypt.serialize(...)
    local hash , sig, time = crypt.sign(data)
    return component.modem.broadcast(1, data, hash, sig, time)
end

function crypt.slave.receive(args, handler)
    if args[2] ~= crypt.master_addr then return nil , "not a master message" end
    local trusted , err =  crypt.verify(args[5], args[6], args[7], args[8], crypt.master_pub_key, crypt.master_last_time)  
    if not trusted then return nil , err end
    crypt.master_last_time = args[8]
    local data
    if args[9] then 
        data = crypt.decodeData(args[5], crypt.secret_key)
    else 
        data = args[5] 
    end
    local cmd, err = crypt.deserialize(data)
    if not cmd then return nil, err end
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
    local hash , sig, time = crypt.sign(data)
    return component.modem.send(keys.full_addr, 1, data, hash, sig, time, true)
end

function crypt.master.broadcast(...)
    local data = crypt.serialize(...)
    local hash , sig, time = crypt.sign(data)
    return component.modem.broadcast(1, data, hash, sig, time) 
end

function crypt.master.register_slave(addr, serialized_key)
    local key, err = component.data.deserializeKey(serialized_key, "ec-public")
    if not key then return nil, err end
    local shared = component.data.sha256(component.data.ecdh(crypt.pvt_key, key)):sub(1, 16)
    crypt.master.slave_keys[addr] = {["secret"] = shared, ["pub_key"] = key, ["full_addr"] = addr, ["last_time"] = ""}
    local data = crypt.serialize("pub_key", crypt.pub_key.serialize())
    local hash , sig, time = crypt.sign(data)
    component.modem.send(addr, 1, data , hash , sig, time)
    return nil, "new slave :" .. addr -- it's not an error but with it we can log
end

function crypt.master.unregister_slave(addr)
    crypt.master.slave_keys[crypt.master.slave_keys[addr].full_addr] = nil
end

function crypt.master.receive(args, handler)
    local keys = crypt.master.slave_keys[args[2]]
    if not keys then -- it-s very dangerous  
        local cmd = crypt.deserialize(args[5])
        if cmd and cmd[1] == "sign_up" then 
            return crypt.master.register_slave(args[2], cmd[2])
        end
        return nil, "unauth message !"
    end
    
    local trusted , err =  crypt.verify(args[5], args[6], args[7], args[8], keys.pub_key, keys.last_time)  
    if not trusted then return nil , err end
    keys.last_time = args[8]
    local data
    if args[9] then 
        data = crypt.decodeData(args[5], keys.secret)
    else 
        data = args[5] 
    end
    local cmd, err = crypt.deserialize(data)
    if not cmd then return nil, err end
    if type(cmd[1]) == "string" then 
        local param = table.move(cmd, 2, #cmd, 2, {args[2]})
        handler[cmd[1]](param)
    else 
        handler[""](table.move(cmd, 1, #cmd, 2, {args[2]})) 
    end 

    return true
end

return crypt