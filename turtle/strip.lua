--[[ Strip mining script for use with the luatools, comms, GPS and GUI libraries.
mining patterns have been implemented to optimize number of tunnels, saving energy and maximizing yield.

env args:
[1] = coords for recalling the turtle -> table
[2] = coords of quarry origin -> table
[3] = length, height and  width of mining quarry -> table ]]

local function strip(args)
    for i, arg in pairs(args) do
        args[i] = textutils.unserialize(arg)
    end

    --textutils.pagedPrint(textutils.serialize(args))

    local recall = Lt.tablesEqual(args[1], {""}) and vector.new(GPS.getVectorComponents(Coords)) or vector.new(table.unpack(args[1]))
    local origin = Lt.tablesEqual(args[2], {""}) and vector.new(GPS.getVectorComponents(Coords)) or vector.new(table.unpack(args[2]))
    local delta = Lt.tablesEqual(args[3], {""}) and vector.new(table.unpack(St.sampleQuarry)) or vector.new(table.unpack(args[3]))

    print(textutils.serialize(recall)) _ = io.read()
    print(textutils.serialize(origin)) _ = io.read()
    print(textutils.serialize(delta)) _ = io.read()

    if Lt.tableContainsValue(delta, 0) then error("Quarry boundaries must be 3-dimensional") end

    Comms.sendStatus("console", {"Moving to quarry..."})
    GPS.goThere(origin)

    local abs = {
    x = math.abs(delta.x),
    y = math.abs(delta.y),
    z = math.abs(delta.z)
    }

    local signs = {
        x = delta.x / abs.x,
        y = delta.y / abs.y,
        z = delta.z / abs.z
    }

    Patterns = {
            [1] = {
                tunnels = 2, endCap = 3, ln = 6, yOffset = { 0, 0 }, zOffset = { 3, 6 }
            },
            [2] = {
                tunnels = 2, endCap = 6, ln = 4, yOffset = { 1, 0 }, zOffset = { 2, 4 }
            },
            [3] = {
                tunnels = 6, endCap = 9, ln = 10, yOffset = { 2, 1, 0, 2, 1, 0 }, zOffset = { 1, 3, 5, 6, 8, 10 }
            },
            [4] = {
                tunnels = 6, endCap = 19, ln = 7, yOffset = { 3, 2, 0, 3, 1, 0 }, zOffset = { 0, 2, 3, 4, 5, 7 }
            },
            [5] = {
                tunnels = 10, endCap = 17, ln = 10, yOffset = { 2, 4, 1, 3, 0, 2, 4, 1, 3, 0 }, zOffset = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
            },
        }

    local i = math.min(abs.y, #Patterns)
    local pattern = Patterns[i]

    local nLayer = math.ceil(abs.y / i)
    local nCycle = math.ceil(abs.z / pattern.ln)
    local fuelNeeded = {
        quarry = nLayer * nCycle * (pattern.tunnels * abs.x + pattern.endCap),
        departure = abs.x + abs.y + abs.z
    }

    QuarryCompletion = 0

    Comms.sendStatus("task", {QuarryCompletion, colours.red})
    GPS.checkFuel(Lt.tableSum(fuelNeeded))
    Comms.sendStatus("task", {QuarryCompletion, nil})

    Comms.sendStatus("console", {"Begin mining sequence..."})

    for layer = 0, nLayer do
        --print("layer = "..layer)
        local tunnelStart, tunnelStop, cycleStart, cycleStop, step = 0, 0, 0, 0, 0

        if layer % 2 == 0 then
            tunnelStart = 1
            tunnelStop = pattern.tunnels
            cycleStart = 0
            cycleStop = nCycle
            step = 1
        else
            tunnelStart = pattern.tunnels
            tunnelStop = 1
            cycleStart = nCycle + 1
            cycleStop = 0
            step = -1
        end

        for cycle = cycleStart, cycleStop, step do
            --print("cycle = "..cycle) _ = io.read()
            for t = tunnelStart, tunnelStop, step do
                --print("t = "..t) _ = io.read()
                local factors = {
                    x = (t % 2) * (abs.x - 1),
                    y = (i * layer + pattern.yOffset[t]),
                    z = (pattern.ln * cycle + pattern.zOffset[t])
                }
                local v = vector.new(
                    origin.x + signs.x * factors.x,
                    origin.y + signs.y * factors.y,
                    origin.z + signs.z * factors.z)

                -- print("factors: ") 
                -- print("x = ("..t.." % 2) * ("..abs.x.." - 1) = "..factors.x)
                -- print("y = ("..i.." * "..layer.." + "..pattern.yOffset[t]..") = "..factors.y)
                -- print("z = ("..pattern.ln.." * "..cycle.." + ".. pattern.zOffset[t]..") = "..factors.z) _ = io.read()
                -- print("v: "..v.x..", "..v.y..", "..v.z) _ = io.read()

                --QuarryCompletion = ((layer / nLayer) * 0.9 + ((cycleStart + (step * cycle)) / nCycle) * 0.09)
                QuarryCompletion = (delta:mul(Coords:sub(origin):dot(delta) / delta:length() ^ 2):length()) / delta:length()
                Comms.sendStatus("task", {QuarryCompletion, colours.yellow})

                if (pattern.ln * cycle + pattern.zOffset[t]) <= abs.z and
                (i * layer + pattern.yOffset[t] < abs.y) then
                    local emptySlot = 0
                    GPS.goThere(v, true)
                    if t % 2 == 0 then
                        for slot = 1, 16 do
                            if turtle.getItemCount(slot) == 0 then
                                emptySlot = emptySlot + 1
                            end
                        end
                        if emptySlot <= St.emptySlots then
                            GPS.goThere(recall)
                            Comms.sendStatus("task", {QuarryCompletion, colours.red})
                            _ = Comms.sendStatus("console",{"Inventory is nearly full. Unload turtle to continue, then press Enter.", true})
                            GPS.checkFuel(Lt. tableSum(fuelNeeded) / (1 - QuarryCompletion))
                            Comms.sendStatus("console",{"Resume mining..."})
                            Comms.sendStatus("task", {QuarryCompletion, nil})
                            GPS.goThere(v)
                        end
                    end
                end
            end
        end
    end
    GPS.goThere(recall)
    Comms.sendStatus("task", {1, nil})
end

return {
    strip = strip
}