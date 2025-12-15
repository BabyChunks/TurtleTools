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
    return table.unpack(coords)
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

local function sumAbsVectorComponents(v)
    return math.abs(v.x) + math.abs(v.y) + math.abs(v.z)
end

local function setHeading(turn) --set Heading to turtle's current heading on the x-z plane. Requires gps
    if not Heading then
        local coords2 = {}

        checkFuel(2)

        while turtle.detect() do
            turtle.dig()
            turtle.suck()
        end
        assert(turtle.forward())

        coords2 = vector.new(locate())
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

local function setCoords(move)
    local orientationMatrix = {
        ["x"] = function() Coords.x = Coords.x + move end,
        ["-x"] = function() Coords.x = Coords.x - move end,
        ["z"] = function() Coords.z = Coords.z + move end,
        ["-z"] = function() Coords.z = Coords.z - move end
    }
    orientationMatrix[Heading]()
end

local function turnRight()
    assert(turtle.turnRight())
    setHeading("right")
end

local function turnLeft()
    assert(turtle.turnLeft())
    setHeading("left")
end

local function forward()
    while turtle.detect() do 
        if isProtectedBlock() then
            circumvent()
        end
        turtle.dig()
        turtle.suck()
    end
    assert(turtle.forward())
    setCoords(1)
end

local function back()
    assert(turtle.back())
    setCoords(-1)
end

local function up()
    
end

local function down()

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
            ["-x"] = {turnRight, turnRight},
            ["z"] = {turnLeft},
            ["-z"] = {turnRight}
        },
        [-1] = {
            ["x"] = {turnRight, turnRight},
            ["-x"] = {},
            ["z"] = {turnRight},
            ["-z"] = {turnLeft}
        },
        },
        z = {
        [1] = {
            ["x"] = {turnRight},
            ["-x"] = {turnLeft},
            ["z"] = {},
            ["-z"] = {turnRight, turnRight}
        },
        [-1] = {
            ["x"] = {turnLeft},
            ["-x"] = {turnRight},
            ["z"] = {turnRight, turnRight},
            ["-z"] = {}
        },
        }
    }

    if delta.rel.x ~= 0 then
        local oMx = orientationMatrix.x[delta.rel.x / delta.abs.x]
        for _, action in ipairs(oMx[Heading]) do
            action()
        end
        local steer = function() for k, v in pairs(oMx) do if next(v) == nil then return k end end end
        Heading = steer()
        Tt.tunnel(delta.abs.x, strip)
    end

    if delta.rel.z ~= 0 then
        local oMz = orientationMatrix.z[delta.rel.z / delta.abs.z]
        for _, action in ipairs(oMz[Heading]) do
            action()
        end
        local steer = function() for k, v in pairs(oMz) do if next(v) == nil then return k end end end
        Heading = steer()
        Tt.tunnel(delta.abs.z, strip)
    end

    if delta.rel.y < 0 then
        local move = 0

        while move < delta.abs.y do
            while turtle.detectDown() do
                turtle.digDown()
                turtle.suckDown()
            end

            assert(turtle.down())
            move = move + 1
        end
    elseif delta.rel.y > 0 then
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
    base = vector.new(handleCoordsInput(io.read()))

    goThere(base)

    local partsNeeded = {
        [1] = {names = {"computercraft:computer_normal", "computercraft:computer_advanced"}, n = 4, check = false},
        [2] = {names = {"computercraft:wireless_modem_normal", "computercraft:wireless_modem_advanced"}, n = 4, check = false},
        [3] = {names = {"computercraft:wired_modem"}, n = 6, check = false},
        [4] = {names = {"computercraft:cable"}, n = 9, check = false}
    }

    local incomplete = true
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

Coords = vector.new(locate())

setHeading()

return {
    locate = locate,
    checkFuel = checkFuel,
    getVectorComponents = getVectorComponents,
    sumAbsVectorComponents = sumAbsVectorComponents,
    setHeading = setHeading,
    turnRight = turnRight,
    turnLeft = turnLeft,
    goThere = goThere,
    buildArray = buildArray
}