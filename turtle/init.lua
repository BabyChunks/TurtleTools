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


-- "update" options
if arg[1] == "-u" then
    local results = {}
    local files = {
        "quarry.lua",
        "GPS.lua",
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

print("Loading environment...")
Lt = require(filePath.."luatools")
St = textutils.unserialize(fs.open(filePath.."settings.txt", "r").readAll())
print(textutils.serialize(St.MODEMS))
_ = io.read()
Tt = require(filePath.."quarry")
Comms = require(filePath.."comms")
GPS = require(filePath.."GPS")
print("Done!")

Coords = GPS.locate()
GPS.getHeading()

print("Awaiting server pings...")
Comms.connectServer()

while true do
    print("Awaiting server commands...")
    CurrentTask = nil
    Comms.SendStatus("task", {nil, nil, CurrentTask})

    local cmd = Comms.getCmd()

    if cmd.name == "mine" then
        CurrentTask = "Mining"
        Tt.startup(cmd.body)
    elseif cmd.name == "move" then
        CurrentTask = "Moving"
        GPS.goThere(table.unpack(cmd.body))
    elseif cmd.name == "courrier" then
        CurrentTask = "Fetching"
    elseif cmd.name == "disconnect" then
        Comms.setServerID(nil)
    end
end

-- local corpBanner = window.create(term.current(), 1, 1, termWidth, 3)
-- local console = window.create(term.current(), 1, 4, termWidth, termHeight - 3)

--Corporation Banner--
-- local logo = "CHUNKSWARE TECH"
-- local filler1 = ("/"):rep(termWidth / 2 - string.len(logo) / 2)
-- local filler2 = ("#"):rep(termWidth)
-- Gt.drawText(filler2, corpBanner, 1, 1, nil, true, colours.cyan)
-- Gt.drawText(filler1..logo..filler1, corpBanner, nil, nil, "left", true, colours.cyan)
-- Gt.drawText(filler2, corpBanner, nil, nil, "left", nil, colours.cyan)

-- term.redirect(console)

-- Gt.drawText("Awaiting server commands...", nil, "center")

-- local function navMenu(options, actions)
--     local selected = 1

--     while true do
--         term.clear()

--         for i, option in pairs(options) do
--             --if i == selected then
--                 Gt.drawText((i == selected) and " > " or "   ", nil, {1, i})
--                 Gt.drawText(option, nil, nil, false, (i == selected) and colours.yellow or colours.white)
--             --else
--                 --Gt.drawText("   "..option, nil, 1, i, nil, false)
--             --end
--         end

--         local _, key = os.pullEvent("key")
--         if key == keys.w or key == keys.up then
--             selected = selected - 1
--             if selected < 1 then selected = #options end
--         elseif key == keys.s or key == keys.down then
--             selected = selected + 1
--             if selected > #options then selected = 1 end
--         elseif key == keys.enter then
--             term.clear()
--             term.setCursorPos(1,1)
--             local action = actions[selected]
--             if action then
--                 local shouldExit = action()
--                 if shouldExit then return end
--             end
--         end
--     end
-- end

-- local function menu()
--     local options = {"Mine", "Move", "Quit"}

--     local actions = {
--         function()
--             Tt.startup()
--         end,
--         function()
--             print("Input destination coordinates [xyz]")
--             local ans = Lt.argparse(io.read(), {"x", "y", "z"})
--             term.clear()
--             term.setCursorPos(1,1)
--             Tt.GoThere(ans.x, ans.y, ans.z)
--         end,
--         function()
--             return true
--         end
--     }

--     navMenu(options, actions)
-- end

-- menu()