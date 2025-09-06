local function noGPS(dim) --manually enter xyz coords
    local ans = ""
    local coords = {}
    local err = false

    print("Could not locate computer using gps. Input coordinates (x, y, z) manually or press Enter to terminate")
    local incomplete = true

    while incomplete do
        ans = io.read()
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
                    print("Input must be numbers")
                    incomplete = true
                    break
                end
            end
        else
            io.write(coords .. "\n")
        end
    end
    return table.unpack(coords)
end

return {
    noGPS =  noGPS
}