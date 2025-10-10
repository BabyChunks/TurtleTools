local turtleID = nil

while true do
    peripheral.find("modem", rednet.open)
    if not rednet.isOpen() then
        Gt.drawConsole("Could not find modem on computer. Place a wireless modem on the computer and press Enter to conitnue", true)
        _ = io.read()
    else break
    end
end

local serverCoords = vector.new(GPS.locate())

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
        local id, msg = rednet.receive("ping", St.pingTimeOut.value)
        if id then
            if msg[1] == "pong" then
                local turtleCoords = vector.new(table.unpack(msg[2]))
                print("msg received: "..textutils.serialize(msg))
                _ = io.read()
                print("msg[2]: "..textutils.serialize(msg[2]))
                _ = io.read()
                print("turtleCoords: "..textutils.serialize(turtleCoords))
                _ = io.read()
                print("serverCoords: "..textutils.serialize(serverCoords))
                _ = io.read()
                dist[id] = serverCoords:sub(turtleCoords):length()
                print("new distance added for #"..id..": "..dist[id])
                print("dist: "..textutils.serialize(dist))
                _ = io.read()
            end
        else
            break
        end
    end
   
    local n = Lt.len(dist)

    if n > 0  then
        turtleID = Lt.getKeyForValue(math.min(table.unpack(dist)))
        Gt.drawConsole("Connected to turtle with ID "..turtleID)
        rednet.send(turtleID, {"ack"}, "ping")
    else
        Gt.drawConsole("repinging...")
        pingTurtles()
    end
end

local function sendCmd(cmd)
    if turtleID then
        rednet.send(turtleID, textutils.serialize(cmd))
    end
end

local function getStatus()
    --three types of status: "turtle", "task" and "console"
    local id, msg = rednet.receive("status")
    if id == turtleID then
        if msg.head == "console" then
            Gt.drawConsole(msg.body[1])
            if msg.body[2] then
                sendCmd(io.read())
            end
        elseif msg.head == "turtle" then
            Gt.drawTurtleStatus(turtleID)
        elseif msg.head == "task" then
            Gt.drawTaskStatus(msg.body[1], msg.body[2], msg.body[3])
            if msg.body[1] == 1 then
                Gt.drawConsole("Task complete! Press Enter to continue", true)
                _ = io.read()
                return true
            end
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