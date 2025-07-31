function TableContains(t, element) -- MiscUtil function that returns true if element is in table
    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

function GetKeyForValue(t, value)
  for k, v in pairs(t) do
    if v == value then return k end
  end
  return nil
end