local filePath = "/ChunksWare/"
print("program start")

for _, v in ipairs(arg) do
    print("arg: "..v)
    if v == "-u" then
        local results = {}
        local files = {
            "luatools.lua",
            "GUItools.lua",
            "GPS.lua",
            "comms.lua"
        }

        if #fs.find(filePath.."settings.txt") == 0 then
            table.insert(files, "settings.txt")
        end

        local gitPath = "https://raw.githubusercontent.com/BabyChunks/TurtleTools/refs/heads/main/server/"
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
        os.sleep(0.8)
        term.clear()
    end
end

Lt = require(filePath.."luatools")
St = textutils.unserialize(fs.open(filePath.."settings.txt", "r").readAll())
Gt = require(filePath.."GUItools")
GPS = require(filePath.."GPS")
Comms = require(filePath.."comms")

local function navMenu(options, actions)
    local selected = 1

    while true do
        Gt.drawMenu(options, selected)

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

local function setupQuarry()
    local cmd = {head = "mine", body = {}}
    Gt.drawConsole("Startup sequence for Mine Turtle (tm)")

    Gt.drawConsole("Use current coordinates as recall point? (y/[xyz])", true)
    local ans = io.read()
    if ans ~= "y" or ans ~= "Y" then
        ans = {GPS.handleCoordsInput(ans)}
    end
    table.insert(cmd.body, ans)

    Gt.drawConsole("Input first coordinates:", true)
    table.insert(cmd.body, {GPS.handleCoordsInput(io.read())})

    Gt.drawConsole("Input second coodinates:", true)
    table.insert(cmd.body, {GPS.handleCoordsInput(io.read())})

    Comms.sendCmd(cmd)

    while true do
        if Comms.getStatus() then break end
    end

end

local function mainMenu()
    local options = {Comms.getTurtleID() and "Disconnect Turtle" or "Connect turtle", "Inventory", "Mine", "Move", "Quit"}

    local actions = {
        function() --(Dis)connect turtle
            if Comms.getTurtleID() then
                local id = Comms.getTurtleID()
                Comms.setTurtleID(nil)
                Gt.drawTurtleStatus(nil)
                Gt.drawConsole("Turtle #"..id.." disconnected successfully")
            else
                Gt.drawConsole("Pinging nearby turtles...")
                Comms.pingTurtles()
                Gt.drawTurtleStatus(Comms.getTurtleID())
                Gt.drawConsole("Connected with turtle #"..Comms.getTurtleID())
            end
            os.sleep(0.8)
        end,
        function() --Inventory
        end,
        function() --Mine
            if not Comms.getTurtleID() then
                Gt.drawConsole("No turtle connected")
                os.sleep(0.8)
            end
            setupQuarry()
        end,
        function() --Move
            -- print("Input destination coordinates [xyz]")
            -- local ans = Lt.argparse(io.read(), {"x", "y", "z"})
            -- term.clear()
            -- term.setCursorPos(1,1)
            -- Tt.GoThere(ans.x, ans.y, ans.z)
        end,
        function() --Quit
            os.queueEvent("terminate")
        end
    }

    navMenu(options, actions)
end

mainMenu()