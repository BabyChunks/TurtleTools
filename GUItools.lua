local function drawText(text, monitor, x, y, align, nL, txtColour, bkgColour)
    monitor = monitor or term
    x, y = x, y or monitor.getCursorPos()
    print(x, y) _ = io.read()
    txtColour = txtColour or colours.white
    bkgColour = bkgColour or colours.black

    local w,h = monitor.getSize()

    if type(txtColour) == "number" then
        txtColour = tostring(colours.toBlit(txtColour)):rep(#text)
    end
    if type(bkgColour) == "number" then
        bkgColour = tostring(colours.toBlit(bkgColour)):rep(#text)
    end

    if align == "left" then
        monitor.setCursorPos(1, y)
    elseif align == "center" then
        monitor.setCursorPos(w / 2 - #text / 2, y)
    elseif align == "right" then
        monitor.setCursorPos(w - #text)
    elseif align == "centerscreen" then
        monitor.setCursorPos(w / 2 - #text / 2, h / 2)
    else
        monitor.setCursorPos(x, y)
    end

    monitor.blit(text, txtColour, bkgColour)

    if nL then
        print()
    end
end

return {
    drawText = drawText
}