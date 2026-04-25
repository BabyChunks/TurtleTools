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
                    ans = Comms.sendStatus("console",{"Input must be numbers. Received "..type(coord).." type.", true})
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
        elseif i == -1 then i = 3 end

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

local function isProtectedBlock(dir)
    local block, blockdata = false, {}
    if not dir then
        block, blockdata = turtle.inspect()
    elseif dir == "up" then
        block, blockdata = turtle.inspectUp()
    elseif dir == "down" then
        block, blockdata = turtle.inspectDown()
    else error("dir can take 3 values: nil, 'up' and 'down'")
    end
    if block then
        if Lt.tableContainsValue(St.PROTECTED_BLOCKS.names, blockdata.name) then return true end
        for tag, _ in pairs(blockdata.tags) do
            if Lt.tableContainsValue(St.PROTECTED_BLOCKS.tags, tag) then return true end
        end
    end
    return false
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
            error()
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
    while turtle.detectUp() do
        if isProtectedBlock("up") then
            error()
        end
        turtle.digUp()
        turtle.suckUp()
    end
    assert(turtle.up())
    Coords.y = Coords.y + 1
end

local function down()
    while turtle.detectDown() do
        if isProtectedBlock("down") then
            error()
        end
        turtle.digDown()
        turtle.suckDown()
    end
    assert(turtle.down())
    Coords.y = Coords.y - 1
end

local function circumvent()
    if not pcall(forward) then
        turnRight()
        circumvent()
    else
        turnLeft()
    end
end

local function mineVein() --Inspects adjacent blocks and enters a new mineVein() instance if ore is found
    local block, blockdata = turtle.inspectUp()

    if block then
        if Lt.tableContainsKey(blockdata.tags, "forge:ores") then
            up()
            mineVein()
            down()
        end
    end

    block, blockdata = turtle.inspectDown()

    if block then
        if Lt.tableContainsKey(blockdata.tags, "forge:ores") then
            down()
            mineVein()
            up()
        end
    end

    for turn = 1, 4 do
        block, blockdata = turtle.inspect()

        if block then
            if Lt.tableContainsKey(blockdata.tags, "forge:ores") then
                forward()
                mineVein()
                back()
            end
        end

        turnRight()
        turn = turn + 1
    end
end

local function dig(blocks, strip)
    local step = 0
    while step < blocks do
        if strip then
            mineVein()
        end
        if not pcall(forward) then
            local fwAxisCoord, swAxisCoord = 0, 0
            if Heading == "x" then
                fwAxisCoord = Coords.x
                swAxisCoord = Coords.z
                repeat
                    circumvent()
                until swAxisCoord == Coords.z and fwAxisCoord < Coords.x
                step = step + (Coords.x - fwAxisCoord) - 1
            elseif Heading == "-x" then
                fwAxisCoord = Coords.x
                swAxisCoord = Coords.z
                repeat
                    circumvent()
                until swAxisCoord == Coords.z and fwAxisCoord > Coords.x
                step = step + (fwAxisCoord - Coords.x) - 1
            elseif Heading == "z" then
                fwAxisCoord = Coords.z
                swAxisCoord = Coords.x
                repeat
                    circumvent()
                until swAxisCoord == Coords.x and fwAxisCoord < Coords.z
                step = step + (Coords.z - fwAxisCoord) - 1
            elseif Heading == "-z" then
                fwAxisCoord = Coords.z
                swAxisCoord = Coords.x
                repeat
                    circumvent()
                until swAxisCoord == Coords.x and fwAxisCoord > Coords.z
                step = step + (fwAxisCoord - Coords.z) - 1
            end
            turnRight()
            turnRight()
        end
        step = step + 1
    end
end

local function move(delta, strip)
    checkFuel(sumAbsVectorComponents(delta))

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

    if delta.x ~= 0 then
        for _, action in ipairs(orientationMatrix.x[delta.x / math.abs(delta.x)][Heading]) do
            action()
        end
        dig(math.abs(delta.x), strip)
    end

    if delta.z ~= 0 then
        for _, action in ipairs(orientationMatrix.z[delta.z / math.abs(delta.z)][Heading]) do
            action()
        end
        dig(math.abs(delta.z), strip)
    end

    local step = 0

    if delta.y < 0 then
        while step < math.abs(delta.y) do
            if strip then
                mineVein()
            end
            if not pcall(down) then
                local clear = false
                local start = Lt.tableShallowCopy(Coords)
                while clear == false do
                    repeat
                        dig(1)
                    until pcall(down)
                    move(vector.new(start.x - Coords.x, 0, start.z - Coords.z))
                    if Coords.x == start.x and Coords.z == start.x then
                        clear = true
                        step = step + (start.y - Coords.y) - 1
                    end
                end
            end
            step = step + 1
        end
    elseif delta.y > 0 then
        while step < delta.y do
            if strip then
                mineVein()
            end
            if not pcall(up) then
                local clear = false
                local start = Lt.tableShallowCopy(Coords)
                while clear == false do
                    repeat
                        dig(1)
                    until pcall(up)
                    move(vector.new(start.x - Coords.x, 0, start.z - Coords.z))
                    if Coords.x == start.x and Coords.z == start.x then
                        clear = true
                        step = step + (Coords.y - start.y) - 1
                    end
                end
            end
            step = step + 1
        end
    end
end

local function goThere(dest, strip)
    move(dest - Coords, strip)
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

pickEquipped = false
while not pickEquipped do
    local equip = turtle.getEquippedRight() 
    if not equip or not Lt.tableContainsValue(St.PICKAXES, equip.name) then
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item then
                if Lt.tableContainsValue(St.PICKAXES, item.name) then
                    turtle.select(slot)
                    turtle.equipRight()
                    pickEquipped = true
                    break
                end
            end
        end
    else pickEquipped = true
    end
    if not pickEquipped then
        Comms.sendStatus("console", {"Could not find pickaxe on turtle. Place a pickaxe in inventory, or equip it and press Enter to continue.", true})
    end
end

Coords = vector.new(locate())
setHeading()

return {
    handleCoordsInput = handleCoordsInput,
    locate = locate,
    checkFuel = checkFuel,
    getVectorComponents = getVectorComponents,
    sumAbsVectorComponents = sumAbsVectorComponents,
    setHeading = setHeading,
    setCoords = setCoords,
    turnRight = turnRight,
    turnLeft = turnLeft,
    forward = forward,
    back = back,
    up = up,
    down = down,
    mineVein = mineVein,
    dig = dig,
    move = move,
    goThere = goThere,
    buildArray = buildArray
}