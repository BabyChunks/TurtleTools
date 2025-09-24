local function handleCoordsInput(forceCoords)

    local keys = {"x", "y", "z"}
    local incomplete, err = true, false
    local coords = {}

    while incomplete do
        local ans = io.read()
        term.clear()
        term.setCursorPos(1,1)
        if ans == "" then
            os.queueEvent("terminate")
        end

        for i, key in ipairs(keys) do
            if forceCoords[i] then
                table.remove(keys, i)
            end
        end
        err, coords = pcall(Lt.argparse, ans, keys)
        if err then
            incomplete = false
            for _, coord in pairs(coords) do
                if type(coord) ~= "number" then
                    Gt.drawConsole("Input must be numbers")
                    incomplete = true
                    break
                end
            end
        else
            io.write(coords .. "\n")
        end
    end

    for i, coord in ipairs(forceCoords) do
        coords[i] = coord
    end
    return vector.new(table.unpack(coords))
end

local function noGPS(forceCoords) --manually enter xyz coords
    forceCoords = forceCoords or {}

    Gt.drawConsole(
    string.format("Could not locate computer using gps. Input coordinates (%s%s%s) manually or press Enter to terminate", 
    "x" and not forceCoords[1],
    "y" and not forceCoords[2],
    "z" and not forceCoords[3]), true)

    return handleCoordsInput(forceCoords)
end

local function locate()
    local coords = gps.locate()

    if not coords then
        return noGPS()
    end

    return vector.new(table.unpack(coords))
end

return {
    handlecoordsInput = handleCoordsInput,
    noGPS =  noGPS,
    locate = locate
}