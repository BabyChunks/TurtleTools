local luaTools = require("LuaTools")

Heading = nil
_FUELS = {
        "minecraft:coal",
        "minecraft:coal_block",
        "minecraft:charcoal",
        "quark:charcoal_block",
        "minecraft:lava_bucket",
        "immersiveengineering:coal_coke",
        "immersiveengineering:coke"
    }
_INVS = {
    "forge:chests",
    "immersiveengineering:crate",
    "immersiveengineering:reinforced_crate",
    "forge:barrels",
    "computercraft:turtle",
    "forge:boxes/shulker",
    "farmersdelight:cabinets",
    "sophisticatedbackpacks:backpack"
}

local function checkFuel(fuelNeeded)
    local item = {}
    local currFuel = turtle.getFuelLevel()

    while currFuel < fuelNeeded do
        for slot = 1, 16 do
            turtle.select(slot)
            item = turtle.getItemDetail(slot)
            if item then
                if luaTools.tableContainsValue(_FUELS, item.name) then
                    turtle.refuel()
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

local function noGPS(dim) --manually enter xy or xyz coords
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

        coords = luaTools.argparse(ans, keys)

        for _, coord in pairs(coords) do
            if type(coord) ~= "number" then
                io.write("Input must be numbers\n")
                incomplete = true
            end
        end
    end
    return coords
end

function GetHeading(turn) --set or get Heading to turtle's current heading on the x-z plane. Requires gps
    if not Heading then
        local coords1, coords2 = {}, {}

        coords1.x, _, coords1.z = gps.locate()
        if not coords1.x then
            coords1 = noGPS("xz")
        end
        print("[55]first coords: " .. coords1.x .. coords1.z)

        if turtle.detect() then
            print("[58]block detected in front of turtle")
            turtle.dig()
            turtle.suck()
        end
        
        assert(turtle.forward(), "GetHeading() terminated: not enough fuel")

        coords2.x, _, coords2.z = gps.locate()
        if not coords2.x then
            coords2 = noGPS("xz")
        end
        print("[69]second coords: ", coords2.x, coords2.z)

        assert(turtle.back(), "GetHeading() terminated: not enough fuel")

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
            i = luaTools.getKeyForValue(compass, Heading) + 1

        elseif turn == "left" then
            i = luaTools.getKeyForValue(compass, Heading) - 1
        end
        if i == 4 then i = 0 end

        Heading = compass[i]
    end
end

local function stripMine() --Inspects adjacent blocks and enters a new stripMine() instance if ore is found
    print("[107]entered new stripMine() routine")
    local block, blockdata = turtle.inspectUp()
    if block then
        print("[110]block detected above")
        if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
            print("[112]block is an ore")
            turtle.digUp()
            turtle.suckUp()
            assert(turtle.up())
            print("[116]mining and moving up")
            stripMine()
            assert(turtle.down())
            print("[119]ended previous stripMine() routine, moving back down")
        end
    end
    block, blockdata = turtle.inspectDown()
    if block then
        print("[124]block detected below")
        if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
            print("[126]block is an ore")
            turtle.digDown()
            turtle.suckDown()
            assert(turtle.down())
            print("[130]mining and moving down")
            stripMine()
            assert(turtle.up())
            print("[133]ended previous stripMine() routine, moving back up")
        end
    end
    for turn = 1,4 do
        block, blockdata = turtle.inspect()
        if block then
            print("[139]block detected forward")
            if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
                print("[141]block is an ore")
                turtle.dig()
                turtle.suck()
                assert(turtle.forward())
                print("[145]mining and moving forward")
                stripMine()
                assert(turtle.back())
                print("[148]ended previous stripMine() routine, moving back")
            end
        end
        turtle.turnRight()
        GetHeading("right")
        turn = turn + 1
        print("[154]turning right. heading is now = ", Heading)
    end
    print("[156]completed a turn. Ending stripMine() instance")
end

