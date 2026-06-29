--[[ Main script for server. Libs are loaded at this level. when called, can specify
-- "-u" flag to update libs through wget program, pulling from raw github files. ]]

local filePath = "/ChunksWare/"

for _, v in ipairs(arg) do
    -- update sequence if flag -u is specified
    if v == "-u" then
        print("Updating files...")
        local files = {
            "luatools.lua",
            "GUI.lua",
            "GPS.lua",
            "comms.lua"
        }
        local gitPath = "https://raw.githubusercontent.com/BabyChunks/CC-ChunksWare/refs/heads/main/server/"
        local oldFiles = {}

        if #fs.find(filePath.."settings.txt") == 0 then
            table.insert(files, "settings.txt")
        end

        for _, file in pairs(files) do
            oldFiles = fs.find(filePath..file)
            if #oldFiles ~= 0 then
                for _, oldFile in pairs(oldFiles) do
                        fs.delete(oldFile)
                end
            end
            shell.execute("wget", gitPath..file, filePath..file)
        end

        oldFiles = fs.find("/init.lua")
        if #oldFiles ~= 0 then
            for _, oldFile in pairs(oldFiles) do
                    fs.delete(oldFile)
            end
        end
        shell.execute("wget", gitPath.."init.lua", "/init.lua")

        print("Done!")
        os.sleep(0.8)
        term.clear()
    end
end

-- Loading settings --
St = textutils.unserialize(fs.open(filePath.."settings.txt", "r").readAll())

-- Define globals --
-- Comms --
TurtleID = St.defaultValues.value["TurtleID"] or nil
CurrentTask = St.defaultValues.value["CurrentTask"] or nil
-- GUI --
TermWidth, TermHeight = term.getSize()
CorpBanner = window.create(term.native(), 1, 1, TermWidth, 3)
Console = window.create(term.native(), 1, 4, TermWidth, TermHeight - 6)
TaskStatus = window.create(term.native(), 1, TermHeight - 1, TermWidth, 1)
TurtleStatus = window.create(term.native(), 1, TermHeight, TermWidth, 1)
-- GPS --
ServerCoords = St.defaultValues.value["ServerCoords"] or {}
-- Inv --
Interface = St.defaultValues.value["Interface"] and peripheral.wrap(St.defaultValues.value["Interface"]) or nil
Invs = {}
Items = {}

term.clear()
term.setCursorPos(1,1)
term.redirect(Console)

print("Loading environment...")
Lt = require(filePath.."luatools")
GUI = require(filePath.."GUI")
GPS = require(filePath.."GPS")
Comms = require(filePath.."comms")
Inv = require(filePath.."inv")

-- Initialize entire screen
GUI.drawCorpBanner()
GUI.drawTurtleStatus()
GUI.drawTaskStatus()

-- Initiailze main menu --
local mainMenu = Menu:new()
    mainMenu.vMargins = 1
    mainMenu.options = {"Control Turtle", "Inventory", "Quit"}
    mainMenu.actions = {
        function() --Control Turtle
            GUI.drawConsole("Pinging nearby turtles...")
            if Comms.pingTurtles() then return end
            local function navMenu()
                local turtleMenu = Menu:new()
                turtleMenu.vMargins = 1
                turtleMenu.options = {"Mine", "Move", "Courier", "Disconnect"}
                turtleMenu.actions = {
                    function() -- Mine
                        local cmd = {head = "mine", body = {}}
                        GUI.drawConsole("Startup sequence for Mine Turtle (tm)")
                        GUI.drawConsole("Input recall point:", true)
                        table.insert(cmd.body, {GPS.handleCoordsInput(io.read(), true)})
                        GUI.drawConsole("Input quarry origin:", true)
                        table.insert(cmd.body, {GPS.handleCoordsInput(io.read(), true)})
                        GUI.drawConsole("Input quarry boundaries:", true)
                        table.insert(cmd.body, {GPS.handleCoordsInput(io.read(), true)})
                        Comms.sendCmd(cmd)
                        while true do
                            if Comms.getStatus() then break end
                        end
                    end,
                    function() --Move
                    GUI.drawConsole("Input destination coordinates [xyz]", true)
                    Comms.sendCmd({head = "move", body = {{GPS.handleCoordsInput(io.read())}}})
                    end,
                    function() --Courier
                    end,
                    function() --Disconnect
                        Comms.sendCmd({head = "disconnect"})
                        CurrentTask = nil
                        TurtleID = nil
                        GUI.drawTaskStatus()
                        GUI.drawTurtleStatus()
                        return true
                    end
                }
                repeat until turtleMenu.nav(turtleMenu)
            end
            local function listen()
                repeat until Comms.getStatus()
                return true
            end
            parallel.waitForAny(navMenu, listen)
        end,
        function() --Inventory
            if not Interface then
                GUI.drawConsole("No interface inventory registered. Input the peripheral name of this computer's interface inventory", true)
                Inv.updateInterface()
            end
            Inv.invMenu:init()
        end,
        function() --  Quit
            Console.clear()
            GUI.drawConsole("Goodbye.")
            os.sleep(1)
            os.reboot()
        end
    }

--Make sure modem is placed on computer--
Comms.checkModem()

--locate server--
ServerCoords = vector.new(GPS.locate())

--navigate main menu as long as computer is on and catch errors--
local ok, err = pcall(mainMenu.init, mainMenu)
if not ok then
    if TurtleID then
        Comms.sendStatus("disconnect")
    end
    error(err)
end