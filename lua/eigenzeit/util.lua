-- Limit the rate at which a given `func` can be called to once every `limit_ms` 
-- milliseconds. Additional calls to `func` within this time period are ignored.
local function debounce(func, limit_ms)
    assert(type(limit_ms) == "number", "limit_ms must be a number")
    assert(limit_ms > 0, "limit_ms must positive")
    assert(type(func) == "function", "f must be a function")

    local last_call = 0
    return function(...)
        local args = {...}
        local now = vim.loop.now()
        local rolled_over = now < last_call
        if rolled_over or now - last_call > limit_ms then
            last_call = now
            return func(unpack(args))
        end
    end
end

local function is_same_day(a, b)
    local a_day = os.date("%Y-%m-%d", a)
    local b_day = os.date("%Y-%m-%d", b)
    return a_day == b_day
end

local function range_to_string(range)
    return string.format(
        "(%s)-(%s)",
        os.date("%Y-%m-%d %H:%M:%S", range.from),
        os.date("%Y-%m-%d %H:%M:%S", range.to))
end

local function has_keys(t, keys)
    if keys then
        for _, key in ipairs(keys) do
            if t[key] == nil then
                return false
            end
        end
    end
    return true
end

return {
    debounce = debounce,
    is_same_day = is_same_day,
    range_to_string = range_to_string,
    has_keys = has_keys
}

