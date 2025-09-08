local termWidth, termHeight = term.getSize()

--Setup main screen--
local corpBanner = window.create(term.current(), 1, 1, termWidth, 3)
local console = window.create(term.current(), 1, 4, termWidth, termHeight - 6)
local taskStatus = window.create(term.current(), 1, termHeight - 2, termWidth, 1)
local turtleStatus = window.create(term.current(), 1, termHeight - 1, termWidth, 1)

local function drawText(text, monitor, pos, nL, txtColour, bkgColour)
    monitor = monitor or term
    txtColour = txtColour or colours.white
    bkgColour = bkgColour or colours.black

    local w, h = monitor.getSize()
    local x, y = monitor.getCursorPos()

    if type(txtColour) == "number" then
        txtColour = tostring(colours.toBlit(txtColour)):rep(#text)
    end
    if type(bkgColour) == "number" then
        bkgColour = tostring(colours.toBlit(bkgColour)):rep(#text)
    end
    if type(pos) == "string" then
        if pos == "left" then
            monitor.setCursorPos(1, y)
            monitor.clearLine()
        elseif pos == "center" then
            monitor.setCursorPos(w / 2 - #text / 2, y)
            monitor.clearLine()
        elseif pos == "right" then
            monitor.setCursorPos(w - #text + 1, y)
        elseif pos == "centerscreen" then
            monitor.setCursorPos(w / 2 - #text / 2, h / 2)
            monitor.clearLine()
        else error("pos should take string arguments -> {left|right|center|centerscreen}")
        end
    elseif type(pos) == "table" then
        if #pos ~= 2 then error("pos should take two arguments-> {x, y}") end
        monitor.setCursorPos(pos[1], pos[2])
        monitor.clearLine()
    else
        monitor.setCursorPos(x, y)
    end

    monitor.blit(text, txtColour, bkgColour)

    if nL then
        monitor.setCursorPos(x, y + 1)
    end
end

local function drawCorpBanner()
    local logo = "CHUNKSWARE TECH"
    local filler1 = ("/"):rep(termWidth / 2 - string.len(logo) / 2)
    local filler2 = ("#"):rep(termWidth)

    corpBanner.clear()
    Gt.drawText(filler2, corpBanner, {1, 1}, true, colours.yellow)
    Gt.drawText(filler1..logo..filler1, corpBanner, "left", true, colours.yellow)
    Gt.drawText(filler2, corpBanner, "left", nil, colours.yellow)
end

local function drawMenu(options, selected)
    console.clear()

    for i, option in pairs(options) do
            drawText((i == selected) and " > " or "   ", console, {1, i + 1})
            drawText(option, console, nil, false, (i == selected) and colours.yellow or colours.white)
    end
end

local function drawTurtleStatus(id, statusColour)
    turtleStatus.clear()

    if not id then statusColour = colours.grey end

    drawText("Current turtle: ["..id or "  ".."]", turtleStatus, "right", nil, statusColour)
end

local function drawTaskStatus(task, taskCompletion, statusColour)
    taskCompletion = taskCompletion or 0
    taskStatus.clear()

    if not task then 
        statusColour = colours.white
        task = "No current task"
    end
    local barLength = termWidth - #task - 4
    local completionBar = ("▮"):rep(barLength * taskCompletion)..(" "):rep(barLength * (1 - taskCompletion))

    drawText(task..": [", taskStatus, "left")
    drawText(completionBar, taskStatus, nil, nil, statusColour)
    drawText("]", taskStatus, "right")
end

local function drawConsole(status, requestInput)
    drawText(status, console, nil, true, requestInput and colours.orange or colours.white)

    if requestInput then
        return io.read()
    end
end

return {
    drawText = drawText,
    drawCorpBanner = drawCorpBanner,
    drawMenu = drawMenu,
    drawTurtleStatus = drawTurtleStatus,
    drawTaskStatus = drawTaskStatus,
    drawConsole = drawConsole
}