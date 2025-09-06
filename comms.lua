local turtleID = 0
peripheral.find("modem", rednet.open)
local emptyCoords = vector.new(0, 0, 0)
local serverCoords = vector.new(gps.locate())

if serverCoords:equals(emptyCoords) then
    serverCoords = vector.new(GPS.noGPS("xyz"))
end

local function pingTurtles()
    local dist = {}

    rednet.broadcast("ping","ping")
    while true do
        local id, msg = rednet.receive("ping", St.pingTimeOut)
        if id then
            local coords = vector.new(table.unpack(textutils.unserialize(msg)))
            dist[id] = serverCoords:sub(coords)
        else
            break
        end
    end
    turtleID = Lt.getKeyForValue(math.max(table.unpack(dist)))
end

local function sendCmd(cmd)
    local id, msg = rednet.send("cmd")
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