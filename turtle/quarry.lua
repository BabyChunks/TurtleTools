QuarryCompletion = 0

local function getCompletion()
    return QuarryCompletion
end

local function mineVein() --Inspects adjacent blocks and enters a new mineVein() instance if ore is found
    local block, blockdata = turtle.inspectUp()

    if block then
        if Lt.tableContainsKey(blockdata.tags, "forge:ores") then
            while turtle.detectUp() do
                turtle.digUp()
                turtle.suckUp()
            end
            assert(turtle.up())
            mineVein()
            assert(turtle.down())
        end
    end

    block, blockdata = turtle.inspectDown()

    if block then
        if Lt.tableContainsKey(blockdata.tags, "forge:ores") then
            while turtle.detectDown() do
                turtle.digDown()
                turtle.suckDown()
            end
            assert(turtle.down())
            mineVein()
            assert(turtle.up())
        end
    end

    for turn = 1, 4 do
        block, blockdata = turtle.inspect()

        if block then
            if Lt.tableContainsKey(blockdata.tags, "forge:ores") then
                while turtle.detect() do
                    turtle.dig()
                    turtle.suck()
                end
                assert(turtle.forward())
                mineVein()
                assert(turtle.back())
            end
        end

        turtle.turnRight()
        GPS.getHeading("right")
        turn = turn + 1
    end
end

local function tunnel(blocks, strip) -- Mine in a straight line for a number of blocks. Specify strip if turtle should evaluate every adjacent block for strip mining
    strip = strip or false
    local move = 0

    while move < blocks do
        if strip then
            mineVein()
        end

        while turtle.detect() do
            turtle.dig()
            turtle.suck()
        end
        assert(turtle.forward())
        move = move + 1
    end
end

