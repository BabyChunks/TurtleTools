Coords = {}
Heading  = nil

local function noGPS() --manually enter xz or xyz coords
    local format, ans = "", ""
    local keys, coords = {}, {}
    local err = false

    ans = Comms.sendStatus("Could not locate turtle using gps. Input coordinates (xyz) manually or press Enter to terminate", true)
    local incomplete = true

    while incomplete do
        ans = io.read()
        term.clear()
        term.setCursorPos(1,1)
        if ans == "" then
            os.queueEvent("terminate")
        end

        err, coords = pcall(Lt.argparse, ans, keys)
        if err then
            incomplete = false
            for _, coord in pairs(coords) do
                if type(coord) ~= "number" then
                    print("Input must be numbers")
                    incomplete = true
                    break
                end
            end
        else
            io.write(coords .. "\n")
        end
    end
    return vector.new(table.unpack(coords))
end

local function checkFuel(fuelNeeded)
    local item = {}
    local currFuel = turtle.getFuelLevel()

    while currFuel < fuelNeeded do
        for slot = 1, NSLOTS do
            item = turtle.getItemDetail(slot)
            if item then
                if Lt.tableContainsValue(St.FUELS, item.name) then
                    turtle.select(slot)
                    turtle.refuel()
                    os.queueEvent("buffer")
                    currFuel = turtle.getFuelLevel()
                end
            end
        end
        if  currFuel < fuelNeeded then
            print("Unsufficient fuel. Add " .. fuelNeeded - currFuel .. " fuel units to turtle's inventory")
            os.pullEvent("turtle_inventory")
        end
    end
    term.clear()
    term.setCursorPos(1,1)
end

local function getHeading(turn) --set or get Heading to turtle's current heading on the x-z plane. Requires gps
    if not Heading then
        local coords2 = {}

        checkFuel(2)

        if turtle.detect() then
            turtle.dig()
            turtle.suck()
        end
        assert(turtle.forward())

        coords2 = vector.new(gps.locate())
        if not delta.x then
            delta = noGPS("xz")
        end
        assert(turtle.back())

        local delta = coords2:sub(Coords)

        local headingMatrix = {
            ["x"] = delta.x > 0,
            ["-x"] = delta.x < 0,
            ["z"] = delta.z > 0,
            ["-z"] = delta.z < 0
        }

        Heading = Lt.getKeyforValue(headingMatrix, true)
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
            i = Lt.getKeyForValue(compass, Heading) + 1

        elseif turn == "left" then
            i = Lt.getKeyForValue(compass, Heading) - 1

        end

        if i == 4 then i = 0
        elseif i == -1 then i = 4 end

        Heading = compass[i]
    end
end

local function goThere(x, y, z, strip) -- main function for navigation. Uses absolute coords to navigate
    strip = strip or false
    local delta = {}
    local xblocks, yblocks, zblocks = 0, 0, 0

    dest = vector.new(x, y, z)

    delta = dest:sub(Coords)

    checkFuel(delta.x + delta.y + delta.z)

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

    Tt.tunnel(xblocks, strip)

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

    Tt.tunnel(zblocks, strip)

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

local function buildArray()
    local base = {}
    local err = false

    io.write("Setting up a GPS array. Please input base coordinates.\n")
    local incomplete = true
    while incomplete do
        err, base = pcall(Lt.argparse, io.read(), {"x", "y", "z"})
        if err then
            incomplete = false
            for _, coord in pairs(base) do
                if type(coord) ~= "number" then
                    io.write("Input must be numbers\n")
                    incomplete = true
                    break
                end
            end
        else
            io.write(base .. "\n")
        end
    end

    goThere(base.x, base.y, base.z)

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
                    if Lt.tableContainsValue(part.names, item.name) then
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
end

return {
    noGPS =  noGPS,
    checkFuel = checkFuel,
    getHeading = getHeading,
    goThere = goThere,
    buildArray = buildArray
}