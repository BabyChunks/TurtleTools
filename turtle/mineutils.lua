QuarryCompletion = 0

local function getCompletion()
    return QuarryCompletion
end

local function setCompletion(n)
    QuarryCompletion = n
end

local function isProtectedBlock()
    for _, func in pairs(St.PROTECTED_BLOCKS) do
        if func() == true then
            return true
        end
    end
end

local function circumvent()
    turtle.turnRight()
    local periph = peripheral.find("inventory")
    if periph then
        if peripheral.getName(periph) == "front" then
            circumvent()
        end
    end
    turtle.forward()
    turtle.turnLeft()
    local periph = peripheral.find("inventory")
    if periph then
        if peripheral.getName(periph) == "front" then
            circumvent()
        end
    end
    turtle.forward()
    local periph = peripheral.find("inventory")
    if periph then
        if peripheral.getName(periph) == "front" then
            circumvent()
        end
    end
    turtle.forward()
    turtle.turnLeft()
    local periph = peripheral.find("inventory")
    if periph then
        if peripheral.getName(periph) == "front" then
            circumvent()
        end
    end
    turtle.forward()
    turtle.turnRight()
end

return {
    getCompletion = getCompletion,
    setCompletion = setCompletion,
    isProtectedBlock = isProtectedBlock,
    circumvent = circumvent
}