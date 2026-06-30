-- Library for communication between turtle and server --

--[[ Wait for pings from computers to take control of turtle, answer with turtle coords and wait for
connection message ]]
local function connectServer()
    while true do
        local id, msg = rednet.receive("ping")
        if msg[1] == "ping" then
            rednet.send(id, {"pong", {GPS.getVectorComponents(Coords)}}, "ping")
        elseif msg[1] == "ack" then
            ServerID = id
            GUI.drawConsole("Server connected at ID "..ServerID)
            GUI.drawServerStatus(ServerID)
            return
        end
    end
end

-- wait for commands or generic messages from controlling computer
local function getCmd()
    if ServerID then
        local id, msg = rednet.receive("cmd")
        if id == ServerID then
            return textutils.unserialize(msg)
        end
    else
        return io.read()
    end
end

--[[ If a computer is controlling: send status messages; if no computer controls the turtle: draw 
information to relevant window ]]
local function sendStatus(head, body)
    if ServerID then
        rednet.send(ServerID, {head = head, body = body}, "status")
        if head == "console" and body[2] then
            GUI.drawConsole("awaiting answer from server")
            return getCmd()
        end
    else
        if head == "console" then GUI.drawConsole(body[1], body[2])
            if body[2] then
                return io.read()
            end
        elseif head == "task" then GUI.drawTaskStatus(body[1], body[2])
            --if task is 100% at completion, return status
            if body[1] == 1 then
                GUI.drawConsole("Task complete! Press Enter to continue", true)
                _ = io.read()
                GUI.drawTaskStatus()
                return true
            end
        end
    end
end

-- Check for equipped modem and open it if found, else prompt user for modem
local function checkModem()
    while true do
        local modem = peripheral.find("modem")
        if not modem then
            for slot = 1, 16 do
                local item = turtle.getItemDetail(slot)
                if item then
                    if Lt.tableContainsValue(St.MODEMS, item.name) then
                        turtle.select(slot)
                        turtle.equipLeft()
                        rednet.open("left")
                        return
                    end
                end
            end
            sendStatus("console", {"Could not find modem on turtle. Put a wireless modem in inventory, or equip it, then press Enter to continue", true})
        elseif peripheral.getName(modem) == "right" then
            turtle.equipRight()
            turtle.equipLeft()
        end
        rednet.open("left")
        return
    end
end

return {
    connectServer = connectServer,
    getCmd = getCmd,
    sendStatus = sendStatus,
    checkModem = checkModem
}