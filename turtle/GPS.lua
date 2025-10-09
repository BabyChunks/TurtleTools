Coords = {}
Heading  = nil

local function handleCoordsInput(ans)

    local incomplete, err = true, false
    local coords = {}

    while incomplete do
        term.clear()
        term.setCursorPos(1,1)
        if ans == "" then
            os.queueEvent("terminate")
        end

        err, coords = pcall(Lt.argparse, ans)
        if err then
            incomplete = false
            for _, coord in pairs(coords) do
                if type(coord) ~= "number" then
                    ans = Comms.sendStatus("console",{"Input must be numbers", true})
                    incomplete = true
                    break
                end
            end
        else
            ans = Comms.sendStatus("console", {coords, true})
        end
    end
    return vector.new(table.unpack(coords))
end

local function locate()
    local x, y, z = gps.locate()

    if not x then
        local ans = Comms.sendStatus("console", {"Could not locate computer using gps. Input coordinates (xyz) manually or press Enter to terminate", true})
        return handleCoordsInput(ans)
    end

    return x, y, z
end

local function checkFuel(fuelNeeded)
    local item = {}
    local currFuel = turtle.getFuelLevel()

    while currFuel < fuelNeeded do
        for slot = 1, 16 do
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
            Comms.sendStatus("console",{"Insufficient fuel. Add " .. fuelNeeded - currFuel .. " fuel units to turtle's inventory"})
            os.pullEvent("turtle_inventory")
        end
    end
end

local function getVectorComponents(v)
    return v.x, v.y, v.z
end

local function sumVectorComponents(v)
    return v.x + v.y + v.z
end

local function getHeading(turn) --set or get Heading to turtle's current heading on the x-z plane. Requires gps
    if not Heading then
        local coords2 = {}

        checkFuel(2)

        while turtle.detect() do
            turtle.dig()
            turtle.suck()
        end
        assert(turtle.forward())

        coords2 = vector.new(GPS.locate())
        assert(turtle.back())

        local delta = coords2:sub(Coords)

        local headingMatrix = {
            ["x"] = delta.x > 0,
            ["-x"] = delta.x < 0,
            ["z"] = delta.z > 0,
            ["-z"] = delta.z < 0
        }

        Heading = Lt.getKeyForValue(headingMatrix, true)
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

local function goThere(dest, strip) -- main function for navigation. Uses absolute coords to navigate
    strip = strip or false
    local delta = {}

    delta.rel = dest:sub(Coords)
    delta.abs = {
        x = math.abs(delta.rel.x),
        y = math.abs(delta.rel.y),
        z = math.abs(delta.rel.z)
    }

    checkFuel(Lt.tableSum(delta.abs))

    local orientationMatrix = {
        x = {
        [1] = {
            ["x"] = {},
            ["-x"] = {turtle.turnRight(), turtle.turnRight()},
            ["z"] = {turtle.turnLeft()},
            ["-z"] = {turtle.turnRight()}
        },
        [-1] = {
            ["x"] = {turtle.turnRight(), turtle.turnRight()},
            ["-x"] = {},
            ["z"] = {turtle.turnRight()},
            ["-z"] = {turtle.turnLeft()}
        }
        },
        z = {
        [1] = {
            ["x"] = {turtle.turnRight()},
            ["-x"] = {turtle.turnLeft()},
            ["z"] = {},
            ["-z"] = {turtle.turnRight(), turtle.turnRight()}
        },
        [-1] = {
            ["x"] = {turtle.turnLeft()},
            ["-x"] = {turtle.turnRight()},
            ["z"] = {turtle.turnRight(), turtle.turnRight()},
            ["-z"] = {}
        }
        }
    }

    for action in _, ipairs(orientationMatrix.x[delta.rel.x / delta.abs.x][Heading]) do
        action = action
    end

    Tt.tunnel(delta.abs.x, strip)

    for action in _, ipairs(orientationMatrix.z[delta.rel.z / delta.abs.z][Heading]) do
        action = action
    end

    Tt.tunnel(delta.abs.z, strip)

    -- if delta.rel.x < 0 then
    --     if Heading == "x" then
    --         turtle.turnRight()
    --         turtle.turnRight()

    --     elseif Heading == "z" then
    --         turtle.turnRight()

    --     elseif Heading == "-z" then
    --         turtle.turnLeft()
    --     end

    --     Heading = "-x"

    -- elseif delta.rel.x > 0 then
    --     if Heading == "-x" then
    --         turtle.turnRight()
    --         turtle.turnRight()

    --     elseif Heading == "z" then
    --         turtle.turnLeft()

    --     elseif Heading == "-z" then
    --         turtle.turnRight()
    --     end

    --     Heading = "x"
    -- end

    -- Tt.tunnel(delta.abs.x, strip)

    -- if delta.rel.z < 0 then
    --     if Heading == "z" then
    --         turtle.turnRight()
    --         turtle.turnRight()

    --     elseif Heading == "x" then
    --         turtle.turnLeft()

    --     elseif Heading == "-x" then
    --         turtle.turnRight()

    --     end

    --     Heading = "-z"

    -- elseif delta.rel.z > 0 then
    --     if Heading == "-z" then
    --         turtle.turnRight()
    --         turtle.turnRight()

    --     elseif Heading == "x" then
    --         turtle.turnRight()

    --     elseif Heading == "-x" then
    --         turtle.turnLeft()

    --     end

    --     Heading = "z"
    -- end

    --Tt.tunnel(delta.abs.z, strip)

    if delta.res.y < 0 then
        local move = 0

        while move < delta.abs.y do
            while turtle.detectDown() do
                turtle.digDown()
                turtle.suckDown()
            end

            assert(turtle.down())
            move = move + 1
        end
    elseif delta.res.y > 0 then
        local move = 0

        while move < delta.abs.y do
            while turtle.detectUp() do
                turtle.digUp()
                turtle.suckUp()
            end

            assert(turtle.up())
            move = move + 1
        end
    end
    Coords = dest
end

local function buildArray() -- WIP
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

    goThere(base) -- make base a vector --

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
    locate = locate,
    checkFuel = checkFuel,
    getVectorComponents = getVectorComponents,
    sumVectorComponents = sumVectorComponents,
    getHeading = getHeading,
    goThere = goThere,
    buildArray = buildArray
}