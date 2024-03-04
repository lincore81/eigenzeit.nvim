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


local function utc_timestamp()
    ---@diagnostic disable-next-line: param-type-mismatch
    return os.time(os.date("!*t"))
end

local function get_timezone_offset(timestamp)
    local utcdate = os.date("!*t", timestamp)
    local localdate = os.date("*t", timestamp)
    ---@diagnostic disable-next-line: param-type-mismatch
    return os.difftime(os.time(localdate), os.time(utcdate))
end

local function utc_to_local(utc_timestamp)
    return utc_timestamp + get_timezone_offset(utc_timestamp)
end

-- NOTE: Sunday = 1, Monday = 2, ...
local function get_weekday_index(timestamp)
    return os.date("*t", timestamp).wday
end


local function start_of_day(timestamp)
    local date = os.date("*t", timestamp)
    date.hour = 0
    date.min = 0
    date.sec = 0
    return os.time(date)
end

local function start_of_today()
    return start_of_day(os.time())
end

local function start_of_yesterday()
    return start_of_day(os.time() - 24 * 60 * 60)
end


local function start_of_week(first_day_of_week)
    local date = os.date("*t")
    date.wday = first_day_of_week or 1
    date.hour = 0
    date.min = 0
    date.sec = 0
    return os.time(date)
end

local function start_of_month()
    local date = os.date("*t")
    date.day = 1
    date.hour = 0
    date.min = 0
    date.sec = 0
    return os.time(date)
end

local function start_of_year()
    local date = os.date("*t")
    date.month = 1
    date.day = 1
    date.hour = 0
    date.min = 0
    date.sec = 0
    return os.time(date)
end

local function add_days(timestamp, days)
    return timestamp + days * 24 * 60 * 60
end

local function add_months(timestamp, months)
    local date = os.date("*t", timestamp)
    date.month = date.month + months
    return os.time(date)
end

local function add_years(timestamp, years)
    local date = os.date("*t", timestamp)
    date.year = date.year + years
    return os.time(date)
end

local function add_unit(timestamp, unit, amount)
    unit = unit:lower()
    if unit == "day" then
        return add_days(timestamp, amount)
    elseif unit == "month" then
        return add_months(timestamp, amount)
    elseif unit == "year" then
        return add_years(timestamp, amount)
    else
        error("Unknown unit: " .. unit)
    end
end

return {
    utc_timestamp = utc_timestamp,
    get_timezone_offset = get_timezone_offset,
    utc_to_local = utc_to_local,
    start_of_day = start_of_day,
    start_of_today = start_of_today,
    start_of_week = start_of_week,
    start_of_month = start_of_month,
    start_of_year = start_of_year,
    start_of_yesterday = start_of_yesterday,
    add_days = add_days,
    add_months = add_months,
    add_years = add_years,
    weekdays = weekdays,
    weekdays_short = weekdays_short,
    months = months,
    months_short = months_short,
}
