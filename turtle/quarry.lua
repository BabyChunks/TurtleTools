NSLOTS = 16

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

    for turn = 1,4 do
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
        GetHeading("right")
        turn = turn + 1
    end
end

local function mine(blocks, strip) -- Mine in a straight line for a number of blocks. Specify strip if turtle should evaluate every adjacent block for strip mining
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

-- local function startup()
--     local incomplete = true

--     print("Startup sequence for Mine Turtle (tm)")
--     os.sleep(1)
--     term.clear()
--     term.setCursorPos(1,1)

--     Coords.x, Coords.y, Coords.z = gps.locate()
--     if not Coords.x then
--         Coords = NoGPS("xyz")
--     end
--     GetHeading()

--     local coords1, coords2, pattern, signs, fuelNeeded = {}, {}, {}, {}, {}
--     local i, nCycle, layer, nLayer= 0, 0, 0, 0
--     local err = false

--     print("Use current coordinates as recall point? (y/[xyz])")
--     incomplete = true
--     while incomplete do
--         local ans = io.read()
--         if ans == "y" or ans == "Y" then
--             Recall = Coords
--             incomplete = false
--         else
--             err, Recall = pcall(Lt.argparse, ans, {"x", "y", "z"})
--             if err then
--                 incomplete = false
--                 for _, coord in pairs(Recall) do
--                     if type(coord) ~= "number" then
--                     io.write("Input must be numbers\n")
--                     incomplete = true
--                     break
--                     end
--                 end
--             else
--                 io.write(Recall .. "\n")
--             end
--         end
--     end

--     print("first coordinates:")

--     incomplete = true
--     while incomplete do
--         err, coords1 = pcall(Lt.argparse, io.read(), {"x", "y", "z"})
--         if err then
--             incomplete = false
--             for _, coord in pairs(coords1) do
--                 if type(coord) ~= "number" then
--                     io.write("Input must be numbers\n")
--                     incomplete = true
--                 end
--             end
--         else
--             io.write(coords1 .. "\n")
--         end
--     end

--     incomplete = true
--     print("second coordinates:")

--     while incomplete do
--         err, coords2 = pcall(Lt.argparse, io.read(), {"x", "y", "z"})
--         if err then
--             incomplete = false
--             for _, coord in pairs(coords2) do
--                 if type(coord) ~= "number" then
--                     io.write("Input must be numbers\n")
--                     incomplete = true
--                 end
--             end
--         else
--             io.write(coords2 .. "\n")
--         end
--     end

--     Patterns ={
--                 [1] = {
--                     tunnels = 2, endCap = 3, cycleLn = 6, yOffset = {0, 0}, zOffset = {3, 6}
--                 },
--                 [2] = {
--                     tunnels = 2, endCap = 6, cycleLn = 4, yOffset = {1, 0}, zOffset = {2, 4}
--                 },
--                 [3] = {
--                     tunnels = 6, endCap = 9, cycleLn = 10, yOffset = {2, 1, 0, 2, 1, 0}, zOffset = {1, 3, 5, 6, 8, 10}
--                 },
--                 [4] = {
--                     tunnels = 6, endCap = 19, cycleLn = 7, yOffset = {3, 2, 0, 3, 1, 0}, zOffset = {0, 2, 3, 4, 5, 7}
--                 },
--                 [5] = {
--                     tunnels = 10, endCap = 17, cycleLn = 10, yOffset = {2, 4, 1, 3, 0, 2, 4, 1, 3, 0}, zOffset = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
--                 },
--             }

--     local quarrySize = {
--         abs ={
--             x = math.abs(coords2.x - coords1.x) + 1,
--             y = math.abs(coords2.y - coords1.y) + 1,
--             z = math.abs(coords2.z - coords1.z) + 1
--         },
--         rel = {
--             x = coords2.x - coords1.x,
--             y = coords2.y - coords1.y,
--             z = coords2.z - coords1.z
--         }
--     }

--     i = math.min(quarrySize.abs.y, 5)
--     pattern = Patterns[i]

--     for dim, size in pairs(quarrySize.rel) do
--         if size < 0 then signs[dim] = -1
--         elseif size >= 0 then signs[dim] = 1
--         end
--     end

--     nLayer = math.ceil(quarrySize.abs.y / i)
--     nCycle = math.ceil(quarrySize.abs.z / pattern.cycleLn)
--     fuelNeeded = nLayer * nCycle * (pattern.tunnels * quarrySize.abs.x + pattern.endCap) + Lt.tableSum(quarrySize.abs)

--     GoThere(coords1.x, coords1.y, coords1.z)
--     checkFuel(fuelNeeded)

--     term.clear()
--     term.setCursorPos(1,1)
--     print("Beginning mining...")

--     while layer < nLayer do
--         local tunnelStart, tunnelStop, cycleStart, cycleStop, step = 0, 0, 0, 0, 0

--         if layer % 2 == 0 then
--             tunnelStart = 1
--             tunnelStop = pattern.tunnels
--             cycleStart = 0
--             cycleStop = nCycle + 1
--             step = 1
--         else
--             tunnelStart = pattern.tunnels
--             tunnelStop = 1
--             cycleStart = nCycle + 1
--             cycleStop = 0
--             step = -1
--         end

--         for cycle = cycleStart, cycleStop, step do

--             for t = tunnelStart, tunnelStop, step  do

--                 local x = coords1.x + signs.x * (t % 2) * (quarrySize.abs.x - 1)
--                 local y = coords1.y + signs.y * (i * layer + pattern.yOffset[t])
--                 local z = coords1.z + signs.z * (pattern.cycleLn * cycle + pattern.zOffset[t])

--                 if (pattern.cycleLn * cycle + pattern.zOffset[t]) < quarrySize.abs.z then
--                     local emptySlot = 0
--                     GoThere(x, y, z, true)

--                     if t % 2 == 0 then
--                         for slot = 1, NSLOTS do
--                             if turtle.getItemCount(slot) == 0 then
--                                 emptySlot = emptySlot + 1
--                             end
--                         end
--                         if emptySlot <= St.EmptySlots then
--                             GoThere(Recall.x, Recall.y, Recall.z)
--                             io.write("Inventory is nearly full. Unload turtle to continue, then press Enter.\n")
--                             _ = io.read()
--                             checkFuel(fuelNeeded / (1 - (0.1 * (layer / nLayer) + 0.01 * (cycle / nCycle))))
--                             io.write("Resume mining...\n")
--                             GoThere(x, y ,z)

--                         end
--                     end
--                 end
--             end
--             cycle = cycle + 1

--         end
--         layer = layer + 1
--     end
--     GoThere(Recall.x, Recall.y, Recall.z)
--     io.write("Mining sequence done!\n")
--     os.sleep(2)
-- end

return {

}