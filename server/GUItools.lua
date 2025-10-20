-- Library for preparing and drawing to windows on server screen --

local termWidth, termHeight = term.getSize()

-- Setup main screen --
local corpBanner = window.create(term.current(), 1, 1, termWidth, 3)
local console = window.create(term.current(), 1, 4, termWidth, termHeight - 6)
local taskStatus = window.create(term.current(), 1, termHeight - 2, termWidth, 1)
local turtleStatus = window.create(term.current(), 1, termHeight - 1, termWidth, 1)

term.redirect(console)

-- main function to draw text on screen. Specify which window to draw to, position of 1st character
-- or alignment of text, if it should end with a new line and colours
local function drawText(text, monitor, pos, nL, txtColour, bkgColour)
    --set default parameters
    monitor = monitor or term.current()
    txtColour = txtColour or colours.white
    bkgColour = bkgColour or colours.black

    local w, h = monitor.getSize()
    local x, y = monitor.getCursorPos()
    local lines = {}

    --wrap text according to window width
    lines = Lt.breakUpString(text, #text / w)
    for n, line in ipairs(lines) do

        -- set cursor postion according to position specified or alignment or stay in place by default
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

        --set colour of text and background colour
        local txtBlit = tostring(colours.toBlit(txtColour)):rep(#line)
        local bkgBlit = tostring(colours.toBlit(bkgColour)):rep(#line)

        --draw to screen, change x,y to one line down
        monitor.blit(line, txtBlit, bkgBlit)
        y = y + 1
        x = 1
    end

    -- set position one line down for next drawText() call
    if nL then
        monitor.setCursorPos(1, y)
    end
end

--update banner
local function drawCorpBanner()
    local logo = "CHUNKSWARE TECH"
    local filler1 = ("/"):rep(termWidth / 2 - string.len(logo) / 2)
    local filler2 = ("#"):rep(termWidth)

    corpBanner.clear()
    drawText(filler2, corpBanner, {1, 1}, true, colours.yellow)
    drawText(filler1..logo..filler1, corpBanner, "left", true, colours.yellow)
    drawText(filler2, corpBanner, "left", nil, colours.yellow)
end

-- update menu window with menu options and current selections
local function drawMenu(options, selected)
    console.clear()

    for i, option in pairs(options) do
            drawText((i == selected) and " > " or "   ", console, {1, i + 1})
            drawText(option, console, nil, false, (i == selected) and colours.yellow or colours.white)
    end
end

-- update turtle window with id if provided
local function drawTurtleStatus(id)
    -- if no turtle: grey;
    -- if turtle: white

    turtleStatus.clear()
    local statusColour = not id and colours.grey or colours.white

    drawText(string.format("Current turtle: [%s]", id or "  "), turtleStatus, "right", nil, statusColour)
end

-- update task window with task completion (0 to 1), textcolour and task name
local function drawTaskStatus(taskCompletion, statusColour, task)
    -- if no task: white;
    -- if task is ongoing: white;
    -- if task is stopped: red
    taskStatus.clear()

    -- set default parameters
    taskCompletion = taskCompletion or 0
    task = task or "No current task"
    statusColour = statusColour or colours.white

    local barLength = termWidth - #task - 4
    local completionBar = ("I"):rep(barLength * taskCompletion)..(" "):rep(barLength * (1 - taskCompletion))

    drawText(task, taskStatus, "left", nil, statusColour)
    drawText(": [", taskStatus, nil)
    drawText(completionBar, taskStatus, nil, nil, statusColour)
    drawText("]", taskStatus, "right")
end

-- update console window with new status added below the previous one
local function drawConsole(status, requestInput)
    drawText(status, console, nil, true, requestInput and colours.orange or colours.white)
end

-- Initialize entire screen
drawCorpBanner()
drawTurtleStatus()
drawTaskStatus()

return {
    drawText = drawText,
    drawCorpBanner = drawCorpBanner,
    drawMenu = drawMenu,
    drawTurtleStatus = drawTurtleStatus,
    drawTaskStatus = drawTaskStatus,
    drawConsole = drawConsole
}