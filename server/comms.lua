-- Library for communication between server and turtle --

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

-- return current turtle's ID
local function getTurtleID()
    return turtleID
end

-- set current turtle's ID
local function setTurtleID(id)
    turtleID = id
end

-- return server's position
local function getServerCoords()
    return serverCoords
end

-- ping nearby turtles and link with closest one
local function pingTurtles()
    -- send ping and listen for incoming pongs
    rednet.broadcast({"ping"},"ping")
    local closest = math.huge
    while true do
        local id, msg = rednet.receive("ping", St.pingTimeOut.value)
        if id then
            if msg[1] == "pong" then
                local dist = serverCoords:sub(vector.new(table.unpack(msg[2]))):length()

                if dist < closest then
                    closest = dist
                    turtleID = id
                end
            end
        else
            break
        end
    end

    -- get length of list to check if at least one turtle pinged back

    if closest ~= math.huge  then
        --find ID for turtle closest to server and send a "get linked" message

        Gt.drawConsole("Connected to turtle with ID "..turtleID)
        rednet.send(turtleID, {"ack"}, "ping")
    else
        -- if no turtle pinged back, prompt for retry
        while true do
            Gt.drawConsole("Ping request timed out. Send a new ping?(y/n)", true)
            local ans = io.read()
            if ans == "n" or ans == "N" then
                return
            elseif ans == "y" or ans == "Y" then
                pingTurtles()
                break
            end
        end
    end
end

--send command to turtle following "cmd" protocol standards
local function sendCmd(cmd)
    if turtleID then
        rednet.send(turtleID, textutils.serialize(cmd), "cmd")
    end
end

--wait for status from turtle
local function getStatus()
    --three types of status: "turtle", "task" and "console"
    local id, msg = rednet.receive("status")
    if id == turtleID then
        -- "console" status writes to console window
        if msg.head == "console" then
            Gt.drawConsole(msg.body[1])
            if msg.body[2] then
                sendCmd(io.read())
            end
        -- "turtle" status writes to turtleID window
        elseif msg.head == "turtle" then
            Gt.drawTurtleStatus(turtleID)
        -- "task" status writes to task completion window
        elseif msg.head == "task" then
            Gt.drawTaskStatus(msg.body[1], msg.body[2], msg.body[3])
            --if task is 100% at completion, return status
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