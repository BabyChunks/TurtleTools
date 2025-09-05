local turtleID = 0
peripheral.find("modem", rednet.open)

local function pingTurtles()
    local ack = true
    local coords = {}

    rednet.broadcast("ping","ping")
    while true do
        local id, msg = rednet.receive("ping", St.pingTimeOut)
        if id then
           coords[id] = textutils.unserialize(msg)
        else
            break
        end
    end

    
end

local function sendCmd()
    local id, msg = rednet.receive("cmd")
    if id == serverID then
        return textutils.unserialize(msg)
    end
end

local function getStatus(status)

end

return {
    pingTurtles = pingTurtles,
    sendCmd = sendCmd,
    getStatus = getStatus
}