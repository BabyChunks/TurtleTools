local luaTools = require("LuaTools")

local function noGPS(dim)
    if dim == "xyz" then
        Format = "x, y, z"
        Keys = {"x", "y", "z"}
    elseif dim == "xz" then
        Format = "x, z"
        Keys = {"x", "z"}
    end

    io.write("Could not locate turtle using gps. Input coordinates (", Format, ") manually or press Enter to terminate\n")
    local incomplete = true
    local coords = {}

    while incomplete do
        local ans = io.read()
        if ans == "" then
            os.reboot()
        end

        coords = luaTools.argparse(ans, Keys)

        for _, coord in pairs(coords) do
            if type(coord) ~= "number" then
                io.write("Input must be numbers\n")
                incomplete = true
            end
        end
    end
    return coords
end

Heading = nil

function GetHeading(turn) --set or get Heading to turtle's current heading on the x-z plane. Requires gps
    if not Heading then
        local coords1 = {}
        coords1.x, _, coords1.z = gps.locate()
        if not coords1.x then
            coords1 = noGPS("xz")
        end
        print("[44]first coords: ", coords1.x, coords1.z)

        if turtle.detect() then
            print("[47]block detected in front of turtle")
            turtle.dig()
            turtle.suck()
        end
        if turtle.forward() then
            print("[52]moving forward...")
        else
            error("GetHeading() terminated: not enough fuel")
        end

        local coords2 = {}
        coords2.x, _, coords2.z = gps.locate()
        if not coords2.x then
            coords2 = noGPS("xz")
        end
        print("[62]second coords: ", coords2.x, coords2.z) _ = io.read()

        if turtle.back() then
            print("[65]moving back...")
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

local function inspectAll()
    print("[103]entered new inspectAll() routine")
    local block, blockdata = turtle.inspectUp()
    if block then
        print("[106]block detected above")
        if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
            print("[108]block is an ore")
            MineChunk("up")
            turtle.down()
            print("[111]ended MineChunk() routine, moving back down")
        end
    end
    local block, blockdata = turtle.inspectDown()
    if block then
        print("[116]block detected below")
        if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
            print("[118]block is an ore")
            MineChunk("down")
            turtle.up()
            print("[121]ended MineChunk() routine, moving back up")
        end
    end
    for turn = 1,4 do
        local block, blockdata = turtle.inspect()
        if block then
            print("[127]block detected forward")
            if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
                print("[129]block is an ore")
                MineChunk()
                turtle.back()
                print("[132]ended MineChunk() routine, moving back")
            end
        end
        turtle.turnRight()
        GetHeading("right")
        turn = turn + 1
        print("[138]turning right. heading is now = ", Heading)
    end
    print("[140]completed a turn. Ending inspectAll()")
end

function MineChunk(target) --internal use with Mine(), detects and mines ore blocks while keeping track of steps
    if target == "up" then
        turtle.digUp()
        turtle.suckUp()
        turtle.up()
        print("[148]mining and moving up")
        inspectAll()
    elseif target == "down" then
        turtle.digDown()
        turtle.suckDown()
        turtle.down()
        print("[154]mining and moving down")
        inspectAll()
    else
        turtle.dig()
        turtle.suck()
        turtle.forward()
        print("[160]mining and moving forward")
        inspectAll()
    end
end

function Mine(blocks, strip) -- Mine in a straight line for a number of blocks. Specify strip if turtle should evaluate every adjacent block for strip mining
    strip = strip or false
    print("[167]beginning sequence to mine ", blocks, " blocks")

    GetHeading()
    print("[170]heading acquired: ", Heading)

    local move = 0
    while move < blocks do

        if strip then
            inspectAll()
        end
        while turtle.detect() do
            turtle.dig()
            turtle.suck()
        end
        turtle.forward()
        move = move + 1
        print("[184]initial inspectAll() terminated. Moving forward")
    end
end

function GoThere(x, y, z, strip) -- main function for navigation. Specify heading if known.
    print("[189]Starting sequence to move to coords:", x, y, z)
    strip = strip or false

    local bot = {}
    bot.x, bot.y, bot.z = gps.locate()
    if not bot.x then
        bot = noGPS("xyz")
    end

    print("[198]turtle location acquired: ", bot.x, bot.y, bot.z)

    local rel = {
        x = (x - bot.x),
        y = (y - bot.y),
        z = (z - bot.z)
    }
    print("[205]computed movement necessary:")
    print("x= ", rel.x)
    print("y= ", rel.y)
    print("z= ", rel.z)

    if not Heading then
        print("[211]heading unknown. searching heading...")
        GetHeading()
        print("[213]heading acquired: ", Heading)
    end

    local xblocks = math.abs(rel.x)

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

    print("[251]mining ", xblocks, "blocks in the ", Heading, " direction")
    Mine(xblocks, strip)

    local zblocks = math.abs(rel.z)

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

    print("[293]mining ", zblocks, "blocks in the ", Heading, " direction")
    Mine(zblocks, strip)

    local yblocks = math.abs(rel.y)

    if rel.y < 0 then
        local move = 0

        print("[300]mining ", yblocks, "blocks in the -y direction")

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

        print("[313]mining ", yblocks, "blocks in the y direction")

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

    io.write("Home base registered. please select a command")
    local options = {"mine", "move", "check fuel"}
    textutils.tabulate(options)
    io.write("\n")

    local cmd = textutils.complete(io.read(), options)

    if cmd == "mine" then
        incomplete = true
        local coords1, coords2 = {}, {}

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

        local quarrySize = {
            x = coords2.x - coords1.x + 1,
            y = coords2.y - coords1.y + 1,
            z = coords2.z - coords1.z + 1
        }

        Patterns = {
            [1] = {
                {coords1.x, coords1.y, coords1.z + (3 * pattern)}
            },
            [2] = {
                {coords2.x, coords1.y, coords1.z},
                {}
            },
            [3] = {},
            [4] = {},
            [5] = {}
    }


    elseif ans == "move" then

    elseif ans == "check fuel" then

    else

    end

end

startup()