-- ping nearby turtles and link with closest one
local function pingTurtles()
    -- send ping and listen for incoming pongs
    rednet.broadcast({"ping"},"ping")
    --local closest = math.huge
    local turtles = {}
    while true do
        local id, msg = rednet.receive("ping", St.pingTimeOut.value)
        if id then
            if msg[1] == "pong" then
                local dist = ServerCoords:sub(vector.new(table.unpack(msg[2]))):length()
                table.insert(turtles, id, dist)
            end
        else
            break
        end
    end

    --find ID for turtle closest to server and send a "get linked" message
    table.sort(turtles, function(a, b) return turtles[a] > turtles[b] end)
    TurtleID = next(turtles)
    if TurtleID then
        GUI.drawConsole("Connected to turtle with ID "..TurtleID)
        GUI.drawTurtleStatus()
        rednet.send(TurtleID, {"ack"}, "ping")
    else
        -- if no turtle pinged back, prompt for retry
        while true do
            GUI.drawConsole("Ping request timed out. Send a new ping?(y/n)", true)
            local ans = string.lower(io.read())
            if ans == "n" then return true
            elseif ans == "y" then
                pingTurtles()
                break
            end
        end
    end
end

--send command to turtle following "cmd" protocol standards
local function sendCmd(cmd)
    if TurtleID then
        rednet.send(TurtleID, textutils.serialize(cmd), "cmd")
    end
end

--wait for status from turtle
local function getStatus()
    --four types of status: "turtle", "task","console" ans "disconnect"
    local id, msg = rednet.receive("status")
    if id == TurtleID then
        -- "console" status writes to console window
        if msg.head == "console" then
            GUI.drawConsole(msg.body[1])
            if msg.body[2] then
                sendCmd(io.read())
            end
        -- "turtle" status writes to turtleID window
        elseif msg.head == "turtle" then
            GUI.drawTurtleStatus(TurtleID)
        -- "task" status writes to task completion window
        elseif msg.head == "task" then
            GUI.drawTaskStatus(msg.body[1], msg.body[2])
            --if task is 100% at completion, return status
            if msg.body[1] == 1 then
                GUI.drawConsole("Task complete! Press Enter to continue", true)
                _ = io.read()
                GUI.drawTaskStatus()
                return true
            end
        -- "disconnect" severs connection between server and turtle
        elseif msg.head == "disconnect" then
            Console.clear()
            GUI.drawConsole("Turtle #"..TurtleID.." requested to disconnect")
            TurtleID = nil
            CurrenTask = nil
            GUI.drawTaskStatus()
            GUI.drawTurtleStatus()
            os.sleep(2)
            Console.clear()
            return true
        end
    end
end

local function checkModem()
    while true do
        peripheral.find("modem", rednet.open)
        if not rednet.isOpen() then
            GUI.drawConsole("Could not find modem on computer. Place a wireless modem on the computer.", true)
            os.pullEvent("peripheral")
        else break
        end
    end
end

return {
    getTurtleID = getTurtleID,
    setTurtleID = setTurtleID,
    getServerCoords = getServerCoords,
    pingTurtles = pingTurtles,
    sendCmd = sendCmd,
    getStatus = getStatus,
    checkModem = checkModem
}