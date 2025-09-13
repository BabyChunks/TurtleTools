local function tableContainsValue(t, element)
    for _, value in ipairs(t) do
        if value == element then
            return value
        end
    end
    return nil
end

local function tableContainsKey(t, element)
    for key, _ in pairs(t) do
        if key == element then
            return key
        end
    end
    return nil
end

local function getKeyForValue(t, value)
  for k, v in pairs(t) do
    if v == value then return k end
  end
  return nil
end

local function tablesOverlap(t1, t2)
  local overlap = {}
  for _, v1 in pairs(t1) do
    for _, v2 in pairs(t2) do
      if v1 == v2 then
        table.insert(overlap, v1)
      end
    end
  end

  if #overlap == 0 then return nil
  else return overlap end

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
    table.insert(parsed, arg)
  end

  if #parsed == 0 then
    error("Unrecognized input")
  elseif keys then
    if #parsed ~= #keys then
      error("Incorrect number of arguments")
    end

    for i, key in ipairs(keys) do
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
