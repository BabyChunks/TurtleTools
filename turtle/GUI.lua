-- Library for preparing and drawing to windows on turtle screen --

--[[ Main function to draw text on screen. Specify which window to draw to, position of 1st character
or alignment of text, if it should end with a new line and colours
text : str, monitor : Term, pos : str/table, nL : bool, txtColour : num, bkgColour : num ]]
local function drawText(text, monitor, pos, nL, txtColour, bkgColour)

    --set default parameters
    monitor = monitor or term.native()
    txtColour = txtColour or colours.white
    bkgColour = bkgColour or colours.black

    local w, h = monitor.getSize()
    local x, y = monitor.getCursorPos()
    local lines = {}

    --wrap text according to window width
    lines = Lt.breakUpString(text, #text / w)
    for n, line in ipairs(lines) do
        -- set cursor postion according to position specified or alignment; stay in place by default
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

--Update banner
local function drawCorpBanner()
    local logo = "CHUNKSWARE TECH"
    local filler1 = ("/"):rep(TermWidth / 2 - string.len(logo) / 2)
    local filler2 = ("#"):rep(TermWidth)

    CorpBanner.clear()
    drawText(filler2, CorpBanner, {1, 1}, true, colours.green)
    drawText(filler1..logo..filler1, CorpBanner, "left", true, colours.green)
    drawText(filler2, CorpBanner, "left", nil, colours.green)
end

--[[ Menu class object with basic methods for updating and navigating.  ]]
Menu = {
    vMargins = 0,
    monitor = Console,
    uBound = 1,
    selected = 1,
    options = {},
    actions = {}
}

-- Update menu screen with selected option highlighted and bounded options
function Menu.draw(self)
    self.monitor.clear()
    local _, height = self.monitor.getSize()

    --handle menus longer than screen, move upper and lower boundary according to previous state and current selection
    self.uBound = math.min(self.selected, self.uBound)
    self.uBound = math.max(self.selected - height + (self.vMargins *2 + 1), self.uBound)

    local lBound = self.uBound + height - (self.vMargins * 2 + 1)

    local windowedOptions = {table.unpack(self.options, self.uBound, lBound)}

    for i, option in pairs(windowedOptions) do
            drawText((i == self.selected - self.uBound + 1) and " > " or "   ", self.monitor, {1, i + 1})
            drawText(option, self.monitor, nil, false, (i == self.selected - self.uBound + 1) and colours.yellow or colours.white)
    end
end

-- Navigate menu with arrow keys and enter, return true if option requires to exit menu.
function Menu.nav(self)
    if #self.options ~= #self.actions then error("options and actions table should contain the same number of items") end
    self.draw(self)

    local _, key = os.pullEvent("key")
    if key == keys.up then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #self.options end
    elseif key == keys.down then
        self.selected = self.selected + 1
        if self.selected > #self.options then self.selected = 1 end
    elseif key == keys.enter then
        self.monitor.clear()
        self.monitor.setCursorPos(1,1)
        local action = self.actions[self.selected]
        return action()
    end
end

-- Initialize an instance of Menu class
function Menu.new(self, o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ Update server window with id if provided
id : num ]]
local function drawServerStatus(id)
    -- if no turtle: grey;
    -- if turtle: white

    ServerStatus.clear()
    local statusColour = not id and colours.grey or colours.white

    drawText(string.format("Current server: [%02d]", id or 0), ServerStatus, "right", nil, statusColour)
end

--[[ Update task window with task completion (0 to 1), textcolour and task name
taskCompletion : num, statusColour : num]]
local function drawTaskStatus(taskCompletion, statusColour)
    -- if no task: white;
    -- if task is ongoing: white;
    -- if task is stopped: red
    TaskStatus.clear()

    -- set default parameters
    taskCompletion = taskCompletion or 0
    CurrentTask = CurrentTask or "No current task"
    statusColour = statusColour or colours.white

    local barLength = TermWidth - #CurrentTask - 2
    local completionBar = (" "):rep(Lt.lerp(0, barLength, taskCompletion))
    local completionBarNeg = (" "):rep(barLength - #completionBar)

    drawText(CurrentTask, TaskStatus, "left", nil, statusColour)
    drawText(": ", TaskStatus)
    drawText(completionBar, TaskStatus, nil, nil, nil, statusColour)
    drawText(completionBarNeg, TaskStatus, "right", nil, nil, colours.grey)
end

--[[ Update console window with new status added below the previous one
status : str, requestInput: bool ]]
local function drawConsole(status, requestInput)
    local width, height = Console.getSize()
    local _, y = Console.getCursorPos()
    local nScrolls = math.max(0, y + math.floor(#status / width) - height + 1)

    Console.scroll(nScrolls)
    Console.setCursorPos(1, y - nScrolls)
    drawText(status, Console, nil, true, requestInput and colours.orange or colours.white)
end

return {
    drawText = drawText,
    drawCorpBanner = drawCorpBanner,
    drawServerStatus = drawServerStatus,
    drawTaskStatus = drawTaskStatus,
    drawConsole = drawConsole,
    Menu = Menu
}