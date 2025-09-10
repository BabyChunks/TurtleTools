local turtleID = nil
peripheral.find("modem", rednet.open)
local emptyCoords = vector.new(0, 0, 0)
local serverCoords = vector.new(gps.locate())

if serverCoords:equals(emptyCoords) then
    serverCoords = vector.new(GPS.noGPS("xyz"))
end

local function getTurtleID()
    return turtleID
end

local function setTurtleID(id)
    turtleID = id
end

local function pingTurtles()
    local dist = {}

    rednet.broadcast({"ping"},"ping")
    while true do
        local id, msg = rednet.receive("ping", St.pingTimeOut)
        if id then
            if msg[1] == "pong" then
                local turtleCoords = vector.new(table.unpack(textutils.unserialize(msg)))
                dist[id] = (serverCoords:sub(turtleCoords)):length()
            end
        else
            break
        end
    end
    turtleID = Lt.getKeyForValue(math.max(table.unpack(dist)))
    Gt.drawConsole("Connected to turtle with ID "..turtleID)
    rednet.send(turtleID, {"ack"}, "ping")
end

local function sendCmd(cmd)
    if turtleID then
        --Gt.drawText(text, monitor, pos, nL, txtColour, bkgColour)
    end
end

local function getStatus(status)
    --three types of status: "turtle", "task" and "console"
end

return {
    getTurtleID = getTurtleID,
    setTurtleID = setTurtleID,
    pingTurtles = pingTurtles,
    sendCmd = sendCmd,
    getStatus = getStatus
}