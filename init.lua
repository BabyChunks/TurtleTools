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
end

local function navMenu(options, actions)
    local selected = 1

    while true do
        term.clear()
        corpBanner()

        for i, option in ipairs(options) do
            if i == selected then
                print(">")
                term.setTextColour(colours.yellow)
                print(option.."\n")
                term.setTextColour(colours.white)
            else
                print(" "..option.."\n")
            end
        end

        local _, key = os.pullEvent("key")
        if key == keys.w then
            selected = selected - 1
            if selected < 1 then selected = #options end
        elseif key == keys.s then
            selected = selected + 1
            if selected > #options then selected = 1 end
        elseif key == keys.enter then
            local action = actions[selected]
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
            tt.GoThere(ans)
        end,
        function()
            return true
        end
    }

    navMenu(options, actions)
end

menu()