local function startup(cmd)

    --Comms.sendStatus("Startup sequence for Mine Turtle (tm)")

    local pattern, signs, fuelNeeded = {}, {}, {}
    local i, nCycle, layer, nLayer = 0, 0, 0, 0

    -- Comms.sendStatus("Use current coordinates as recall point? (y/[xyz])", true)
    -- incomplete = true
    -- while incomplete do
    --     local ans = io.read()
    --     if ans == "y" or ans == "Y" then
    --         Recall = Coords
    --         incomplete = false
    --     else
    --         err, Recall = pcall(Lt.argparse, ans)
    --         if err then
    --             incomplete = false
    --             for _, coord in pairs(Recall) do
    --                 if type(coord) ~= "number" then
    --                     io.write("Input must be numbers\n")
    --                     incomplete = true
    --                     break
    --                 end
    --             end
    --         else
    --             io.write(Recall .. "\n")
    --         end
    --     end
    -- end

    

    -- print("first coordinates:")

    -- incomplete = true
    -- while incomplete do
    --     err, coords1 = pcall(Lt.argparse, io.read())
    --     if err then
    --         incomplete = false
    --         for _, coord in pairs(coords1) do
    --             if type(coord) ~= "number" then
    --                 io.write("Input must be numbers\n")
    --                 incomplete = true
    --             end
    --         end
    --     else
    --         io.write(coords1 .. "\n")
    --     end
    -- end

    -- incomplete = true
    -- print("second coordinates:")

    -- while incomplete do
    --     err, coords2 = pcall(Lt.argparse, io.read(), { "x", "y", "z" })
    --     if err then
    --         incomplete = false
    --         for _, coord in pairs(coords2) do
    --             if type(coord) ~= "number" then
    --                 io.write("Input must be numbers\n")
    --                 incomplete = true
    --             end
    --         end
    --     else
    --         io.write(coords2 .. "\n")
    --     end
    -- end

    local Recall = cmd[1]
    local coords1, coords2 = cmd[2], cmd[3]

    Patterns = {
        [1] = {
            tunnels = 2, endCap = 3, cycleLn = 6, yOffset = { 0, 0 }, zOffset = { 3, 6 }
        },
        [2] = {
            tunnels = 2, endCap = 6, cycleLn = 4, yOffset = { 1, 0 }, zOffset = { 2, 4 }
        },
        [3] = {
            tunnels = 6, endCap = 9, cycleLn = 10, yOffset = { 2, 1, 0, 2, 1, 0 }, zOffset = { 1, 3, 5, 6, 8, 10 }
        },
        [4] = {
            tunnels = 6, endCap = 19, cycleLn = 7, yOffset = { 3, 2, 0, 3, 1, 0 }, zOffset = { 0, 2, 3, 4, 5, 7 }
        },
        [5] = {
            tunnels = 10, endCap = 17, cycleLn = 10, yOffset = { 2, 4, 1, 3, 0, 2, 4, 1, 3, 0 }, zOffset = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
        },
    }


    local quarrySize = {}
        quarrySize.rel = coords2:sub(coords1)
        quarrySize.abs = {
            x = math.abs(quarrySize.rel.x) + 1,
            y = math.abs(quarrySize.rel.y) + 1,
            z = math.abs(quarrySize.rel.z) + 1,
        }

    i = math.min(quarrySize.abs.y, #Patterns)
    pattern = Patterns[i]

    for dim, size in pairs(quarrySize.rel) do
        if size < 0 then
            signs[dim] = -1
        elseif size >= 0 then
            signs[dim] = 1
        end
    end

    nLayer = math.ceil(quarrySize.abs.y / i)
    nCycle = math.ceil(quarrySize.abs.z / pattern.cycleLn)
    fuelNeeded = {
        arrival = GPS.sumVectorComponents(coords1:sub(Coords)),
        quarry = nLayer * nCycle * (pattern.tunnels * quarrySize.abs.x + pattern.endCap),
        departure = GPS.sumVectorComponents(coords2:sub(Coords))
    }

    Comms.sendStatus("task", {QuarryCompletion, colours.red, "Mining"})
    GPS.checkFuel(Lt.tableSum(fuelNeeded))
    Comms.sendStatus("task", {QuarryCompletion, nil, "Mining"})

    Comms.sendStatus("console", {"Begin mining sequence..."})

    GPS.goThere(coords1)

    while layer < nLayer do
        local tunnelStart, tunnelStop, cycleStart, cycleStop, step = 0, 0, 0, 0, 0

        if layer % 2 == 0 then
            tunnelStart = 1
            tunnelStop = pattern.tunnels
            cycleStart = 0
            cycleStop = nCycle + 1
            step = 1
        else
            tunnelStart = pattern.tunnels
            tunnelStop = 1
            cycleStart = nCycle + 1
            cycleStop = 0
            step = -1
        end

        for cycle = cycleStart, cycleStop, step do
            for t = tunnelStart, tunnelStop, step do
                local v = vector.new(
                    coords1.x + signs.x * (t % 2) * (quarrySize.abs.x - 1),
                    coords1.y + signs.y * (i * layer + pattern.yOffset[t]),
                    coords1.z + signs.z * (pattern.cycleLn * cycle + pattern.zOffset[t]))
                -- local x = coords1.x + signs.x * (t % 2) * (quarrySize.abs.x - 1)
                -- local y = coords1.y + signs.y * (i * layer + pattern.yOffset[t])
                -- local z = coords1.z + signs.z * (pattern.cycleLn * cycle + pattern.zOffset[t])

                QuarryCompletion = ((layer / nLayer) * 0.99 + (cycle / nCycle) * 0.01)
                Comms.sendStatus("task", {QuarryCompletion, colours.yellow, "Mining"})

                if (pattern.cycleLn * cycle + pattern.zOffset[t]) <= quarrySize.abs.z then
                    local emptySlot = 0
                    GPS.goThere(v, true)

                    if t % 2 == 0 then
                        for slot = 1, 16 do
                            if turtle.getItemCount(slot) == 0 then
                                emptySlot = emptySlot + 1
                            end
                        end
                        if emptySlot <= St.emptySlots then
                            GPS.goThere(Recall)
                            Comms.sendStatus("task", {QuarryCompletion, colours.red, "Mining"})
                            _ = Comms.sendStatus("console",{"Inventory is nearly full. Unload turtle to continue, then press Enter.", true})
                            GPS.checkFuel(fuelNeeded / (1 - QuarryCompletion))
                            Comms.sendStatus("console",{"Resume mining..."})
                            Comms.sendStatus("task", {QuarryCompletion, nil, "Mining"})
                            GPS.goThere(v)
                        end
                    end
                end
            end
            cycle = cycle + 1
        end
        layer = layer + 1
    end
    GPS.goThere(Recall)
    Comms.sendStatus("console", {"Mining sequence done!"})
end

return {
    getCompletion = getCompletion,
    tunnel = tunnel,
    startup = startup
}
