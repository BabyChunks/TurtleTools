local serverID = nil

-- Check for equipped modem and open it if found, else prompt user for modem --
while true do
    if #peripheral.find("modem", rednet.open) == 0 then
        for slot = 1, 16 do
            local item = turtle.getItemDetails(slot)
            if Lt.tableContainsValue(St.MODEMS, item.name) then
                turtle.select(slot)
                turtle.equipRight()
                break
            end
        end
        Comms.sendStatus("console", {"Could not find modem on turtle. Place a wireless modem in inventory, or equip it, and press Enter to conitnue", true})
    else break
    end
end

local function getServerID()
    return serverID
end

local function setServerID(id)
    serverID = id
end

local function connectServer()
    while true do
        local id, msg = rednet.receive("ping", St.pingTimeOut)
        if msg then
            if msg[1] == "ping" then
                rednet.send(id, {"pong", {Coords.x, Coords.y, Coords.z}}, "ping")
            elseif msg[1] == "ack" then
                print("Server connected at ID "..serverID)
                serverID = id
                return
            end
        end
    end
end

local function getCmd()
    local id, msg = rednet.receive("cmd")
    if id == serverID then
        return textutils.unserialize(msg)
    end
end

local function sendStatus(head, body)
    if serverID then
        rednet.send("status", {head = head, body = body})
        if body[2] then
            return getCmd()
        end
    else
        print(head..": "..body[1])
        if body[2] then
            return io.read()
        end
    end
end

return {
    getServerID = getServerID,
    setServerID = setServerID,
    connectServer = connectServer,
    getCmd = getCmd,
    sendStatus = sendStatus
}