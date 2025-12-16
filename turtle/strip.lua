Recall = vector.new(table.unpack(arg[1]))

local origin = Coords
local delta = vector.new(table.unpack(arg[2]))

    if Lt.tableContainsValue(delta, 0) then error("Quarry boundaries must be 3-dimensional") end

    local abs = {
       x = math.abs(delta.x),
       y = math.abs(delta.y),
       z = math.abs(delta.z)
    }

    local signs = {
        x = delta.x / abs.x,
        y = delta.y / abs.z,
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
    departure = GPS.sumAbsVectorComponents(abs)
}

Comms.sendStatus("task", {QuarryCompletion, colours.red, CurrentTask})
GPS.checkFuel(Lt.tableSum(fuelNeeded))
Comms.sendStatus("task", {QuarryCompletion, nil, CurrentTask})

Comms.sendStatus("console", {"Begin mining sequence..."})

for layer = 0, nLayer do
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
            local factors = {
                x = (t % 2) * (abs.x - 1),
                y = (i * layer + pattern.yOffset[t]),
                z = (pattern.ln * cycle + pattern.zOffset[t])
            }
            local v = vector.new(
                origin.x + signs.x * factors.x,
                origin.y + signs.y * factors.y,
                origin.z + signs.z * factors.z)

            QuarryCompletion = ((layer / nLayer) * 0.9 + ((cycleStart + (step * cycle)) / nCycle) * 0.1)
            Comms.sendStatus("task", {QuarryCompletion, colours.yellow, "Mining"})

            if (pattern.ln * cycle + pattern.zOffset[t]) <= abs.z and
            (i * layer + pattern.yOffset[t] <= abs.y) then
                local emptySlot = 0
                GPS.move(v - Coords, true)
                if t % 2 == 0 then
                    for slot = 1, 16 do
                        if turtle.getItemCount(slot) == 0 then
                            emptySlot = emptySlot + 1
                        end
                    end
                    if emptySlot <= St.emptySlots then
                        GPS.move(Recall - Coords)
                        Comms.sendStatus("task", {QuarryCompletion, colours.red, "Mining"})
                        _ = Comms.sendStatus("console",{"Inventory is nearly full. Unload turtle to continue, then press Enter.", true})
                        GPS.checkFuel(fuelNeeded / (1 - QuarryCompletion))
                        Comms.sendStatus("console",{"Resume mining..."})
                        Comms.sendStatus("task", {QuarryCompletion, nil, "Mining"})
                        GPS.move(v - Coords)
                    end
                end
            end
        end
    end
end
GPS.move(Recall - Coords)
Comms.sendStatus("task", {1, nil, "Mining"})