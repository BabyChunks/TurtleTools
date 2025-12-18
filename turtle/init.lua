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
            "strip.lua",
            "GPS.lua",
            "GUI.lua",
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
Comms = require(filePath.."comms")
GPS = require(filePath.."GPS")
Gt = require(filePath.."GUI")

-- start menu selection at first option
local selected = 1

-- navigation function for all menus. options is a table with menu option names, 
-- actions is a table of functions executing these options
local function navMenu(options, actions)
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

local function mainMenu()
    local connect = Comms.getServerID() and "Disconnect Server" or "Connect Server"
    local options = {connect, "Mine", "Move", "Quit"}

    local actions = {
        function() --(Dis)connect server
            if Comms.getServerID() then
                local id = Comms.getServerID()
                Comms.setServerID(nil)
                Gt.drawServerStatus(nil)
                Gt.drawConsole("Computer #"..id.." disconnected successfully")
            else
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
            end
            os.sleep(0.8)
        end,
        function() --Mine
         local cmd = {}
        Gt.drawConsole("Starting mining sequence")
        Gt.drawConsole("Use current coords as recall point?(y/[xyz])", true)
        local ans = io.read()

        if ans == "y" or ans == "Y" then
            table.insert(cmd, Coords)
        else
            table.insert({GPS.handleCoordsInput(ans)}, ans)
        end
            Gt.drawConsole("Input quarry origin:", true)
            local origin = vector.new(GPS.handleCoordsInput(io.read()))
            Gt.drawConsole("Input quarry boundaries:", true)
            table.insert(cmd, {GPS.handleCoordsInput(io.read())})
            GPS.goThere(origin)
            shell.execute(filePath.."strip", cmd)
        end,
        function() --Move
            Gt.drawConsole("Input destination coordinates [xyz]", true)
            GPS.goThere(vector.new(GPS.handleCoordsInput(io.read())))
        end,
        function() --Quit
            Gt.clearConsole()
            Gt.drawConsole("Goodbye.")
            os.sleep(1)
            term.native().clear()
            
            os.queueEvent("terminate")
        end
    }

    navMenu(options, actions)
end

while true do
    mainMenu()
end