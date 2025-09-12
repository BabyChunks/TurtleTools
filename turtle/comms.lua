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
        if msg[1] == "ping" then
            rednet.send(id, {"pong", Coords}, "ping")
        elseif msg[1] == "ack" then
            print("Server connected at ID "..serverID)
            serverID = id
            return
        end
    end
end

local function getCmd()
    local id, msg = rednet.receive("cmd")
    if id == serverID then
        return textutils.unserialize(msg)
    end
end

local function sendStatus(status)

end

return {
    getServerID = getServerID,
    setServerID = setServerID,
    connectServer = connectServer,
    getCmd = getCmd,
    sendStatus = sendStatus
}