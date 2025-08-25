local results = {}
local files = {
    "settings.lua",
    "luatools.lua",
    "turtle.lua"
}
local gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/"
local filePath = "/ChunksWare/"
local logo = "CHUNKSWARE🅪"
-- whipser On
local whisper = term.redirect(window.create(term.current(), 1, 1, 1, 1, false))

for _, file in pairs(files) do
    results = fs.find(file)
    if #results ~= 0 then
        for _, result in pairs(results) do
            fs.delete(result)
        end
    end
    shell.execute("wget", gitPath..file, filePath..file)
end

--whisper Off
whisper = term.redirect(whisper)

local lt = require("luatools")

local termWidth, termHeight = term.getSize()

term.clear()
term.setCursorPos(1,1)
term.write(string.rep("#", termWidth))

local filler = string.rep("/", termWidth / 2 - string.len(logo))
term.write(filler..logo..filler)

term.write(string.rep("#", termWidth))
