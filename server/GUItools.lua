local termWidth, termHeight = term.getSize()

--Setup main screen--
local corpBanner = window.create(term.current(), 1, 1, termWidth, 3)
local console = window.create(term.current(), 1, 4, termWidth, termHeight - 6)
local taskStatus = window.create(term.current(), 1, termHeight - 2, termWidth, 1)
local turtleStatus = window.create(term.current(), 1, termHeight - 1, termWidth, 1)

term.redirect(console)

local function drawText(text, monitor, pos, nL, txtColour, bkgColour)
    monitor = monitor or term
    txtColour = txtColour or colours.white
    bkgColour = bkgColour or colours.black

    local w, h = monitor.getSize()
    local x, y = monitor.getCursorPos()
    local lines = {}

    if type(txtColour) == "number" then
        txtColour = tostring(colours.toBlit(txtColour)):rep(#text)
    end
    if type(bkgColour) == "number" then
        bkgColour = tostring(colours.toBlit(bkgColour)):rep(#text)
    end

    local i = 0
    repeat
        table.insert(lines, string.sub(text, (i * w) + 1, ((i + 1) * w)))
        i = i + 1
    until i > (#text / w)

    for n, line in ipairs(lines) do
        if type(pos) == "string" then
            if pos == "left" then
                monitor.setCursorPos(1, y)
                monitor.clearLine()
            elseif pos == "center" then
                monitor.setCursorPos(w / 2 - #line / 2, y)
                monitor.clearLine()
            elseif pos == "right" then
                monitor.setCursorPos(w - #line + 1, y)
            elseif pos == "centerscreen" then
                monitor.setCursorPos(w / 2 - #line / 2, ((h - #lines) / 2) + (n - 1) )
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
            monitor.blit(line, txtColour, bkgColour)
            y = y + 1
            x = 1
    end

    if not nL then
        monitor.setCursorPos(#lines[#lines], y - 1)
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

local function drawTurtleStatus(id)
    -- if no turtle: grey;
    -- if turtle: white

    turtleStatus.clear()
    local statusColour = not id and colours.grey or colours.white

    drawText(string.format("Current turtle: [%s]", id or "  "), turtleStatus, "right", nil, statusColour)
end

local function drawTaskStatus(taskCompletion, statusColour, task)
    -- if no task: white;
    -- if task is ongoing: white;
    -- if task is stopped: red
    taskStatus.clear()

    taskCompletion = taskCompletion or 0
    task = task or "No current task"
    statusColour = statusColour or colours.white

    local barLength = termWidth - #task - 4
    local completionBar = ("▮"):rep(barLength * taskCompletion)..(" "):rep(barLength * (1 - taskCompletion))

    drawText(task, taskStatus, "left", nil, statusColour)
    drawText(": [", taskStatus, nil)
    drawText(completionBar, taskStatus, nil, nil, statusColour)
    drawText("]", taskStatus, "right")
end

local function drawConsole(status, requestInput)
    drawText(status, console, nil, true, requestInput and colours.orange or colours.white)
end

return {
    drawText = drawText,
    drawCorpBanner = drawCorpBanner,
    drawMenu = drawMenu,
    drawTurtleStatus = drawTurtleStatus,
    drawTaskStatus = drawTaskStatus,
    drawConsole = drawConsole
}