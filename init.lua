local results = {}
local files = {
    "settings.lua",
    "luatools.lua",
    "quarry.lua",
    "GUItools.lua",
    "GPS.lua"
}
local gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/"
local filePath = "/ChunksWare/"


-- whipser On
local whisper = term.redirect(window.create(term.current(), 1, 1, 1, 1, false))

    for _, file in pairs(files) do
        results = fs.find(filePath..file)
        if #results ~= 0 then
            for _, result in pairs(results) do
                if fs.getName(result) ~= "settings.lua" or arg[1] == "-r" then
                    fs.delete(result)
                end
            end
        end
        shell.execute("wget", gitPath..file, filePath..file)
    end

--whisper Off
whisper = term.redirect(whisper)

Lt = require(filePath.."luatools")
Tt = require(filePath.."quarry")
St = require(filePath.."settings")
Gt = require(filePath.."GUItools")

local termWidth, termHeight = term.getSize()
local corpBanner = window.create(term.current(), 1, 1, termWidth, 3)
local console = window.create(term.current(), 1, 4, termWidth, termHeight - 3)

--Corporation Banner--
local logo = "CHUNKSWARE TECH"
local filler1 = ("/"):rep(termWidth / 2 - string.len(logo) / 2)
local filler2 = ("#"):rep(termWidth)
corpBanner.setCursorPos(1,1)
corpBanner.write(filler2)
corpBanner.setCursorPos(1,2)
corpBanner.write(filler1..logo..filler1)
corpBanner.setCursorPos(1,3)
corpBanner.write(filler2)

term.redirect(console)

local function navMenu(options, actions)
    local selected = 1

    while true do
        term.clear()

        for i, option in ipairs(options) do
            term.setCursorPos(1, i)
            if i == selected then
                term.blit(" > "..option, "000"..string.rep("4", #option), string.rep("f",#option + 3))
            else
                term.blit("   "..option, string.rep("0", #option + 3), string.rep("f", #option + 3))
            end
        end

        local _, key = os.pullEvent("key")
        if key == keys.w or key == keys.up then
            selected = selected - 1
            if selected < 1 then selected = #options end
        elseif key == keys.s or key == keys.down then
            selected = selected + 1
            if selected > #options then selected = 1 end
        elseif key == keys.enter then
            term.clear()
            term.setCursorPos(1,1)
            local action = actions[selected]
            if action then
                local shouldExit = action()
                if shouldExit then return end
            end
        end
    end
end

local function menu()
    local options = {"Mine", "Move", "Quit"}

    local actions = {
        function()
            Tt.startup()
        end,
        function()
            print("Input destination coordinates [xyz]")
            local ans = Lt.argparse(io.read(), {"x", "y", "z"})
            term.clear()
            term.setCursorPos(1,1)
            Tt.GoThere(ans.x, ans.y, ans.z)
        end,
        function()
            return true
        end
    }

    navMenu(options, actions)
end

menu()