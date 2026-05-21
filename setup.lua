local gitPath = ""
local files = {
        "luatools.lua",
        "GPS.lua",
        "GUI.lua",
        "comms.lua"
    }
local filePath = "/ChunksWare/"

print("Setting up files...")
if turtle then
    table.insert(files, "strip.lua")
    gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/turtle/"
else
    gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/server/"

end
-- whipser On
local whisper = term.redirect(window.create(term.current(), 1, 1, 1, 1, false))
local oldFiles = {}

if #fs.find(filePath.."settings.txt") == 0 then
    table.insert(files, "settings.txt")
end

for _, file in pairs(files) do
    oldFiles = fs.find(filePath..file)
    if #oldFiles ~= 0 then
        for _, oldFile in pairs(oldFiles) do
            fs.delete(oldFile)
        end
    end
    shell.execute("wget", gitPath..file, filePath..file)
end

oldFiles = fs.find("/init.lua")
if #oldFiles ~= 0 then
    for _, oldFile in pairs(oldFiles) do
        fs.delete(oldFile)
    end
end
shell.execute("wget", gitPath.."init.lua", "/init.lua")

--whisper Off
whisper = term.redirect(whisper)

for _, v in ipairs(arg) do
    if v == "-d" then
        shell.run("rm", "setup.lua")
    end
end

print("Setup complete")
os.sleep(0.8)
os.reboot()