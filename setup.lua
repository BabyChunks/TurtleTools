local results = {}
local file = "init.lua"
local gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/"
local filePath = "/ChunksWare/"

-- whipser On
local whisper = term.redirect(window.create(term.current(), 1, 1, 1, 1, false))

    results = fs.find(filePath..file)
    if #results ~= 0 then
        for _, result in pairs(results) do
            fs.delete(result)
        end
    end
    shell.execute("wget", gitPath..file, filePath..file)

--whisper Off
whisper = term.redirect(whisper)

print("Setup complete")

shell.run("rm", "setup.lua")