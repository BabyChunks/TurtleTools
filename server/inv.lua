-- Library for managing inventory with a computer. One inventory must be designated as the "interfacing" inventory for a given computer

local function updateInterface()
    local ans = io.read()
    local faces = {
        "front",
        "back",
        "left",
        "right",
        "bottom",
        "top"
    }
    while not (peripheral.isPresent(ans) and peripheral.hasType(ans, "inventory") and not Lt.tableContainsValue(faces, ans))  do
        GUI.drawConsole("No inventory by that name on any wired network. Please input the interface inventory's name", true)
        ans = io.read()
    end
    Interface = peripheral.wrap(ans)
end

local function updateInvs()
    Invs = {peripheral.find("inventory")}
    for pos, inv in pairs(Invs) do
        if peripheral.getName(inv) == peripheral.getName(Interface) then table.remove(Invs, pos) end
    end
end

local function updateItems()
    if #Invs ~= 0 then
        for _, inv in pairs(Invs) do
            Items[peripheral.getName(inv)] = inv.list()
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
                local pullCount = 0
                if string.match(ans, "^quit$") then
                    flushInterface()
                    break
                elseif string.match(ans, "%s*") then
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
                                pullCount = pullCount + Interface.pullItems(periph, slot)
                            end
                        end
                    end
                end
                if pullCount == 0 then
                    GUI.drawConsole("No item found with keyword"..((#keywords > 1) and "s" or ""))
                else
                    GUI.drawConsole("Done. "..pullCount.." items moved to "..peripheral.getName(Interface))
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
                        os.sleep(5)
                        break
                    else
                        GUI.drawConsole("No items could be moved")
                        os.sleep(5)
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
    itemMenu = itemMenu,
    invMenu = invMenu
}