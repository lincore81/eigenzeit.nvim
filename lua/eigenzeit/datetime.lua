
-- TODO: Consider using a library once you figured out how luarocks works

--[[
--

10d to 10m
mon (means mon 00:00 til mon 24:00)
mon - now  (now is implied)
feb -
feb 
2024 (number w/o suffix is year)
0 - mon (0 is implied)
- sunday
today (alias for 00:00 - 24:00)
yesterday (alias for YESTERDATE:00:00 - YESTERDATE:24:00)
2023-jun - 2024-feb (year-month)
jan-12 - (omitted year is implied to be current year)
10d (10 days ago)
since X (alias for X - now)
until X (alias for epoch - X)

--]]


local function tokenise(input)
    local tokens = {}
    for token in input:gmatch("%S+") do
        table.insert(tokens, token)
    end
    return tokens
end

local WEEKDAYS = {
    "Sunday", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday",
}

local MONTHS = {
    "January", "February", "March", "April",
    "May", "June", "July", "August",
    "September", "October", "November", "December",
}

local MONTH_SET = {
    ["january"] = 1, ["february"] = 2, ["march"] = 3, ["april"] = 4,
    ["may"] = 5, ["june"] = 6, ["july"] = 7, ["august"] = 8,
    ["september"] = 9, ["october"] = 10, ["november"] = 11, ["december"] = 12,
}


local ONE_MINUTE_IN_SECS = 60
local ONE_HOUR_IN_SECS = ONE_MINUTE_IN_SECS * 60
local ONE_DAY_IN_SECS = ONE_HOUR_IN_SECS * 24
local ONE_WEEK_IN_SECS = ONE_DAY_IN_SECS * 7

local start_of_day = function(unixtime) 
    return unixtime - (unixtime % ONE_DAY_IN_SECS) 
end

local end_of_day = function(unixtime) 
    return start_of_day(unixtime) + ONE_DAY_IN_SECS - 1
end

local add_days = function(unixtime, days) 
    return unixtime + (days * ONE_DAY_IN_SECS) 
end




local function parse(token_lc, ostime)
    ostime = ostime or os.time()
    local result
    if token_lc == "today" then
        result = {
            type = "datetime",
            starts = function() start_of_day(ostime()) end,
            ends = function() end_of_day(ostime()) end,
        }
    elseif token_lc == "yesterday" then
        result = {
            type = "datetime",
            starts = function() add_days(start_of_day(ostime()), -1) end,
            ends = function() add_days(end_of_day(ostime()), -1) end,
        }
    end




-- @param month number
-- @param year? number
local function get_days_in_month(month, year)
    year = year or tonumber(os.date("%Y"))
    local days_in_month = {
        31, 28, 31, 30,
        31, 30, 31, 31,
        30, 31, 30, 31,
    }
    if month == 2 then
        local is_leap_year = year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
        if is_leap_year then return 29 end
    end
    return days_in_month[month]
end


local function week_day_to_offset(week_day)
    week_day = week_day:lower()
    local offset = {
        ["sunday"] = 0,
        ["monday"] = 1,
        ["tuesday"] = 2,
        ["wednesday"] = 3,
        ["thursday"] = 4,
        ["friday"] = 5,
        ["saturday"] = 6,
    }
    assert(offset[week_day], "Invalid week day")
    return offset[week_day]
end

local function start_of_day(unixtime)
    return unixtime - (unixtime % ONE_DAY_IN_SECS)
end

local function end_of_day(unixtime)
    return start_of_day(unixtime) + ONE_DAY_IN_SECS - 1
end

local function start_of_week(unixtime, week_start_offset)
    week_start_offset = week_start_offset or 0
    local week_day = os.date("%w", unixtime) + week_start_offset
    return start_of_day(unixtime) - (week_day * ONE_DAY_IN_SECS)
end

local function end_of_week(unixtime, week_start_offset)
    week_start_offset = week_start_offset or 0
    return start_of_week(unixtime, week_start_offset) + ONE_WEEK_IN_SECS - 1
end

local function start_of_month(unixtime)
    local year = get_year(unixtime)
    local month = get_month(unixtime)
    return os.time({year=year, month=month, day=1})
end

local function get_month(unixtime)
    return tonumber(os.date("%m", unixtime))
end

local function get_year(unixtime)
    return tonumber(os.date("%Y", unixtime))
end


-- TODO: Make me not suck
local function parse_range(from, to)
    local result = {}
    if type(from) == "number" then
        result.from = from
    elseif type(from) == "string" then
        from = from:lower()
    end

    if from == "today" then
        result.from = start_of_day(os.time())
    elseif from == "yesterday" then
        result.from = start_of_day(os.time() - ONE_DAY_IN_SECS)
    elseif from == "this_week" then
        result.from = start_of_week(os.time())
    elseif from == "last_week" then
        result.from = start_of_week(os.time() - ONE_WEEK_IN_SECS)
    elseif from == "this_month" then
        result.from = start_of_month(os.time())
    elseif MONTH_SET[from] then
        local month = MONTH_SET[from]
        local year = get_year(os.time())
        result.from = os.time({year=year, month=month, day=1})
    else
        error("Invalid range")
    end

    if type(to) == "number" then
        result.to = to
    elseif type(to) == "string" then
        to = to:lower()
    end

    if to == "today" then
        result.to = end_of_day(os.time())
    elseif to == "yesterday" then     
        result.to = end_of_day(os.time() - ONE_DAY_IN_SECS)
    elseif to == "this_week" then
        result.to = end_of_week(os.time())
    elseif to == "last_week" then
        result.to = end_of_week(os.time() - ONE_WEEK_IN_SECS)
    elseif to == "this_month" then
        result.to = end_of_day(os.time())
    elseif MONTH_SET[to] then
        local month = MONTH_SET[to]
        local year = get_year(os.time())
        local days_in_month = get_days_in_month(month, year)
        result.to = os.time({year=year, month=month, day=days_in_month})
    else
        error("Invalid range")
    end

    return result
end
