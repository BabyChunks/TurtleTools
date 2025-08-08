local luaTools = require("LuaTools")

Heading = nil

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
        print("[46]first coords: " .. coords1.x .. coords1.z)

        if turtle.detect() then
            print("[49]block detected in front of turtle")
            turtle.dig()
            turtle.suck()
        end
        if turtle.forward() then
            print("[54]moving forward...")
        else
            error("GetHeading() terminated: not enough fuel")
        end

        coords2.x, _, coords2.z = gps.locate()
        if not coords2.x then
            coords2 = noGPS("xz")
        end
        print("[63]second coords: ", coords2.x, coords2.z)

        if turtle.back() then
            print("[66]moving back...")
        else
            error("GetHeading() terminated: not enough fuel")
        end

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

local function inspectAll() --in tandem with MineChunk(). Inspects adjacent blocks and enters a MineChunk() instance if ore is found
    print("[105]entered new inspectAll() routine")
    local block, blockdata = turtle.inspectUp()
    if block then
        print("[108]block detected above")
        if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
            print("[110]block is an ore")
            MineChunk("up")
            turtle.down()
            print("[113]ended MineChunk() routine, moving back down")
        end
    end
    block, blockdata = turtle.inspectDown()
    if block then
        print("[118]block detected below")
        if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
            print("[120]block is an ore")
            MineChunk("down")
            turtle.up()
            print("[123]ended MineChunk() routine, moving back up")
        end
    end
    for turn = 1,4 do
        block, blockdata = turtle.inspect()
        if block then
            print("[129]block detected forward")
            if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
                print("[131]block is an ore")
                MineChunk()
                turtle.back()
                print("[134]ended MineChunk() routine, moving back")
            end
        end
        turtle.turnRight()
        GetHeading("right")
        turn = turn + 1
        print("[140]turning right. heading is now = ", Heading)
    end
    print("[142]completed a turn. Ending inspectAll()")
end

function MineChunk(target) --in tandem with inspectAll(). Mine ore block, move into block space and initialize new inspectAll() instance
    if target == "up" then
        turtle.digUp()
        turtle.suckUp()
        turtle.up()
        print("[150]mining and moving up")
        inspectAll()
    elseif target == "down" then
        turtle.digDown()
        turtle.suckDown()
        turtle.down()
        print("[156]mining and moving down")
        inspectAll()
    else
        turtle.dig()
        turtle.suck()
        turtle.forward()
        print("[162]mining and moving forward")
        inspectAll()
    end
end

function Mine(blocks, strip) -- Mine in a straight line for a number of blocks. Specify strip if turtle should evaluate every adjacent block for strip mining
    strip = strip or false
    local move = 0

    print("[171]beginning sequence to mine ", blocks, " blocks")

    GetHeading()
    print("[174]heading acquired: ", Heading)

    while move < blocks do

        if strip then
            inspectAll()
            print("[180]initial inspectAll() terminated. Moving forward")
        end
        while turtle.detect() do
            turtle.dig()
            turtle.suck()
        end
        turtle.forward()
        move = move + 1
    end
end

function GoThere(x, y, z, strip) -- main function for navigation. Specify heading if known.
    print("[192]Starting sequence to move to coords:", x, y, z)
    strip = strip or false
    local bot, rel = {}, {}
    local xblocks, yblocks, zblocks = 0, 0, 0

    bot.x, bot.y, bot.z = gps.locate()
    if not bot.x then
        bot = noGPS("xyz")
    end

    print("[202]turtle location acquired: ", bot.x, bot.y, bot.z)

    rel = {
        x = (x - bot.x),
        y = (y - bot.y),
        z = (z - bot.z)
    }
    print("[209]computed movement necessary:")
    print("x= ", rel.x)
    print("y= ", rel.y)
    print("z= ", rel.z)

    GetHeading()
    print("[215]heading acquired: ", Heading)

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

    print("[248]mining ", xblocks, "blocks in the ", Heading, " direction")
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
        if Heading == "z" then

        elseif Heading == "-z" then

            turtle.turnRight()
            turtle.turnRight()

        elseif Heading == "x" then

            turtle.turnRight()

        elseif Heading == "-x" then

            turtle.turnLeft()
        end

        Heading = "z"
    end

    print("[290]mining ", zblocks, "blocks in the ", Heading, " direction")
    Mine(zblocks, strip)

    yblocks = math.abs(rel.y)

    if rel.y < 0 then
        local move = 0

        print("[298]mining ", yblocks, "blocks in the -y direction")

        while move < yblocks do
            while turtle.detectDown() do
                turtle.digDown()
                turtle.suckDown()
            end

            turtle.down()
            move = move + 1
        end
    elseif rel.y > 0 then
        local move = 0

        print("[312]mining ", yblocks, "blocks in the y direction")

        while move < yblocks do
            while turtle.detectUp() do
                turtle.digUp()
                turtle.suckUp()
            end

            turtle.up()
            move = move + 1
        end
    end
end

local function startup()
    Home = {}

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
        end
    end

    io.write("Home base registered. please select a command\n")
    local options = {"mine", "move", "check fuel"}
    textutils.tabulate(options)
    io.write("\n")

    local cmd = io.read()

    if cmd == "mine" then
        incomplete = true
        local coords1, coords2, quarrySize = {}, {}, {}
        local ysign, zsign, cycle, endcycle, h, layer, endlayer = 0, 0, 0, 0, 0, 0, 0

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
                {coords1.x, coords1.y + ysign * 2, coords1.z + zsign * (5 * cycle + 1)},
                {coords2.x, coords1.y + ysign * 1, coords1.z + zsign * (5 * cycle + 3)},
                {coords1.x, coords1.y, coords1.z + zsign * (5 * cycle + 5)}
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
                {coords1.x, coords1.y + ysign * 2 * (5 * layer + 2), coords1.z + zsign * 2 * (5 * cycle + 1)},
                {coords2.x, coords1.y + ysign * 2 * (5 * layer + 4), coords1.z + zsign * 2 * (5 * cycle + 2)},
                {coords1.x, coords1.y + ysign * 2 * (5 * layer + 1), coords1.z + zsign * 2 * (5 * cycle + 3)},
                {coords2.x, coords1.y + ysign * 2 * (5 * layer + 3), coords1.z + zsign * 2 * (5 * cycle + 4)},
                {coords1.x, coords1.y + ysign * 2 * (5 * layer), coords1.z + zsign * 2 * (5 * cycle + 5)}
            }
    }

        if quarrySize.y == 1 then
            endcycle = math.floor(quarrySize / 3)
        elseif quarrySize.y == 2 then
            endcycle = math.floor(quarrySize.z / 4)
        elseif quarrySize.y == 3 then
            endcycle = math.floor(quarrySize.z / 5)
        elseif quarrySize.y == 4 then
            endcycle = math.floor(quarrySize.z / 7)
        else
            endcycle = math.floor(quarrySize.z / 5)
        end

        h = math.min(quarrySize.y, 5)
        endlayer = math.floor(quarrySize.y / h)

        GoThere(coords1.x, coords1.y, coords1.z, false)

        while layer < endlayer do
            while cycle < endcycle do
                print("cycle = " .. cycle)
                for _, pattern in pairs(Patterns[h]) do
                    GoThere(pattern[1], pattern[2], pattern[3], true)
                end
                cycle = cycle + 1
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