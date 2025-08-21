local lt = require("luatools")

Heading = nil
Coords = {}

NSLOTS = 16

FUELS = {
    "minecraft:coal",
    "minecraft:coal_block",
    "minecraft:charcoal",
    "quark:charcoal_block",
    "minecraft:lava_bucket",
    "immersiveengineering:coal_coke",
    "immersiveengineering:coke"
}
INVS = {
    ["forge:chests"] = true,
    "immersiveengineering:crate",
    "immersiveengineering:reinforced_crate",
    ["forge:barrels"] = true,
    ["computercraft:turtle"] = true,
    ["forge:boxes/shulker"] = true,
    ["farmersdelight:cabinets"] = true,
    ["sophisticatedbackpacks:backpack"] = true
}

local function checkFuel(fuelNeeded)
    local item = {}
    local currFuel = turtle.getFuelLevel()

    while currFuel < fuelNeeded do
        for slot = 1, NSLOTS do
            item = turtle.getItemDetail(slot)
            if item then
                if lt.tableContainsValue(FUELS, item.name) then
                    turtle.select(slot)
                    turtle.refuel()
                    os.queueEvent("buffer")
                    currFuel = turtle.getFuelLevel()
                end
            end
        end
        if  currFuel < fuelNeeded then
            io.write("Unsufficient fuel. Add " .. fuelNeeded - currFuel .. " fuel units to turtle's inventory\n")
            os.pullEvent("turtle_inventory")
        end
    end
end

local function noGPS(dim) --manually enter xz or xyz coords
    local format, ans = "", ""
    local keys, coords = {}, {}

    if dim == "xyz" then
        format = "x, y, z"
        keys = {"x", "y", "z"}
    elseif dim == "xz" then
        format = "x, z"
        keys = {"x", "z"}
    end

    io.write("Could not locate turtle using gps. Input coordinates (" .. format .. ") manually or press Enter to terminate\n")
    local incomplete = true

    while incomplete do
        ans = io.read()
        if ans == "" then
            os.reboot()
        end

        coords = lt.argparse(ans, keys)

        incomplete = false
        for _, coord in pairs(coords) do
            if type(coord) ~= "number" then
                io.write("Input must be numbers\n")
                incomplete = true
                break
            end
        end
    end
    return coords
end

function GetHeading(turn) --set or get Heading to turtle's current heading on the x-z plane. Requires gps
    if not Heading then
        local coords1, coords2 = {}, {}

        checkFuel(2)

        coords1.x, coords1.z = Coords.x, Coords.z

        if turtle.detect() then
            turtle.dig()
            turtle.suck()
        end
        assert(turtle.forward())

        coords2.x, _, coords2.z = gps.locate()
        if not coords2.x then
            coords2 = noGPS("xz")
        end
        assert(turtle.back())

        if coords2.x - coords1.x > 0 then
            Heading =  "x"

        elseif coords2.x - coords1.x < 0 then
            Heading = "-x"

        elseif coords2.z - coords1.z > 0 then
            Heading = "z"

        elseif coords2.z - coords1.z < 0 then
            Heading = "-z"

        end
    end
    if turn then
        local i = 0
        local compass = {
            [0] = "x",
            [1] = "z",
            [2] = "-x",
            [3] = "-z"
        }

        if turn == "right" then
            i = lt.getKeyForValue(compass, Heading) + 1

        elseif turn == "left" then
            i = lt.getKeyForValue(compass, Heading) - 1

        end

        if i == 4 then i = 0 end
        if i == -1 then i = 4 end

        Heading = compass[i]
    end
end

local function stripMine() --Inspects adjacent blocks and enters a new stripMine() instance if ore is found
    local block, blockdata = turtle.inspectUp()

    if block then
        if lt.tableContainsKey(blockdata.tags, "forge:ores") then
            turtle.digUp()
            turtle.suckUp()
            assert(turtle.up())
            stripMine()
            assert(turtle.down())
        end
    end

    block, blockdata = turtle.inspectDown()

    if block then
        if lt.tableContainsKey(blockdata.tags, "forge:ores") then
            turtle.digDown()
            turtle.suckDown()
            assert(turtle.down())
            stripMine()
            assert(turtle.up())
        end
    end

    for turn = 1,4 do
        block, blockdata = turtle.inspect()

        if block then
            if lt.tableContainsKey(blockdata.tags, "forge:ores") then
                turtle.dig()
                turtle.suck()
                assert(turtle.forward())
                stripMine()
                assert(turtle.back())
            end
        end

        turtle.turnRight()
        GetHeading("right")
        turn = turn + 1
    end
