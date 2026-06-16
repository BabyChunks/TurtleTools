-- Library for managing inventory with a computer. One inventory must be designated as the "interfacing" inventory for a given computer

local function updateInvs()
    Invs = {peripheral.find("inventory")}
end

local function updateItems()
    if #Invs ~= 0 then
        for _, inv in pairs(Invs) do
            Items[peripheral.getName(inv)] = inv.list()
            -- local slots = inv.list()
            -- for slot, item in pairs(slots) do
            --     Items[peripheral.getName(inv)][slot] = item
            -- end
        end
    end
end

local invMenu = Menu:new()
    invMenu.vMargins = 1
    invMenu.options = {"Retrieve Items", "Stock Items", "Change Interface", "Quit"}
    invMenu.actions = {
        function() --Retrieve Items
            GUI.drawConsole("*** Item Retrieval ***")
            GUI.drawConsole("Items containing the input keywords will be moved to the interface")
            GUI.drawConsole("You can also search for a specific item set")
            GUI.drawConsole("Type 'quit' to go back to Inventory menu")
            while true do
                local ans = string.lower(io.read())
                if string.match(ans, "^%s*quit%s*$") then break end
                GUI.drawConsole("Retrieving items...")
                updateInvs()
                updateItems()
                local pulledNum = 0
                for periph, slots in pairs(Items) do
                    for slot, item in pairs(slots) do
                        if string.match(item.name, ans) then
                            Interface.pullItems(periph, slot)
                            pulledNum = pulledNum + item.count
                        end
                    end
                end
                GUI.drawConsole("Done. "..pulledNum.." items moved to "..peripheral.getName(Interface))
            end
        end,
        function() --Stock Items
        end,
        function() --Change Interface
        end,
        function() -- Quit
            return true
        end
    }


return {
    itemMenu = itemMenu,
    invMenu = invMenu
}