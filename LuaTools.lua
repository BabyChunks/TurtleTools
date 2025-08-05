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

local function argparse(str, keys)
  Args = {}

  for arg in string.gmatch(ans, "-?%w+") do
    table.insert(Args, arg)
  end

  if #Args == 0 then
    return nil
  elseif #Args ~= #Keys then
    error("Incorrect number of arguments")
  else
    incomplete = false

    for i, key in pairs(keys) do
      Home[key] = Args[i]
    end
  end
end

return {
  tableContainsValue = tableContainsValue,
  tableContainsKey = tableContainsKey,
  getKeyForValue = getKeyForValue,
  argparse = argparse
}