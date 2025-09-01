local function drawText(text, monitor, pos, nL, txtColour, bkgColour)
    monitor = monitor or term
    txtColour = txtColour or colours.white
    bkgColour = bkgColour or colours.black

    local w,h = monitor.getSize()
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
            monitor.setCursorPos(w - #text)
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

return {
    drawText = drawText
}