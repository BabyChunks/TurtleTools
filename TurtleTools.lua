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

        Args = {}

        for arg in string.gmatch(ans, "-?%d+") do
            table.insert(Args, tonumber(arg))
        end
        if #Args == 0 then
            io.write("Input must be numbers\n")
        elseif #Args ~= #Keys then
            io.write("Incorrect number of arguments\n")
        else
            incomplete = false
        end
    end
    for i, key in pairs(Keys) do
        coords[key] = Args[i]
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
        print("[50]first coords: ", coords1.x, coords1.z)

        if turtle.detect() then
            print("[53]block detected in front of turtle")
            turtle.dig()
            turtle.suck()
        end
        if turtle.forward() then
            print("[58]moving forward...")
        else
            error("GetHeading() terminated: not enough fuel")
        end

        local coords2 = {}
        coords2.x, _, coords2.z = gps.locate()
        if not coords2.x then
            coords2 = noGPS("xz")
        end
        print("[68]second coords: ", coords2.x, coords2.z) _ = io.read()

        if turtle.back() then
            print("[71]moving back...")
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
    print("[109]entered new inspectAll() routine")
    local block, blockdata = turtle.inspectUp()
    if block then
        print("[112]block detected above")
        if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
            print("[114]block is an ore")
            MineChunk("up")
            turtle.down()
            print("[117]ended MineChunk() routine, moving back down")
        end
    end
    local block, blockdata = turtle.inspectDown()
    if block then
        print("[122]block detected below")
        if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
            print("[124]block is an ore")
            MineChunk("down")
            turtle.up()
            print("[127]ended MineChunk() routine, moving back up")
        end
    end
    for turn = 1,4 do
        local block, blockdata = turtle.inspect()
        if block then
            print("[133]block detected forward")
            if luaTools.tableContainsKey(blockdata.tags, "forge:ores") then
                print("[135]block is an ore")
                MineChunk()
                turtle.back()
                print("[138]ended MineChunk() routine, moving back")
            end
        end
        turtle.turnRight()
        GetHeading("right")
        turn = turn + 1
        print("[144]turning right. heading is now = ", Heading)
    end
    print("[146]completed a turn. Ending inspectAll()")
end

function MineChunk(target) --internal use with Mine(), detects and mines ore blocks while keeping track of steps
    if target == "up" then
        turtle.digUp()
        turtle.suckUp()
        turtle.up()
        print("[154]mining and moving up")
        inspectAll()
    elseif target == "down" then
        turtle.digDown()
        turtle.suckDown()
        turtle.down()
        print("[160]mining and moving down")
        inspectAll()
    else
        turtle.dig()
        turtle.suck()
        turtle.forward()
        print("[166]mining and moving forward")
        inspectAll()
    end
end

function Mine(blocks, strip) -- Mine in a straight line for a number of blocks. Specify strip if turtle should evaluate every adjacent block for strip mining
    strip = strip or false
    print("[173]beginning sequence to mine ", blocks, " blocks")

    GetHeading()
    print("[176]heading acquired: ", Heading)

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
        print("[190]initial inspectAll() terminated. Moving forward")
    end
end

function GoThere(x, y, z, strip) -- main function for navigation. Specify heading if known.
    print("[195]Starting sequence to move to coords:", x, y, z)
    strip = strip or false

    local bot = {}
    bot.x, bot.y, bot.z = gps.locate()
    if not bot.x then
        bot = noGPS("xyz")
    end

    print("[203]turtle location acquired: ", bot.x, bot.y, bot.z)

    local rel = {
        x = (x - bot.x),
        y = (y - bot.y),
        z = (z - bot.z)
    }
    print("[210]computed movement necessary:")
    print("x= ", rel.x)
    print("y= ", rel.y)
    print("z= ", rel.z)

    if not Heading then
        print("[216]heading unknown. searching heading...")
        GetHeading()
        print("[218]heading acquired: ", Heading)
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

    print("[256]mining ", xblocks, "blocks in the ", Heading, " direction")
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

    print("[299]mining ", zblocks, "blocks in the ", Heading, " direction")
    Mine(zblocks, strip)
    
    local yblocks = math.abs(rel.y)

    if rel.y < 0 then
        local move = 0

        print("[355]mining ", yblocks, "blocks in the -y direction")

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

        print("[368]mining ", yblocks, "blocks in the y direction")

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