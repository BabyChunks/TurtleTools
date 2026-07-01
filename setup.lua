print("Setting up files...")
local files = {
    "GPS.lua",
    "GUI.lua",
    "comms.lua",
    "init.lua"
}
local filePath = "/ChunksWare/"
local gitPath = "https://raw.githubusercontent.com/BabyChunks/CC-ChunksWare/refs/heads/main/"
local gitBranch = ""


local function updateFiles(fromPath, toPath, overwrite)
    overwrite = overwrite or true
    if overwrite and fs.exists(toPath) then fs.delete(toPath) end
    if not fs.exist(toPath) then shell.execute("wget", fromPath, toPath) end
end

if turtle then
    table.insert(files, "strip.lua")
    gitBranch = "turtle/"
else
    table.insert(files, "inv.lua")
    gitBranch = "server/"
end

updateFiles(gitPath..gitBranch.."settings.txt", filePath.."settings.txt", false)
updateFiles(gitPath.."luatools.lua", filePath.."luatools.lua")
updateFiles(gitPath.."alias.lua", "/startup/alias.lua")

for _, file in pairs(files) do
    updateFiles(gitPath..gitBranch..file, filePath..file)
end

for _, v in pairs(arg) do
    if v == "-d" then
        shell.run("rm", "setup.lua")
    end
end

print("Setup complete")
os.sleep(0.8)
os.reboot()