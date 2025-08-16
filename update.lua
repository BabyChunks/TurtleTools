local results = {}
local files = {
    "turtle.lua",
    "luatools.lua"
}

for _, file in pairs(files) do
    results = fs.find(file)
    if #results ~= 0 then
        for _, result in pairs(results) do
            fs.delete(result)
        end
    end
    shell.run("wget", "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/" .. file)
end