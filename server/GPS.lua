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
                    Gt.drawConsole("Input must be numbers", true)
                    ans = io.read()
                    incomplete = true
                    break
                end
            end
        else
            Gt.drawConsole(coords, true)
            ans = io.read()
        end
    end
    return vector.new(table.unpack(coords))
end

local function locate()
    local x, y, z = gps.locate()

    if not x then
        Gt.drawConsole("Could not locate computer using gps. Input coordinates (xyz) manually or press Enter to terminate", true)
        return handleCoordsInput(io.read())
    end
    return vector.new(x, y, z)
end

return {
    handlecoordsInput = handleCoordsInput,
    locate = locate
}