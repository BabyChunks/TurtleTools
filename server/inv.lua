-- Library for managing inventory with a computer. One inventory must be designated as the "interfacing" inventory for a given computer

local faces = {
    "front",
    "back",
    "left",
    "right",
    "bottom",
    "top"
}

local function updateInterface()
    parallel.waitForAny(
        function()
            local ans = io.read()
            while not (peripheral.isPresent(ans) and peripheral.hasType(ans, "inventory") and not Lt.tableContainsValue(faces, ans))  do
                GUI.drawConsole("No inventory by that name on any wired network. Please input the interface inventory's name", true)
                ans = io.read()
            end
            Interface = peripheral.wrap(ans)
        end,
        function()
            local address = ""
            repeat  _, address = os.pullEvent("peripheral")
            until peripheral.hasType(address, "inventory") and not Lt.tableContainsValue(faces, address)
            Interface = peripheral.wrap(address)
            term.setCursorBlink(false)
        end
    )
end

local function updateInvs() -- try using modem.getNamesRemote()
    Invs = {peripheral.find("inventory")}
    for pos, inv in pairs(Invs) do
        if peripheral.getName(inv) == peripheral.getName(Interface) then table.remove(Invs, pos)
        elseif Lt.tableContainsValue(faces, peripheral.getName(inv)) then table.remove(Invs, pos) end
    end
end

local function updateItems()
    if #Invs ~= 0 then
        for _, inv in pairs(Invs) do
            Items[peripheral.getName(inv)] = inv.list()
        end
    end
end

local function pushItems(inv, fromSlot, limit)
    inv = peripheral.wrap(inv)
    local invList = Lt.tableShallowCopy(Invs)
    for k, v in pairs(invList) do
        if peripheral.getName(v) == inv then table.remove(invList[k]) break end
    end
    local itemData = inv.getItemDetail(fromSlot)
    local count = itemData.count
    limit = limit or count
    for _, t in pairs(invList) do
        limit = limit - inv.pushItems(peripheral.getName(t), fromSlot, limit)
        if limit == 0 then break end
    end
end

local function pullItems(inv, fromName, fromSlot, limit, toSlot)

end

local function swap(inv1, slot1, inv2, slot2)
    for _, inv in pairs(Invs) do
        for slot = 1, inv.size() do
            if not inv.getItemDetail(slot) then
                inv.pullItems(inv1, slot1, nil, slot)
                peripheral.call(inv1, "pullItems", inv2, slot2, nil, slot1)
                inv.pushItems(inv2, slot, nil, slot2)
                return true
            end
        end
    end
    return false
end

-- this doesnt work. i might need to make my own push and pull functions to optimize stacking
-- actually might recycle this function later to use on user demand to undo re-stacking mistakes.
-- Use Interface as a temp space to organize inventories
local function sort()
    local items = {}
    for periph, slots in pairs(Items) do
        for slot, item in pairs(slots) do
            if not items[item.name] then
                items[item.name] = {}
            end
            table.insert(items[item.name], {name = item.name, count = item.count, periph = periph, slot = slot})
        end
    end

    local sortedItems = {}
    for _, item in pairs(items) do
        table.insert(sortedItems, item)
    end

    table.sort(sortedItems, function(a, b) return a[1].name < b[1].name end)
    textutils.pagedPrint(textutils.serialize(sortedItems)) _ = io.read()
    local currItem = table.remove(sortedItems)
    --textutils.pagedPrint(textutils.serialize(currItem)) _ = io.read()
    local currLoc = table.remove(currItem)
    for _, inv in pairs(Invs) do
        for slot = 1, inv.size() do
            if #currItem ~= 0 then
                if currLoc.count == 0 then
                    currLoc = table.remove(currItem)
                end
                local itemData = inv.getItemDetail(slot)
                if not itemData then
                    inv.pullItems(currLoc.periph, currLoc.slot, nil, slot)
                else
                    if itemData.name == currLoc.name then
                        currLoc.count = currLoc.count - inv.pullItems(currLoc.periph, currLoc.slot, itemData.maxCount - itemData.count, slot)
                    else
                        swap(peripheral.getName(inv), slot, currLoc.periph, currLoc.slot)
                        currLoc.count = 0
                    end
                end
            else
                currItem = table.remove(sortedItems)
            end
        end
    end
end

local function flushInterface()
    local pushCount = 0
    for _, inv in pairs(Invs) do
        for slot, item in pairs(Interface.list()) do
            pushCount = pushCount + Interface.pushItems(peripheral.getName(inv), slot)
        end
    end
    return pushCount
end

local invMenu = Menu:new()
    invMenu.title = "Inventory"
    invMenu.vMargins = 1
    invMenu.options = {"Retrieve Items", "Stock Items", "Change Interface", "Quit"}
    invMenu.actions = {
        function() --Retrieve Items
            GUI.drawConsole("*** Item Retrieval ***")
            GUI.drawConsole("Items containing the input keywords will be moved to the interface")
            GUI.drawConsole("You can also search for a specific item set")
            GUI.drawConsole("An empty query ('') will retrieve the entire inventory")
            GUI.drawConsole("Type 'quit' to go back to Inventory menu")
            while true do
                local ans = string.lower(io.read())
                local keywords = {}
                local pullTotal = 0
                if string.match(ans, "^quit$") then
                    flushInterface()
                    break
                elseif string.match(ans, "^%s*$") then
                    keywords = {"%a"}
                else
                    keywords = Lt.argparse(ans)
                end
                GUI.drawConsole("Retrieving items...")
                updateInvs()
                updateItems()
                for periph, slots in pairs(Items) do
                    for slot, item in pairs(slots) do
                        for _, keyword in pairs(keywords) do
                            if string.match(item.name, keyword) then
                                local pullCount = Interface.pullItems(periph, slot)
                                pullTotal = pullTotal + pullCount
                                if item.count ~= pullCount then
                                    GUI.drawConsole("Interface full. Please view the current inventory and press Enter when you are ready to view the other search items.", true)
                                    _ = io.read()
                                    flushInterface()
                                end
                                break
                            end
                        end
                    end
                end
                if pullTotal == 0 then
                    GUI.drawConsole("No item found with keyword"..((#keywords > 1) and "s" or ""))
                else
                    GUI.drawConsole("Done. "..pullTotal.." items moved to "..peripheral.getName(Interface))
                end
            end
        end,
        function() --Stock Items
            GUI.drawConsole("All items in interface inventory will be put away. Proceed? [y/n]", true)
            updateInvs()
            while true do
                local ans = string.lower(io.read())
                Console.setCursorPos(1, 3)
                Console.clearLine()
                if ans == "y" then
                    local count = flushInterface()
                    if count ~= 0 then
                        GUI.drawConsole("Done. "..count.. " items put away in inventory")
                        os.sleep(2)
                        break
                    else
                        GUI.drawConsole("No items could be moved")
                        os.sleep(2)
                        break
                    end
                elseif ans == "n" then break end
            end
        end,
        function() --Change Interface
            GUI.drawConsole("Input new interface name:", true)
            updateInterface()
        end,
        function() -- Quit
            return true
        end
    }


return {
    updateInterface = updateInterface,
    invMenu = invMenu
}