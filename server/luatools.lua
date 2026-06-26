local function stringBreakUp(s, n)
  local t = {}
  local len = #s / n
  while #s > len do
    table.insert(t, string.sub(s, 1, len))
    s = string.sub(s, len + 1, -1)
  end
  table.insert(t, s)
  return table.unpack(t)
end

local function tableKeys(t)
  local l = {}
  for k, _ in pairs(t) do
    l[#l + 1] = k
  end
  return l
end

local function tableShallowCopy(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = v
  end
  return copy
end

local function tableContainsValue(t, element)
    for _, value in pairs(t) do
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

local function tablesEqual(...)
  local tables = {...}
  if #tables < 2 then error("Need at least 2 tables to compare") end
  local ln = #tables[1]
  for i, t in pairs(tables) do
    if type(t) ~= "table" then error("tables["..i.."] is not a table") end
    if #t ~= ln then return false end
  end
  for n = 1, #tables - 1 do
    for k, v in pairs(tables[n]) do
      if v ~= tables[n + 1][k] then return false end
    end
  end
  return true
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
  for _, v in pairs(t) do
    sum = sum + v
  end
  return sum
end

local function tableAvg(t)
  return tableSum(t) / #t
end

local function argparse(str, keys)
  local parsed = {}
  local args = {}

  for arg in string.gmatch(str, "[^,%s]+") do
    arg = tonumber(arg) or arg
    table.insert(parsed, arg)
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

local function lerp(a, b, t)
  return a + (b - a) * t
end

return {
  stringBreakUp = stringBreakUp,
  tableShallowCopy = tableShallowCopy,
  tableKeys = tableKeys,
  tableContainsValue = tableContainsValue,
  tableContainsKey = tableContainsKey,
  getKeyForValue = getKeyForValue,
  tablesEqual = tablesEqual,
  tablesOverlap = tablesOverlap,
  tableSum = tableSum,
  tableAvg = tableAvg,
  argparse = argparse,
  lerp = lerp
}
