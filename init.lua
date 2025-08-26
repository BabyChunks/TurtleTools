local results = {}
local files = {
    "settings.lua",
    "luatools.lua",
    "quarry.lua"
}
local gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/"
local filePath = "/ChunksWare/"

local function initFiles()
    -- whipser On
    local whisper = term.redirect(window.create(term.current(), 1, 1, 1, 1, false))

    for _, file in pairs(files) do
        results = fs.find(file)
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
end

initFiles()
local lt = require(filePath.."luatools")
local tt = require(filePath.."quarry")
local st = require(filePath.."settings")

local function corpBanner()
    local logo = "CHUNKSWARE TECHNOLOGY®"
    local termWidth, termHeight = term.getSize()
    term.setCursorPos(1,1)
    term.write(string.rep("#", termWidth))
    term.setCursorPos(1,2)
    local filler = string.rep("/", termWidth / 2 - string.len(logo) / 2)
    term.write(filler..logo..filler)
    term.setCursorPos(1,3)
    term.write(string.rep("#", termWidth))
    term.setCursorPos(1,4)
end

local function navMenu(options, actions)
    local selected = 1

    while true do
        term.clear()
        corpBanner()

        for i, option in ipairs(options) do
            if i == selected then
                io.write(">")
                term.setTextColour(colours.yellow)
                io.write(option.."\n")
                term.setTextColour(colours.white)
            else
                print(" "..option)
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
            tt.startup()
        end,
        function()
            term.clear()
            corpBanner()
            print("Input destination coordinates [xyz]")
            local ans = lt.argparse(io.read(), {"x", "y", "z"})
            tt.GoThere(ans.x, ans.y, ans.z)
        end,
        function()
            return true
        end
    }

    navMenu(options, actions)
end

menu()