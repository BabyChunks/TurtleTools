local function noGPS(dim) --manually enter xyz coords
    local format, ans = "", ""
    local keys, coords = {}, {}
    local err = false

    if dim == "xyz" then
        format = "x, y, z"
        keys = {"x", "y", "z"}
    elseif dim == "xz" then
        format = "x, z"
        keys = {"x", "z"}
    end

    print("Could not locate turtle using gps. Input coordinates (" .. format .. ") manually or press Enter to terminate")
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
    return coords
end

return {
    noGPS =  noGPS
}