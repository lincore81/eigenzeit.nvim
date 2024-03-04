-- Take a date range encoded in natural language and return a range of timestamps.

local D = require("eigenzeit.datetime")


local weekdays = {
    sunday = 1,
    monday = 2,
    tuesday = 3,
    wednesday = 4,
    thursday = 5,
    friday = 6,
    saturday = 7,
}

local weekdays_short = {
    sun = 1,
    mon = 2,
    tue = 3,
    wed = 4,
    thu = 5,
    fri = 6,
    sat = 7,
}

local months = {
    january = 1,
    february = 2,
    march = 3,
    april = 4,
    may = 5,
    june = 6,
    july = 7,
    august = 8,
    september = 9,
    october = 10,
    november = 11,
    december = 12,
}

local months_short = {
    jan = 1,
    feb = 2,
    mar = 3,
    apr = 4,
    may = 5,
    jun = 6,
    jul = 7,
    aug = 8,
    sep = 9,
    oct = 10,
    nov = 11,
    dec = 12,
}

local reductions = {
    { { "modifier", { type = "datetime", fixed = false } }, function(modifier, datetime)
        if datetime.unit and modifier.offset then
            local result = vim.deepcopy(datetime)
            result.value = D.add_unit(result.value, result.unit, modifier.offset)
        end
    end },
}

local queries = {
    { { "datetime", "to", "datetime" }, function(from, _, to)
        return { from = from.from or from.value, to = to.to or to.value }
    end },
    { "datetime", function(datetime)
        return { from = datetime.from or datetime.value, to = datetime.to or datetime.value }
    end },
}


local function tokenise(str)
    local tokens = {}
    for token in string.gmatch(str, "%w+") do
        table.insert(tokens, token)
    end
    return tokens
end


local function try_parse_iso_datetime(token)
    local year, month, day, hour, min, sec =
        string.match(token, "(%d+)-(%d+)-(%d+)[Tt:-](%d+):(%d+):(%d+)")
    if not year then
        year, month, day, hour, min =
            string.match(token, "(%d+)-(%d+)-(%d+)[Tt:-](%d+):(%d+)")
        sec = 0
        if not year then
            year, month, day = string.match(token, "(%d+)-(%d+)-(%d+)")
            hour, min, sec = 0, 0, 0
        end
    end

    year, month, day, hour, min, sec =
        tonumber(year), tonumber(month), tonumber(day),
        tonumber(hour), tonumber(min), tonumber(sec)

    if not year or not month or not day then return nil end
    return {
        type = "datetime",
        value = os.time {
            year = year,
            month = month,
            day = day,
            hour = hour,
            min = min,
            sec = sec
        },
        fixed = true,
        token = token
    }
end


local function lex1(token, first_day_of_week)
    token = token:lower()

    if token == "last" then
        return { type = "modifier", offset = -1, token = token }
    elseif token == "to" then
        return { type = "to", token = token }
    elseif token == "today" then
        local from = D.start_of_today()
        return {
            type = "datetime",
            from = from,
            to = D.add_days(from, 1),
            unit = "day",
            token = token
        }
    elseif token == "yesterday" then
        local from = D.start_of_today()
        return {
            type = "datetime",
            from = from,
            to = D.add_days(from, 1),
            unit = "day",
            token = token
        }
    elseif token == "week" then
        local from = D.start_of_week(first_day_of_week)
        return {
            type = "datetime",
            from = from,
            to = D.add_days(from, 7),
            unit = "week",
            token = token
        }
    elseif token == "month" then
        local from = D.start_of_month()
        return {
            type = "datetime",
            from = from,
            to = D.add_months(from, 1),
            unit = "month",
            token = token
        }
    elseif token == "year" then
        local from = D.start_of_year()
        return {
            type = "datetime",
            from = from,
            to = D.add_years(from, 1),
            unit = "year",
            token = token
        }
    end

    --    local weekday = weekdays[token] or weekdays_short[token]
    --    if weekday ~= nil then
    --        return {
    --            type = "datetime",
    --            from = weekday, unit = "day", token = token }
    --    end
    --    local month = months[token] or months_short[token]
    --    if month ~= nil then
    --        return { type = "datetime", abs = false, value = month, token = token }
    --    end
    --    local number = tonumber(token)
    --    if number and number > 1900 then
    --        return { type = "year", value = number, token = token }
    --    end

    local iso = try_parse_iso_datetime(token)
    if iso then return iso end
end


local function lex(tokens, first_day_of_week)
    local result = {}
    for _, token in ipairs(tokens) do
        table.insert(result, lex1(token, first_day_of_week))
    end
end


local function take(n, tbl)
    local result = {}
    for i = 1, n do
        table.insert(result, tbl[i])
    end
    return result
end


local function drop(n, tbl)
    for _ = 1, n do
        table.remove(tbl, 1)
    end
end


local compare_fields = function(a, b)
    for k, v in pairs(a) do
        if b[k] ~= v then return false end
    end
    return true
end


local match_tokens = function(pattern, tokens)
    if #pattern ~= #tokens then return false end
    for i, token in ipairs(tokens) do
        local p = pattern[i]
        if (type(p) == "table" and not compare_fields(p, token))
            or type(p) == "string" and p ~= token.type then
            return false
        end
    end
    return true
end


local try_reduce_form = function(form, tokens)
    local pattern, reducer = unpack(form)
    local n = #pattern
    if #tokens < n then return end
    local candidate = take(n, tokens)
    if not match_tokens(pattern, candidate) then return end
    return reducer(unpack(candidate)), 3
end


local function apply_reductions(tokens)
    local input = vim.deepcopy(tokens)
    local output = {}
    while #input > 0 do
        local reduced
        local n
        for _, form in ipairs(reductions) do
            reduced, n = try_reduce_form(form, input)
            if reduced then break end
        end
        if reduced then
            table.insert(output, reduced)
            drop(n, input)
        else
            table.insert(output, table.remove(input, 1))
        end
    end
    return output
end


-- Must be called after lexer
local function parse(tokens)
    tokens = apply_reductions(tokens)
    for _, variant in ipairs(queries) do
        local pattern, reducer = unpack(variant)
        if match_tokens(pattern, tokens) then
            return reducer(unpack(tokens))
        end
    end
end


local function parse_query(query, first_day_of_week)
    local tokens = tokenise(query)
    local lexed = lex(tokens, first_day_of_week)
    return parse(lexed)
end

return {
    _tokenise = tokenise,
    _lex = lex,
    _parse = parse,
    parse_query = parse_query,
}
