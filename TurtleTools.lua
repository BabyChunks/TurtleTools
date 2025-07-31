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
        print("first coords: ", coords1.x, coords1.z)

        if turtle.detect() then
            print("block detected in front of turtle")
            turtle.dig()
            turtle.suck()
        end
        if turtle.forward() then
            print("moving forward...")
        else
            error("GetHeading() terminated: not enough fuel")
        end

        local coords2 = {}
        coords2.x, _, coords2.z = gps.locate()
        if not coords2.x then
            coords2 = noGPS("xz")
        end
        print("second coords: ", coords2.x, coords2.z)

        if turtle.back() then
            print("moving back...")
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
        print("Heading = ", Heading, "\n turn = ", turn)
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
    local block, blockdata = turtle.inspectUp()
    if block then
        for tag, _ in pairs(blockdata.tags) do
            if string.find(tag, "forge:ores") then
                MineChunk("up")
                turtle.down()
            end
        end
    end
    local block, blockdata = turtle.inspectDown()
    if block then
        for tag, _ in pairs(blockdata.tags) do
            if string.find(tag,"forge:ores") then
                MineChunk("down")
                turtle.up()
            end
        end
    end
    for turn = 1,3 do
        local block, blockdata = turtle.inspect()
        if block then
            for tag, _ in pairs(blockdata.tags) do
                if string.find(tag, "forge:ores") then
                    MineChunk()
                    turtle.back()
                end
            end
        end
        turtle.turnRight()
        GetHeading("right")
        turn = turn + 1
    end
    turtle.turnRight()
    GetHeading("right")
end

function MineChunk(target) --internal use with Mine(), detects and mines ore blocks while keeping track of steps
    if target == "up" then
        turtle.digUp()
        turtle.suckUp()
        turtle.up()
        inspectAll()
        turtle.down()
    elseif target == "down" then
        turtle.digDown()
        turtle.suckDown()
        turtle.down()
        inspectAll()
        turtle.up()
    else
        turtle.dig()
        turtle.suck()
        turtle.forward()
        inspectAll()
        turtle.back()
    end
end

function Mine(blocks, strip) -- Mine in a straight line for a number of blocks. Specify strip if turtle should evaluate every adjacent block for strip mining
    strip = strip or false

    local move = 0
    while move < blocks do

        if strip then
            GetHeading()

            inspectAll()
        end
        while turtle.detect() do
            turtle.dig()
            turtle.suck()
        end
        turtle.forward()
        move = move + 1
    end
end

function GoThere(x, y, z) -- main function for navigation. Specify heading if known.
    print("Starting sequence to move to coords:", x, y, z)

    local bot = {}
    bot.x, bot.y, bot.z = gps.locate()
    if not bot.x then
        bot = noGPS("xyz")
    end

    print("turtle location acquired: ", bot.x, bot.y, bot.z)

    local rel = {
        x = (x - bot.x),
        y = (y - bot.y),
        z = (z - bot.z)
    }
    print("computed movement necessary:")
    print("x= ", rel.x)
    print("y= ", rel.y)
    print("z= ", rel.z)

    if not Heading then
        print("heading unknown. searching heading...")
        GetHeading()
        print("heading acquired: ", Heading)
    end

    local xblocks = math.abs(rel.x)

    if rel.x < 0 then
        if Heading == "x" then
            turtle.turnRight()
            turtle.turnRight()

            print("mining ", blocks, "blocks in the -x direction")
            Mine(xblocks)

        elseif Heading == "-x" then

            print("mining ", xblocks, "blocks in the -x direction")
            Mine(xblocks)

        elseif Heading == "z" then

            turtle.turnRight()

            print("mining ", xblocks, "blocks in the -x direction")
            Mine(xblocks)

        elseif Heading == "-z" then

            turtle.turnLeft()

            print("mining ", xblocks, "blocks in the -x direction")
            Mine(xblocks)
        end

        Heading = "-x"

    elseif rel.x > 0 then
        if Heading == "x" then

            print("mining ", xblocks, "blocks in the x direction")
            Mine(xblocks)

        elseif Heading == "-x" then

            turtle.turnRight()
            turtle.turnRight()

            print("mining ", xblocks, "blocks in the x direction")
            Mine(xblocks)

        elseif Heading == "z" then

            turtle.turnLeft()

            print("mining ", xblocks, "blocks in the x direction")
            Mine(xblocks)

        elseif Heading == "-z" then

            turtle.turnRight()

            print("mining ", xblocks, "blocks in the x direction")
            Mine(xblocks)
        end

        Heading = "x"
    end

    local zblocks = math.abs(rel.z)

    if rel.z < 0 then
        if Heading == "z" then
            turtle.turnRight()
            turtle.turnRight()

            print("mining ", zblocks, "blocks in the -z direction")
            Mine(zblocks)

        elseif Heading == "-z" then

            print("mining ", zblocks, "blocks in the -z direction")
            Mine(zblocks)

        elseif Heading == "x" then

            turtle.turnLeft()

            print("mining ", zblocks, "blocks in the -z direction")
            Mine(zblocks)

        elseif Heading == "-x" then

            turtle.turnRight()

            print("mining ", zblocks, "blocks in the -z direction")
            Mine(zblocks)

        end

        Heading = "-z"

    elseif rel.z > 0 then
        if Heading == "z" then

            print("mining ", zblocks, "blocks in the z direction")
            Mine(zblocks)

        elseif Heading == "-z" then

            turtle.turnRight()
            turtle.turnRight()

            print("mining ", zblocks, "blocks in the z direction")
            Mine(zblocks)

        elseif Heading == "x" then

            turtle.turnRight()

            print("mining ", zblocks, "blocks in the z direction")
            Mine(zblocks)

        elseif Heading == "-x" then

            turtle.turnLeft()

            print("mining ", zblocks, "blocks in the z direction")
            Mine(zblocks)
        end

        Heading = "z"
    end

    local yblocks = math.abs(rel.y)

    if rel.y < 0 then
        local move = 0

        print("mining ", yblocks, "blocks in the -y direction")

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

        print("mining ", yblocks, "blocks in the y direction")

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

print(luaTools.t, luaTools.test())
--Mine(10, true)
