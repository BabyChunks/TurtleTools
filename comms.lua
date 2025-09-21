local turtleID = nil
peripheral.find("modem", rednet.open)
local emptyCoords = vector.new(0, 0, 0)
local serverCoords = vector.new(gps.locate())

if serverCoords:equals(emptyCoords) then
    serverCoords = GPS.noGPS()
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

    while true do
        rednet.broadcast({"ping"},"ping")
        print("ping sent")
        local id, msg = rednet.receive("ping", St.pingTimeOut.value)
        if id then
            print("ping received with ID "..id)
            if msg[1] == "pong" then
                print(textutils.serialize(msg[2]))
                os.sleep(2)
                local turtleCoords = textutils.unserialize(msg[2])
                print(textutils.serialize(turtleCoords))
                print(textutils.serialize(serverCoords))
                dist[id] = (serverCoords:sub(turtleCoords)):length()
                print("new distance added: "..dist[id])
            end
        else
            break
        end
    end
    print("dist length:"..#dist)
    if #dist > 0  then
        
        turtleID = Lt.getKeyForValue(math.max(table.unpack(dist)))
        Gt.drawConsole("Connected to turtle with ID "..turtleID)
        rednet.send(turtleID, {"ack"}, "ping")
    else
        print("list is empty")
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
            Gt.drawTaskStatus(msg.body[1], msg.body[2])
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