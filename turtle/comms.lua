local serverID = 0
peripheral.find("modem", rednet.open)

local function connectServer()
    while true do
        local id, msg = rednet.receive("ping", St.pingTimeOut)
        if msg == "ping" then
            serverID = id
            rednet.send(serverID, textutils.serialize(Coords), "ping")
        elseif msg == "pong" then
            return true
        end
    end
end

local function getCmd()
    local id, msg = rednet.receive("cmd")
    if id == serverID then
        return textutils.serialize(msg)
    end
end

local function sendStatus()

end

return {
    connectServer = connectServer,
    getCmd = getCmd
}