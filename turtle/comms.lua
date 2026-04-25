local serverID = nil

local function getServerID()
    return serverID
end

local function setServerID(id)
    serverID = id
end

local function connectServer()
    while true do
        local id, msg = rednet.receive("ping")
            if msg[1] == "ping" then
                rednet.send(id, {"pong", {Coords.x, Coords.y, Coords.z}}, "ping")
            elseif msg[1] == "ack" then
                serverID = id
                GUI.drawConsole("Server connected at ID "..serverID)
                return
            end
    end
end

local function getCmd()
    if serverID then
        local id, msg = rednet.receive("cmd")
        if id == serverID then
            return textutils.unserialize(msg)
        end
    else
        return io.read()
    end
end

local function sendStatus(head, body)
    if serverID then
        rednet.send(serverID, {head = head, body = body}, "status")
        if head == "console" and body[2] then
            print("awaiting answer from server")
            return getCmd()
        end
    else
        print(head..": "..body[1])
        if body[2] then
            return io.read()
        end
    end
end

-- Check for equipped modem and open it if found, else prompt user for modem --
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
                    break
                end
            end
        end
        sendStatus("console", {"Could not find modem on turtle. Place a wireless modem in inventory, or equip it, and press Enter to continue", true})
    elseif peripheral.getName(modem) == "right" then
        turtle.equipRight()
        turtle.equipLeft()
        rednet.open("left")
        break
    else break
    end
end

return {
    getServerID = getServerID,
    setServerID = setServerID,
    connectServer = connectServer,
    getCmd = getCmd,
    sendStatus = sendStatus
}