end

function Mine(blocks, strip) -- Mine in a straight line for a number of blocks. Specify strip if turtle should evaluate every adjacent block for strip mining
    strip = strip or false
    local move = 0

    while move < blocks do

        if strip then
            stripMine()
        end

        while turtle.detect() do
            turtle.dig()
            turtle.suck()
        end
        assert(turtle.forward())
        move = move + 1
    end
end

function GoThere(x, y, z, strip) -- main function for navigation. Uses absolute coords to navigate
    strip = strip or false
    local rel = {}
    local xblocks, yblocks, zblocks = 0, 0, 0

    rel = {
        x = (x - Coords.x),
        y = (y - Coords.y),
        z = (z - Coords.z)
    }

    checkFuel(rel.x + rel.y + rel.z)

    xblocks = math.abs(rel.x)

    if rel.x < 0 then
        if Heading == "x" then
            turtle.turnRight()
            turtle.turnRight()

        elseif Heading == "z" then
            turtle.turnRight()

        elseif Heading == "-z" then
            turtle.turnLeft()
        end

        Heading = "-x"

    elseif rel.x > 0 then
        if Heading == "-x" then
            turtle.turnRight()
            turtle.turnRight()

        elseif Heading == "z" then
            turtle.turnLeft()

        elseif Heading == "-z" then
            turtle.turnRight()
        end

        Heading = "x"
    end

    Mine(xblocks, strip)

    zblocks = math.abs(rel.z)

    if rel.z < 0 then
        if Heading == "z" then
            turtle.turnRight()
            turtle.turnRight()

        elseif Heading == "x" then
            turtle.turnLeft()

        elseif Heading == "-x" then
            turtle.turnRight()

        end

        Heading = "-z"

    elseif rel.z > 0 then
        if Heading == "-z" then
            turtle.turnRight()
            turtle.turnRight()

        elseif Heading == "x" then
            turtle.turnRight()

        elseif Heading == "-x" then
            turtle.turnLeft()

        end

        Heading = "z"
    end

    Mine(zblocks, strip)

    yblocks = math.abs(rel.y)

    if rel.y < 0 then
        local move = 0

        while move < yblocks do
            while turtle.detectDown() do
                turtle.digDown()
                turtle.suckDown()
            end

            assert(turtle.down())
            move = move + 1
        end
    elseif rel.y > 0 then
        local move = 0

        while move < yblocks do
            while turtle.detectUp() do
                turtle.digUp()
                turtle.suckUp()
            end

            assert(turtle.up())
            move = move + 1
        end
    end
    Coords = {
        x = x,
        y = y,
        z = z
    }
end

