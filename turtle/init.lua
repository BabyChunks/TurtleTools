local termWidth, termHeight = term.getSize()

local filePath = "/ChunksWare/turtle/"

--initial screen--
term.setCursorPos((termWidth + 16) / 2, termHeight / 2 -2)
textutils.slowWrite("Mine Turtle (tm)", 10)
term.setCursorPos((termWidth + 0) / 2, termHeight / 2)
textutils.slowWrite("a", 10)
term.setCursorPos((termWidth + 10) / 2, termHeight / 2 + 1) term.setTextColour(colours.cyan)
textutils.slowWrite("ChunksWare", 10)
term.setCursorPos((termWidth + 10) / 2, termHeight / 2 + 2) term.setTextColour(colours.white)
textutils.slowWrite("product", 10)
os.sleep(2)
term.clear()

Lt = require(filePath.."luatools")
if Lt.tableContainsValue(arg, "-u") then
    local results = {}
    local files = {
        "settings.lua",
        "quarry.lua",
        "GPS.lua",
    }
    local gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/"

    print("Updating files...")
    --whipser On
    local whisper = term.redirect(window.create(term.current(), 1, 1, 1, 1, false))
        for _, file in pairs(files) do
            results = fs.find(filePath..file)
            if #results ~= 0 then
                for _, result in pairs(results) do
                    if fs.getName(result) ~= "settings.lua" or Lt.tableContainsValue(arg, "-r") then
                        fs.delete(result)
                    end
                end
            end
            shell.execute("wget", gitPath..file, filePath..file)

        end

    --whisper Off
    whisper = term.redirect(whisper)
    print("Done!")
    os.sleep(0.8)
    term.clear()
end

Tt = require(filePath.."quarry")
Gt = require(filePath.."GUItools")
GPS = require(filePath.."GPS")

local corpBanner = window.create(term.current(), 1, 1, termWidth, 3)
local console = window.create(term.current(), 1, 4, termWidth, termHeight - 3)

--Corporation Banner--
local logo = "CHUNKSWARE TECH"
local filler1 = ("/"):rep(termWidth / 2 - string.len(logo) / 2)
local filler2 = ("#"):rep(termWidth)
Gt.drawText(filler2, corpBanner, 1, 1, nil, true, colours.cyan)
Gt.drawText(filler1..logo..filler1, corpBanner, nil, nil, "left", true, colours.cyan)
Gt.drawText(filler2, corpBanner, nil, nil, "left", nil, colours.cyan)

term.redirect(console)

Gt.drawText("Awaiting server commands...", nil, "center")

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