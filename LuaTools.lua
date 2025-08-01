local function tableContainsValue(t, element) -- MiscUtil function that returns true if element is in table values
    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

local function tableContainsKey(t, element) -- MiscUtil function that returns true if element is in table keys
    for key, _ in pairs(t) do
        if key == element then
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

return {
  tableContainsValue = tableContainsValue,
  tableContainsKey = tableContainsKey,
  getKeyForValue = getKeyForValue
}