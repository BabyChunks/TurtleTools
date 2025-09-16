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

local function getServerCoords()
    return serverCoords
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
        rednet.send(turtleID, textutils.serialize(cmd))
    end
end

local function getStatus(status)
    --three types of status: "turtle", "task" and "console"
    local id, msg = rednet.receive("status")
    if id == turtleID then
        if msg.head == "console" then
            Gt.drawConsole(msg.body[1])
            if msg.body[2] then
                sendCmd(io.read())
            end
        elseif msg.head == "turtle" then
            Gt.drawTurtleStatus(turtleID, msg.body[1])
        end
    end
end

return {
    getTurtleID = getTurtleID,
    setTurtleID = setTurtleID,
    getServerCoords = getServerCoords,
    pingTurtles = pingTurtles,
    sendCmd = sendCmd,
    getStatus = getStatus
}