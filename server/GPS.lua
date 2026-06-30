-- Library for positionning of server and handling coordinates --

--[[ Utility function to receive a string containing coords in format: "x*y*z"
(where '*' is any whitespace characters or commas) and return single coords in order 
str: str , emptyOK: bool -> num, num, num ]]--
local function handleCoordsInput(str, emptyOK)
    local incomplete = true
    local coords = {}

    while incomplete do
        if emptyOK and str == "" then return str end

        local ok, err = pcall(Lt.argparse, str)
        if ok then
            coords = err
            incomplete = false
            for _, coord in pairs(coords) do
                if type(coord) ~= "number" then
                    GUI.drawConsole("Input must be numbers. Received "..type(coord).." type.", true)
                    str = io.read()
                    incomplete = true
                    break
                end
            end
            if #coords ~= 3 then
                GUI.drawConsole("Coordinates must be 3-dimensional", true)
                str = io.read()
                incomplete = true
            end
        else
            GUI.drawConsole(err, true)
            str = io.read()
        end
    end
    return table.unpack(coords)
end

--[[ Make a call for gps coordinates, or prompt user for manual input of coords if no gps is found 
-> num, num, num ]]--
local function locate()
    local x, y, z = gps.locate()

    if not x then
        GUI.drawConsole("Could not locate computer using gps. Input coordinates (xyz) manually or press Enter to terminate", true)
        if ans == "" then os.queueEvent("terminate") end
        return handleCoordsInput(io.read())
    end
    return x, y, z
end

return {
    handleCoordsInput = handleCoordsInput,
    locate = locate
}