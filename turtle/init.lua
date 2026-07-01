--[[ Main script for turtle. Libs are loaded at this level. when called, can specify
"-u" flag to update libs through wget program, pulling from raw github files. ]]

for _, v in pairs(arg) do
    -- update sequence if flag -u is specified
    if v == "-u" then
        print("Updating files...")
        local files = {
            "GPS.lua",
            "GUI.lua",
            "comms.lua",
            "strip.lua",
            "init.lua"
        }
        local filePath = "/ChunksWare/"
        local gitPath = "https://raw.githubusercontent.com/BabyChunks/CC-ChunksWare/refs/heads/main/"
        local gitBranch = "turtle/"

        local function updateFiles(fromPath, toPath, overwrite)
            overwrite = overwrite or true
            if overwrite and fs.exists(toPath) then fs.delete(toPath) end
            if not fs.exist(toPath) then shell.execute("wget", fromPath, toPath) end
        end

        updateFiles(gitPath..gitBranch.."settings.txt", filePath.."settings.txt", false)
        updateFiles(gitPath.."luatools.lua", filePath.."luatools.lua")
        updateFiles(gitPath.."alias.lua", "/startup/alias.lua")

        for _, file in pairs(files) do
            updateFiles(gitPath..gitBranch..file, filePath..file)
        end
        
        print("Done!")
        os.sleep(0.8)
        term.clear()
    end
end
parallel.waitForAny(
function() --Main script for software; will run as long as computer is on

    -- Loading settings --
    St = textutils.unserialize(fs.open(filePath.."settings.txt", "r").readAll())

    -- Define globals --
    -- Comms --
    ServerID = nil
    CurrentTask = nil
    -- GUI --
    TermWidth, TermHeight = term.getSize()
    CorpBanner = window.create(term.native(), 1, 1, TermWidth, 3)
    Console = window.create(term.native(), 1, 4, TermWidth, TermHeight - 6)
    TaskStatus = window.create(term.native(), 1, TermHeight - 1, TermWidth, 1)
    ServerStatus = window.create(term.native(), 1, TermHeight, TermWidth, 1)
    -- GPS --
    Coords = {}
    Heading  = nil

    --initial screen--
    local initScreen = {
        [1] = {"Mine Turtle (tm)", -2, 10, colours.white},
        [2] = {"a", 0, 15, colours.white},
        [3] = {"CHUNKSWARE", 1, 15, colours.cyan},
        [4] = {"product", 2, 15, colours.white}
    }

    for _, line in ipairs(initScreen) do
        term.setCursorPos((TermWidth - #line[1]) / 2, TermHeight / 2 + line[2])
        term.setTextColour(line[4])
        textutils.slowWrite(line[1], line[3])
    end
    os.sleep(2)
    term.clear()
    term.setCursorPos(1, 1)
    term.redirect(Console)

    print("Loading environment...")
    Lt = require(filePath.."luatools")
    GUI = require(filePath.."GUI")
    Comms = require(filePath.."comms")
    GPS = require(filePath.."GPS")
    Strip = require(filePath.."strip")

    -- Initialize entire screen
    GUI.drawBanner()
    GUI.drawServerStatus()
    GUI.drawTaskStatus()

    --initialize main menu--
    local mainMenu = Menu:new()
        mainMenu.vMargins = 1
        mainMenu.options = {"Connect Server", "Mine", "Move", "Courier", "Quit"}
        mainMenu.actions = {
            function() --Connect server
                GUI.drawConsole("Awaiting server pings... Press any key to cancel")
                local function cancel()
                    repeat
                        local _, key = os.pullEvent("key")
                    until key ~= keys.enter and key ~= keys.escape
                end

                parallel.waitForAny(Comms.connectServer, cancel)
                if not ServerID then return end

                local function listenForCmds()
                    while true do
                        local cmd = Comms.getCmd()
                        if cmd.head == "mine" then
                            local args = {}
                            if cmd.body[1] == "y" or cmd.body[1] == "Y" then
                                args[1] = textutils.serialize({GPS.getVectorComponents(Coords)})
                            else
                                args[1] = cmd.body[1]
                            end
                            GPS.goThere(vector.new(table.unpack(cmd.body[2])))
                            args[2] = textutils.serialize(cmd.body[3])
                            Strip.strip(args)
                        elseif cmd.head == "move" then
                            GPS.goThere(vector.new(table.unpack(cmd.body[1])))
                        elseif cmd.head == "courier" then
                        elseif cmd.head == "disconnect" then
                            local id = ServerID
                            ServerID = nil
                            GUI.drawServerStatus()
                            GUI.drawConsole("Computer #"..id.." disconnected")
                            return true
                        end
                    end
                end
                local function navMenu()
                    local remoteTaskMenu = Menu:new{vMargins = 2, options = {"Disconnect Server"}, actions = {
                    function()
                        local id = ServerID
                        Comms.sendStatus("disconnect")
                        ServerID = nil
                        GUI.drawServerStatus()
                        GUI.drawTaskStatus()
                        Console.clear()
                        GUI.drawConsole("Computer #"..id.." disconnected successfully")
                        return true
                    end}}
                    repeat until remoteTaskMenu.nav(remoteTaskMenu)
                end

                parallel.waitForAny(listenForCmds, navMenu)
                os.sleep(0.8)
            end,
            function() --Mine
                local args = {}
                GUI.drawConsole("Starting mining sequence")
                GUI.drawConsole("Input recall point:", true)
                table.insert(args, textutils.serialize({GPS.handleCoordsInput(io.read(), true)}))

                GUI.drawConsole("Input quarry origin:", true)
                table.insert(args, textutils.serialize({GPS.handleCoordsInput(io.read(), true)}))

                GUI.drawConsole("Input quarry boundaries:", true)
                table.insert(args, textutils.serialize({GPS.handleCoordsInput(io.read(), true)}))

                -- GPS.goThere(origin)
                CurrentTask = "Mining"
                Strip.strip(args)
                CurrentTask = nil
                Comms.sendStatus("task")
            end,
            function() --Move
                GUI.drawConsole("Input destination coordinates:", true)
                GPS.goThere(vector.new(GPS.handleCoordsInput(io.read())))
            end,
            function() --Courier
            end,
            function() --Quit
                Console.clear()
                GUI.drawConsole("Goodbye.")
                os.sleep(1)
                os.reboot()
            end
        }

    --Make sure modem is equipped on turtle--
    Comms.checkModem()

    --Make sure pickaxe is equipped on turtle--
    GPS.checkPick()

    --locate turtle--
    Coords = vector.new(GPS.locate())
    GPS.setHeading()

    --navigate main menu as long as computer is on and catch errors--
    local ok, err = pcall(mainMenu.init, mainMenu)
    if not ok then
        if ServerID then
            Comms.sendStatus("disconnect")
        end
        error(err)
    end
end,
function() --catch "terminate" events and cleanup before basically doing what normal termination does
    os.pullEvent = os.pullEventRaw
    repeat until os.pullEvent("terminate")

    if ServerID then Comms.sendStatus("disconnect") end

    local x, y = term.getCursorPos()
    term.clearLine()
    term.setCursorPos(1, y)
    term.setTextColour(colours.red)
    term.write("Terminated")
end
)
