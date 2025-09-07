local turtleID = nil
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
        if type(msg) == "table" then
            local turtleCoords = vector.new(table.unpack(textutils.unserialize(msg)))
            dist[id] = serverCoords:sub(turtleCoords)
        else
            break
        end
    end
    turtleID = Lt.getKeyForValue(math.max(table.unpack(dist)))
end

local function sendCmd(cmd)
    if not turtleID then
        --Gt.drawText(text, monitor, pos, nL, txtColour, bkgColour)
    end
end

local function getStatus(status)
    --three types of status: "turtle", "task" and "console"
end

return {
    pingTurtles = pingTurtles,
    sendCmd = sendCmd,
    getStatus = getStatus
}