function Mine(blocks, strip) -- Mine in a straight line for a number of blocks. Specify strip if turtle should evaluate every adjacent block for strip mining
    strip = strip or false
    local move = 0

    print("[163]beginning sequence to mine ", blocks, " blocks")

    GetHeading()
    print("[166]heading acquired: ", Heading)

    while move < blocks do

        if strip then
            stripMine()
            print("[172]initial stripMine() terminated. Moving forward")
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
    print("[184]Starting sequence to move to coords:", x, y, z)
    strip = strip or false
    local bot, rel, item = {}, {}, {}
    local xblocks, yblocks, zblocks, currFuel, fuelNeeded = 0, 0, 0, 0, 0

    bot.x, bot.y, bot.z = gps.locate()
    if not bot.x then
        bot = noGPS("xyz")
    end

    print("[194]turtle location acquired: ", bot.x, bot.y, bot.z)

    rel = {
        x = (x - bot.x),
        y = (y - bot.y),
        z = (z - bot.z)
    }
    print("[201]computed movement necessary:")
    print("x= ", rel.x)
    print("y= ", rel.y)
    print("z= ", rel.z)

    checkFuel(rel.x + rel.y + rel.z)
    GetHeading()
    print("[207]heading acquired: ", Heading)

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

    print("[240]mining ", xblocks, "blocks in the ", Heading, " direction")
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

    print("[282]mining ", zblocks, "blocks in the ", Heading, " direction")
    Mine(zblocks, strip)

    yblocks = math.abs(rel.y)

    if rel.y < 0 then
        local move = 0

        print("[290]mining ", yblocks, "blocks in the -y direction")

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

        print("[304]mining ", yblocks, "blocks in the y direction")

        while move < yblocks do
            while turtle.detectUp() do
                turtle.digUp()
                turtle.suckUp()
            end

            assert(turtle.up())
            move = move + 1
        end
    end
end

function GoHome()

    GoThere(Home.x, Home.y, Home.z, false)

end

