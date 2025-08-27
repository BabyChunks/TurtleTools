local function tableContainsValue(t, element) -- MiscUtil function that returns true if element is in table values
    for _, value in ipairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

local function tableContainsKey(t, element) -- MiscUtil function that returns true if element is in table keys
    for key, _ in ipairs(t) do
        if key == element then
            return true
        end
    end
    return false
end

local function getKeyForValue(t, value)
  for k, v in ipairs(t) do
    if v == value then return k end
  end
  return nil
end

local function tablesOverlap(t1, t2)
  for k1, v1 in ipairs(t1) do
    for k2, v2 in ipairs(t2) do
      if k1 == k2 or v1 == v2 then
        return true
      end
    end
  end
  return false
end

local function tableSum(t)
  local sum = 0
  for _, v in ipairs(t) do
    sum = sum + v
  end
  return sum
end

local function argparse(str, keys)
  local parsed = {}
  local args = {}

  for arg in string.gmatch(str, "-?%w+") do
    if tonumber(arg) then
      arg = tonumber(arg)
    end
    parsed:insert(arg)
  end

  if #parsed == 0 then
    error("Unrecognized input")
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
  tablesOverlap = tablesOverlap,
  tableSum = tableSum,
  argparse = argparse
}
