local t = "Testing this value"

local function test()
  return "Testing this function"
end
local function tableContains(t, element) -- MiscUtil function that returns true if element is in table
    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

local function getKeyForValue(t, value)
  for k, v in pairs(t) do
    if v == value then return k end
  end
  return nil
end

return {t = t, test = test, tableContains = tableContains, getKeyForValue = getKeyForValue}