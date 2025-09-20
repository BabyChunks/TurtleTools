local serverID = nil
peripheral.find("modem", rednet.open)

local function getServerID()
    return serverID
end

local function setServerID(id)
    serverID = id
end

local function connectServer()
    while true do
        local id, msg = rednet.receive("ping", St.pingTimeOut)
        if msg then
            if msg[1] == "ping" then
                rednet.send(id, {"pong", textutils.serialize(Coords)}, "ping")
            elseif msg[1] == "ack" then
                print("Server connected at ID "..serverID)
                serverID = id
                return
            end
        end
    end
end

local function getCmd()
    local id, msg = rednet.receive("cmd")
    if id == serverID then
        return textutils.unserialize(msg)
    end
end

local function sendStatus(head, body)
    if serverID then
        rednet.send({head = head, body = body})
        if body[2] then
            return getCmd()
        end
    else
        print(head..": "..body[1])
        if body[2] then
            return io.read()
        end
    end
end

return {
    getServerID = getServerID,
    setServerID = setServerID,
    connectServer = connectServer,
    getCmd = getCmd,
    sendStatus = sendStatus
}