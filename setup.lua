local gitPath = ""
local libs, commons = {}, {}
local filePath = "/ChunksWare/"

print("Setting up files...")
if turtle then
    libs = {
        "luatools.lua",
        "GPS.lua",
        "GUI.lua",
        "comms.lua"
    }
    commons = {
        "init.lua",
        "strip.lua"
    }
    gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/turtle/"
else
    libs = {
        "init.lua",
        "luatools.lua",
        "GUItools.lua",
        "GPS.lua",
        "comms.lua"
    }
    gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/server/"
end
-- whipser On
local whisper = term.redirect(window.create(term.current(), 1, 1, 1, 1, false))

if #fs.find(filePath.."settings.txt") == 0 then
    table.insert(commons, "settings.txt")
end

for _, lib in pairs(libs) do
    local results = {}
    results = fs.find(filePath.."libs/"..lib)
    if #results ~= 0 then
        for _, result in pairs(results) do
            fs.delete(result)
        end
    end
    shell.execute("wget", gitPath.."libs/"..lib, filePath.."libs/"..lib)
end

for _, file in pairs(commons) do
    local results = {}
    results = fs.find(filePath..file)
    if #results ~= 0 then
        for _, result in pairs(results) do
            fs.delete(result)
        end
    end
    shell.execute("wget", gitPath..file, filePath..file)
end
--whisper Off
whisper = term.redirect(whisper)

print("Setup complete")
os.sleep(0.8)
os.reboot()

for _, v in ipairs(arg) do
    if v == "-d" then
        shell.run("rm", "setup.lua")
    end
end