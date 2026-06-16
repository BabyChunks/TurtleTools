-- Library for managing inventory with a computer. One inventory must be designated as the "interfacing" inventory for a given computer

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
                local ans = io.read()
                Console.clearLine()
                if string.match("^[Qq]uit$") then return true end

            end
            local function updateInvs()
                while true do
                    Items = {}
                    local invs = {peripheral.find("inventory")}
                    if #invs ~= 0 then
                        for _, inv in pairs(invs) do
                            Items[peripheral.getName(inv)] = {}
                            for slot = 1, inv.size() do
                                local item = inv.getItemDetail(slot)
                                if item then
                                    Items[peripheral.getName(inv)][slot] = {name = item.displayName, count = item.count}
                                end
                            end
                        end
                    end
                    os.sleep(5)
                end
            end
            local function aggregateItems()
                while true do
                    ItemList = {}
                    for periph, slots in pairs(Items) do
                        for slot, item in pairs(slots) do
                            if not ItemList[item.name] then
                                ItemList[item.name] = item.count
                            else
                                ItemList[item.name] = ItemList[item.name] + item.count
                            end
                        end
                    end
                    os.sleep(5)
                end
            end
            local function menu()

                local itemMenu = Menu:new()
                    itemMenu.vMargins = 1
                    itemMenu.options = ItemList
                    itemMenu.actions = {}
                itemMenu:init()
            end
            parallel.waitForAny(menu, aggregateItems, updateInvs)
        end,
        function() --Stock Items
        end,
        function() --Change Interface
        end,
        function() -- Quit
        end
    }


return {
    itemMenu = itemMenu,
    invMenu = invMenu
}