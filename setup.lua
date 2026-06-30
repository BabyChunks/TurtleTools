local gitPath = ""
local files = {
        "luatools.lua",
        "GPS.lua",
        "GUI.lua",
        "comms.lua",
        "init.lua"
    }
local filePath = "/ChunksWare/"

print("Setting up files...")
if turtle then
    table.insert(files, "strip.lua")
    gitPath = "https://raw.githubusercontent.com/BabyChunks/CC-ChunksWare/refs/heads/main/turtle/"
else
    table.insert(files, "inv.lua")
    gitPath = "https://raw.githubusercontent.com/BabyChunks/CC-ChunksWare/refs/heads/main/server/"
end

if not fs.exists(filePath.."settings.txt") then
    table.insert(files, "settings.txt")
end

for _, file in pairs(files) do
    if fs.exists(filePath..file) then fs.delete(filePath..file) end
    shell.execute("wget", gitPath..file, filePath..file)
end

if fs.exists("/startup/alias.lua") then fs.delete("/startup/alias.lua") end
shell.execute("wget", gitPath.."alias.lua", "/startup/alias.lua")

for _, v in pairs(arg) do
    if v == "-d" then
        shell.run("rm", "setup.lua")
    end
end

print("Setup complete")
os.sleep(0.8)
os.reboot()