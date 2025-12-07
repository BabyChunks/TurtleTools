local termWidth, termHeight = term.getSize()
local filePath = "/ChunksWare/"

--initial screen--
local initScreen = {
    [1] = {"Mine Turtle (tm)", -2, 10, colours.white},
    [2] = {"a", 0, 15, colours.white},
    [3] = {"CHUNKSWARE", 1, 15, colours.cyan},
    [4] = {"product", 2, 15, colours.white}
}
term.clear()
for _, line in ipairs(initScreen) do
    term.setCursorPos((termWidth - #line[1]) / 2, termHeight / 2 + line[2])
    term.setTextColour(line[4])
    textutils.slowWrite(line[1], line[3])
end
os.sleep(2)
term.clear()
term.setCursorPos(1,1)

for _, v in pairs(arg) do
    -- "update" options
    if v == "-u" then
        local results = {}
        local files = {
            "quarry.lua",
            "GPS.lua",
            "GUITools.lua",
            "luatools.lua",
            "comms.lua"
        }

        if #fs.find(filePath.."settings.txt") == 0 then
            table.insert(files, "settings.txt")
        end

        local gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/turtle/"

        print("Updating files...")
        --whipser On
        local whisper = term.redirect(window.create(term.current(), 1, 1, 1, 1, false))
            for _, file in pairs(files) do
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
        print("Done!")
    end
end

print("Loading environment...")
Lt = require(filePath.."luatools")
St = textutils.unserialize(fs.open(filePath.."settings.txt", "r").readAll())
Tt = require(filePath.."quarry")
Comms = require(filePath.."comms")
GPS = require(filePath.."GPS")
Gt = require(filePath.."GUITools")
print("Done!")



print("Awaiting server pings...")
Comms.connectServer()

while true do
    print("Awaiting server commands...")
    CurrentTask = nil

    local cmd = Comms.getCmd()

    if cmd.head == "mine" then
        CurrentTask = "Mining"
        Tt.startup(cmd.body)
    elseif cmd.head == "move" then
        CurrentTask = "Moving"
        GPS.goThere(table.unpack(cmd.body))
    elseif cmd.head == "courrier" then
        CurrentTask = "Fetching"
    elseif cmd.head == "disconnect" then
        Comms.setServerID(nil)
    end
end