local function startup()
    local incomplete = true

    io.write("Startup sequence for mining turtle.\n")
    os.sleep(1)

    Coords.x, Coords.y, Coords.z = gps.locate()
    if not Coords.x then
        Coords = noGPS("xyz")
    end
    GetHeading()

    io.write("Please select a command\n")
    local options = {"mine", "quit"}
    textutils.tabulate(options)

    local cmd = io.read()

    if cmd == "mine" then
        local coords1, coords2, pattern, signs, fuelNeeded = {}, {}, {}, {}, {}
        local i, nCycle, layer, nLayer= 0, 0, 0, 0

        io.write("first coordinates: \n")

        incomplete = true
        while incomplete do
            coords1 = lt.argparse(io.read(), {"x", "y", "z"})

            incomplete = false
            for _, coord in pairs(coords1) do
                if type(coord) ~= "number" then
                    io.write("Input must be numbers\n")
                    incomplete = true
                end
            end
        end

        incomplete = true
        io.write("second coordinates: \n")

        while incomplete do
            coords2 = lt.argparse(io.read(), {"x", "y", "z"})

            incomplete = false
            for _, coord in pairs(coords2) do
                if type(coord) ~= "number" then
                    io.write("Input must be numbers\n")
                    incomplete = true
                end
            end
        end

        Patterns ={
                    [1] = {
                        tunnels = 2, endCap = 3, cycleLn = 6, yOffset = {0, 0}, zOffset = {3, 6}
                    },
                    [2] = {
                        tunnels = 2, endCap = 6, cycleLn = 4, yOffset = {1, 0}, zOffset = {2, 4}
                    },
                    [3] = {
                        tunnels = 6, endCap = 9, cycleLn = 10, yOffset = {2, 1, 0, 2, 1, 0}, zOffset = {1, 3, 5, 6, 8, 10}
                    },
                    [4] = {
                        tunnels = 6, endCap = 19, cycleLn = 7, yOffset = {3, 2, 0, 3, 1, 0}, zOffset = {0, 2, 3, 4, 5, 7}
                    },
                    [5] = {
                        tunnels = 10, endCap = 17, cycleLn = 10, yOffset = {2, 4, 1, 3, 0, 2, 4, 1, 3, 0}, zOffset = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
                    },
                }

        local quarrySize = {
            abs ={
                x = math.abs(coords2.x - coords1.x) + 1,
                y = math.abs(coords2.y - coords1.y) + 1,
                z = math.abs(coords2.z - coords1.z) + 1
            },
            rel = {
                x = coords2.x - coords1.x,
                y = coords2.y - coords1.y,
                z = coords2.z - coords1.z
            }
        }

        i = math.min(quarrySize.abs.y, 5)
        pattern = Patterns[i]

        for dim, size in pairs(quarrySize.rel) do
            if size < 0 then signs[dim] = -1
            elseif size >= 0 then signs[dim] = 1
            end
        end

        nLayer = math.ceil(quarrySize.abs.y / i)
        nCycle = math.ceil(quarrySize.abs.z / pattern.cycleLn)
        fuelNeeded = nLayer * nCycle * (pattern.tunnels * quarrySize.abs.x + pattern.endCap) + lt.tableSum(quarrySize.abs)

        GoThere(coords1.x, coords1.y, coords1.z)
        checkFuel(fuelNeeded)

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

                for t = tunnelStart, tunnelStop, step  do

                    local x = coords1.x + signs.x * (t % 2) * (quarrySize.abs.x - 1)
                    local y = coords1.y + signs.y * (i * layer + pattern.yOffset[t])
                    local z = coords1.z + signs.z * (pattern.cycleLn * cycle + pattern.zOffset[t])

                    if (pattern.cycleLn * cycle + pattern.zOffset[t]) < quarrySize.abs.z then
                        local emptySlot = 0
                        GoThere(x, y, z, true)

                        if t % 2 == 0 then
                            for slot = 1, NSLOTS do
                                if turtle.getItemCount(slot) == 0 then
                                    emptySlot = emptySlot + 1
                                end
                            end
                            if emptySlot <= 3 then
                                GoThere(coords1.x, coords1.y, coords1.z)
                                io.write("Inventory is nearly full. Unload turtle to continue, then press Enter.")
                                _ = io.read()
                                GoThere(x, y ,z)

                            end
                        end
                    end
                end
                cycle = cycle + 1

            end
            layer = layer + 1
        end
        GoThere(coords1.x, coords1.y, coords1.z)

    elseif cmd == "move" then

    elseif cmd == "GPS" then
        local base = {}
        io.write("Setting up a GPS array. Please input base coordinates.\n")

        incomplete = true
        while incomplete do
            base = lt.argparse(io.read(), {"x", "y", "z"})
            
            incomplete = false
            for _, coord in pairs(base) do
                if type(coord) ~= "number" then
                    io.write("Input must be numbers\n")
                    incomplete = true
                    break
                end
            end
        end

        GoThere(base.x, base.y, base.z)

        local partsNeeded = {
            [1] = {names = {"computercraft:computer_normal", "computercraft:computer_advanced"}, n = 4, check = false},
            [2] = {names = {"computercraft:wireless_modem_normal", "computercraft:wireless_modem_advanced"}, n = 4, check = false},
            [3] = {names = {"computercraft:wired_modem"}, n = 6, check = false},
            [4] = {names = {"computercraft:cable"}, n = 9, check = false}
        }

        while incomplete do
            incomplete = false
            for _, part in pairs(partsNeeded) do
                for slot = 1, 16 do
                    local item = turtle.getItemDetail(slot)
                    if item then
                        if lt.tableContainsValue(part.names, item.name) then
                            if item.count >= part.n then
                                part.check = true
                            end
                        end
                    end
                end
                if not part.check then
                    incomplete = true
                end
            end
            if incomplete then
                io.write("List of objects to put in inventory:\n")
                textutils.tabulate({4, 4, 6, 9},{"Computers", "Wireless Modems", "Wired Modems", "Wires"})
                os.pullEvent("turtle_inventory")
            end
        end

        io.write("Clear a space of 6 blocks in the positive x and z direction, as well as a clearance of 6 blocks above the square delimited thus. Press Enter when this is done.\n")
        _ = io.read()

    elseif cmd == "quit" then
        io.write("Goodbye")
        os.sleep(2)
        os.reboot()
    else
        io.write("Couldn't recognize input\n")
        os.sleep(2)
        startup()
    end
end

startup()