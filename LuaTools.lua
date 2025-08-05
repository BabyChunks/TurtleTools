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
  local parsed = {}
  local args = {}

  for arg in string.gmatch(str, "-?%w+") do
    if tonumber(arg) then
      arg = tonumber(arg)
    end
    table.insert(parsed, arg)
  end

  if #parsed == 0 then
    return nil
  elseif keys then
    if #parsed ~= #keys then
      error("Incorrect number of arguments")
    end

    for i, key in pairs(keys) do
    args[key] = parsed[i]
    end

    return args
  end

  return parsed
end

return {
  tableContainsValue = tableContainsValue,
  tableContainsKey = tableContainsKey,
  getKeyForValue = getKeyForValue,
  argparse = argparse
}