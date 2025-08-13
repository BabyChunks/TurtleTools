local results = {}

results = fs.find("TurtleTools.lua")
if #results ~= 0 then
    for _, result in pairs(results) do
        fs.delete(result)
    end
end
shell.run("wget", "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/TurtleTools.lua")

results = fs.find("LuaTools.lua")
if #results ~= 0 then
    for _, result in pairs(results) do
        fs.delete(result)
    end
end
shell.run("wget", "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/LuaTools.lua")