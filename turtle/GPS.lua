-- Library for handling positioning and movement of turtle and handle coordinates --

--[[ Utility function to receive a string containing coords in format: "x%y%z"
(where '%' is any whitespace characters or commas) and return single coords in order 
str: str , emptyOK: bool -> num, num, num ]]
local function handleCoordsInput(str, emptyOK)
    local incomplete, err = true, false
    local coords = {}

    while incomplete do
        if emptyOK and str == "" then return str end

        err, coords = pcall(Lt.argparse, str)
        if err then
            incomplete = false
            for _, coord in pairs(coords) do
                if type(coord) ~= "number" then
                    str = Comms.sendStatus("console",{"Input must be numbers. Received "..type(coord).." type.", true})
                    incomplete = true
                    break
                end
            end
            if #coords ~= 3 then
                str = Comms.sendStatus("console", {"Coordinates must be 3-dimensional", true})
                incomplete = true
            end
        else
            str = Comms.sendStatus("console", {coords, true})
        end
    end
    return table.unpack(coords)
end

--[[ Make a call for gps coordinates, or prompt user for manual input of coords if no gps is found 
-> num, num, num ]]
local function locate()
    local x, y, z = gps.locate()

    if not x then
        local str = Comms.sendStatus("console", {"Could not locate computer using gps. Input coordinates (xyz) manually or press Enter to terminate", true})
        if str == "" then os.reboot() end
        return handleCoordsInput(str)
    end

    return x, y, z
end

--[[ Look at current fuel and fuel limit on turtle and send a message for more fuel if insufficient
fuelNeeded: num ]]
local function checkFuel(fuelNeeded)
    local item = {}
    local currFuel = turtle.getFuelLevel()

    if fuelNeeded > turtle.getFuelLimit() then error("turtle can't complete planned route because of fuel capacity.") end

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

--[[ Extract vector xyz components in order 
v: table -> num, num, num]]
local function getVectorComponents(v)
    if not pcall(v:unm()) then error("argument must be Vector type") end
    return v.x, v.y, v.z
end

--[[ From a vector, return the absolute sum of its 3-dimensional components
v: table -> num, num, num ]]
local function sumAbsVectorComponents(v)
    if not pcall(v:unm()) then error("argument must be Vector type") end
    return math.abs(v.x) + math.abs(v.y) + math.abs(v.z)
end

--[[ Retrieve information about the block in front, above or below turtle and run it against 
essential block list from settings file and return true if block is essential
dir: str ["up"|"down"] -> bool]]
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

--[[ set Heading to turtle's current heading on the x-z plane. Requires gps
turn: str ["right"|"left"] ]]
local function setHeading(turn)
    if not Heading then
        local coords2 = {}

        checkFuel(2)

        while turtle.detect() do
            if isProtectedBlock() then
                error("Turtle couldn't go forward: essential block detected")
            end
            turtle.dig()
            turtle.suck()
        end
        assert(turtle.forward(), "Turtle couldn't go forward")
        coords2 = vector.new(locate())
        assert(turtle.back(), "Turtle couldn't go backward")

        local delta = coords2:sub(Coords)

        Heading =
                (delta.x > 0 and "x") or
                (delta.x < 0 and "-x") or
                (delta.z > 0 and "z") or
                (delta.z < 0 and "-z")
    end
    if turn then
        local i = 0

        local compass = {
            ["x"] = 1,
            ["z"] = 2,
            ["-x"] = 3,
            ["-z"] = 4
        }

        local cardinals = Lt.tableKeys(compass)
        table.sort(cardinals, function(a, b) return compass[a] < compass [b] end)

        if turn == "right" then
            i = (compass[Heading]) + 1
            if i == 5 then i = 1 end
        elseif turn == "left" then
            i = (compass[Heading]) - 1
            if i == 0 then i = 4 end
        end

        Heading = cardinals[i]
    end
end

--[[ Update Coords using the number of moves and the current Heading of turtle
move: num ]]
local function setCoords(move)
    local orientationMatrix = {
        ["x"] = function() Coords.x = Coords.x + move end,
        ["-x"] = function() Coords.x = Coords.x - move end,
        ["z"] = function() Coords.z = Coords.z + move end,
        ["-z"] = function() Coords.z = Coords.z - move end
    }
    orientationMatrix[Heading]()
end

-- Move the turtle forward and check for obstacles, update coords
local function forward()
    while turtle.detect() do
        if isProtectedBlock() then
            error()
        end
        turtle.dig()
        turtle.suck()
    end
    assert(turtle.forward(), "Turtle couldn't go forward")
    setCoords(1)
end

-- Move the turtle backward and check for obstacles, update coords
local function back()
    assert(turtle.back(), "Turtle couldn't go backward")
    setCoords(-1)
end

-- Turn the turtle to the right and update heading
local function turnRight()
    assert(turtle.turnRight())
    setHeading("right")
end

-- Turn the turtle to the left and update heading
local function turnLeft()
    assert(turtle.turnLeft())
    setHeading("left")
end

-- Move the turtle up and check for obstacles, update coords
local function up()
    while turtle.detectUp() do
        if isProtectedBlock("up") then
            error()
        end
        turtle.digUp()
        turtle.suckUp()
    end
    assert(turtle.up(), "Turtle couldn't go up")
    Coords.y = Coords.y + 1
end

-- Move the turtle down and check for obstacles, update coords
local function down()
    while turtle.detectDown() do
        if isProtectedBlock("down") then
            error()
        end
        turtle.digDown()
        turtle.suckDown()
    end
    assert(turtle.down(), "Turtle couldn't go down")
    Coords.y = Coords.y - 1
end

-- Recursive function to get around essential or undestructible blocks
local function circumvent()
    if not pcall(forward) then
        turnRight()
        circumvent()
    else
        turnLeft()
    end
end

-- Inspect adjacent blocks and enters a new mineVein() instance if ore is found
local function mineVein()
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

--[[ Dig in a straight line for a number of blocks, checking for obstacles and, if specified, for ore chunks
blocks: num; strip: bool ]]
local function dig(blocks, strip)
    for step = 1, blocks do
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
    end
end

--[[ Orient turtle in the right direction and move in 3 dimensions, passing a boolean to allow ore mining or not
delta: table; strip: bool ]]
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

    if delta.y < 0 then
        for step = 1, math.abs(delta.y) do
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
        for step = 1,  delta.y do
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

--[[ Call the move function, transforming absolute coords in a usable differential vector, passing a boolean to allow ore mining or not
dest: table; strip:bool ]]
local function goThere(dest, strip)
    move(dest - Coords, strip)
end

-- Check for equipped pickaxe, else prompt user for pickaxe --
local function checkPick()
    while true do
        local equip = turtle.getEquippedRight()
        if not equip or not Lt.tableContainsValue(St.PICKAXES, equip.name) then
            for slot = 1, 16 do
                local item = turtle.getItemDetail(slot)
                if item then
                    if Lt.tableContainsValue(St.PICKAXES, item.name) then
                        turtle.select(slot)
                        turtle.equipRight()
                        break
                    end
                end
                if slot == 16 then
                    Comms.sendStatus("console", {"Could not find pickaxe on turtle. Place a pickaxe in inventory, or equip it and press Enter to continue.", true})
                end
            end
        else break
        end
    end
end

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
    checkPick = checkPick
}