local function startup()
    Home = {}
    local item, necessaryItems = {}, {}

    io.write("Startup sequence for mining turtle. Use current location as home base? (y/[provide xyz coordinates])\n")
    local incomplete = true
    while incomplete do
        local ans = io.read()
        if ans == "y" or ans == "Y" then
            Home.x, Home.y, Home.z = gps.locate()
            if not Home.x then
                Home = noGPS("xyz")
            end
            incomplete = false
        else
            Home = luaTools.argparse(ans, {"x", "y", "z"})

            incomplete = false
            for _, coord in pairs(Home) do
                if type(coord) ~= "number" then
                    io.write("Input must be numbers\n")
                    incomplete = true
                end
            end

            GoThere(Home.x, Home.y, Home.z)
        end
    end
    -- write code here to setup Home base
    incomplete = true
    while incomplete do
        for slot = 1, 16 do
            turtle.select(slot)
            item = turtle.getItemDetail(slot)
            if item then
                if luaTools.tableContainsValue(_INVS, item.name) then
                    incomplete = false
                end
            end
        end
        if incomplete then
            io.write("Insert a valid inventory item to begin")
            os.pullEvent("turtle_inventory")
        end
    end

    io.write("Home base registered. please select a command\n")
    local options = {"mine", "move", "check fuel"}
    textutils.tabulate(options)
    io.write("\n")

    local cmd = io.read()

    if cmd == "mine" then
        incomplete = true
        local coords1, coords2, quarrySize, fuelNeeded = {}, {}, {}, {}
        local ysign, zsign, cycle, endcycle, h, layer, endlayer, emptySlot = 0, 0, 0, 0, 0, 0, 0, 0

        io.write("first coordinates: ")

        while incomplete do
            coords1 = luaTools.argparse(io.read(), {"x", "y", "z"})

            incomplete = false
            for _, coord in pairs(coords1) do
                if type(coord) ~= "number" then
                    io.write("Input must be numbers\n")
                    incomplete = true
                end
            end
        end

        incomplete = true
        io.write("second coordinates: ")

        while incomplete do
            coords2 = luaTools.argparse(io.read(), {"x", "y", "z"})

            incomplete = false
            for _, coord in pairs(coords2) do
                if type(coord) ~= "number" then
                    io.write("Input must be numbers\n")
                    incomplete = true
                end
            end
        end

        quarrySize = {
            x = math.abs(coords2.x - coords1.x) + 1,
            y = math.abs(coords2.y - coords1.y) + 1,
            z = math.abs(coords2.z - coords1.z) + 1
        }

        if coords2.z - coords1.z > 0 then
            zsign = 1
        elseif coords2.z - coords1.z < 0 then
            zsign = -1
        end
        if coords2.y - coords1.y > 0 then
            ysign = 1
        elseif coords2.y - coords1.y < 0 then
            ysign = -1
        end

        Patterns = {
            [1] = {
                {coords2.x, coords1.y, coords1.z + zsign * (6 * cycle + 3)},
                {coords1.x, coords1.y, coords1.z + zsign * (6 * cycle + 6)}
            },
            [2] = {
                {coords2.x, coords1.y + ysign * 1, coords1.z + zsign * (4 * cycle + 2)},
                {coords1.x, coords1.y, coords1.z + zsign * (4 * cycle + 4)}
            },
            [3] = {
                {coords2.x, coords1.y + ysign * 2, coords1.z + zsign * (5 * cycle + 1)},
                {coords1.x, coords1.y + ysign * 1, coords1.z + zsign * (5 * cycle + 3)},
                {coords2.x, coords1.y, coords1.z + zsign * (5 * cycle + 5)},
                {coords1.x, coords1.y + ysign * 2, coords1.z + zsign * (5 * cycle + 6)},
                {coords2.x, coords1.y + ysign * 1, coords1.z + zsign * (5 * cycle + 8)},
                {coords1.x, coords1.y, coords1.z + zsign * (5 * cycle + 10)}
            },
            [4] = {
                {coords2.x, coords1.y + ysign * 3, coords1.z + zsign * (7 * cycle)},
                {coords1.x, coords1.y + ysign * 2, coords1.z + zsign * (7 * cycle + 2)},
                {coords2.x, coords1.y , coords1.z + zsign * (7 * cycle + 3)},
                {coords1.x, coords1.y + ysign * 3, coords1.z + zsign * (7 * cycle + 4)},
                {coords2.x, coords1.y + ysign * 1, coords1.z + zsign * (7 * cycle + 5)},
                {coords1.x, coords1.y, coords1.z + zsign * (7 * cycle + 7)}
            },
            [5] = {
                {coords2.x, coords1.y + ysign * (5 * layer + 2), coords1.z + zsign * (5 * cycle + 1)},
                {coords1.x, coords1.y + ysign * (5 * layer + 4), coords1.z + zsign * (5 * cycle + 2)},
                {coords2.x, coords1.y + ysign * (5 * layer + 1), coords1.z + zsign * (5 * cycle + 3)},
                {coords1.x, coords1.y + ysign * (5 * layer + 3), coords1.z + zsign * (5 * cycle + 4)},
                {coords2.x, coords1.y + ysign * (5 * layer), coords1.z + zsign * (5 * cycle + 5)},
                {coords1.x, coords1.y + ysign * (5 * layer + 2), coords1.z + zsign * (5 * cycle + 6)},
                {coords2.x, coords1.y + ysign * (5 * layer + 4), coords1.z + zsign * (5 * cycle + 7)},
                {coords1.x, coords1.y + ysign * (5 * layer + 1), coords1.z + zsign * (5 * cycle + 8)},
                {coords2.x, coords1.y + ysign * (5 * layer + 3), coords1.z + zsign * (5 * cycle + 9)},
                {coords1.x, coords1.y + ysign * (5 * layer), coords1.z + zsign * (5 * cycle + 10)}
            }
    }

        if quarrySize.y == 1 then
            endcycle = math.floor(quarrySize / 6)
        elseif quarrySize.y == 2 then
            endcycle = math.floor(quarrySize.z / 4)
        elseif quarrySize.y == 3 then
            endcycle = math.floor(quarrySize.z / 10)
        elseif quarrySize.y == 4 then
            endcycle = math.floor(quarrySize.z / 7)
        else
            endcycle = math.floor(quarrySize.z / 10)
        end

        h = math.min(quarrySize.y, 5)
        endlayer = math.floor(quarrySize.y / h)

        GoThere(coords1.x, coords1.y, coords1.z, false)

        fuelNeeded = {
            [1] = endlayer * endcycle * (quarrySize.x + 3),
            [2] = endlayer * endcycle * (2 * quarrySize.x + 6),
            [3] = endlayer * endcycle * (3 * quarrySize.x + 9),
            [4] = endlayer * endcycle * (6 * quarrySize.x + 19),
            [5] = endlayer * endcycle * (5 * quarrySize.x + 17)
        }

        checkFuel(fuelNeeded[h])

        while layer < endlayer do
            print("[490}layer = ]" .. layer)
            while cycle < endcycle do
                print("[492]cycle = " .. cycle)
                for _, pattern in pairs(Patterns[h]) do
                    GoThere(pattern[1], pattern[2], pattern[3], true)
                end
                cycle = cycle + 1

                for slot = 1, 16 do
                    if not turtle.getItemDetail(slot) then
                        emptySlot = emptySlot + 1
                    end
                    slot = slot + 1
                end
                if emptySlot <= 3 then
                    GoHome()
                end

            end
            layer = layer + 1
        end

    elseif cmd == "move" then

    elseif cmd == "check fuel" then

    else
        io.write("Couldn't recognize input")
    end
end

startup()