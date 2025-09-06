local turtleID = 0
peripheral.find("modem", rednet.open)
local emptyCoords = {nil, nil, nil}
local serverCoords = {gps.locate()}

if serverCoords == emptyCoords then
    serverCoords = GPS.noGPS()
end

local function pingTurtles()
    local coords = {}

    rednet.broadcast("ping","ping")
    while true do
        local id, msg = rednet.receive("ping", St.pingTimeOut)
        if id then
           coords[id] = vector.new(table.unpack(textutils.unserialize(msg)))
        else
            break
        end
    end
end

local function sendCmd()
    local id, msg = rednet.receive("cmd")
    if id == serverID then
        return textutils.serialize(msg)
    end
end

local function getStatus(status)

end

return {
    pingTurtles = pingTurtles,
    sendCmd = sendCmd,
    getStatus = getStatus
}