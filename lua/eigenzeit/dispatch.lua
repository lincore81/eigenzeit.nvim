local function is_serialisable(tbl, seen_tables)
    seen_tables = seen_tables or { [tbl] = true }
    for _, v in pairs(tbl) do
        local t = type(v)
        if t == "function" or t == "userdata" or t == "thread" then
            return false, "must not contain function, userdata or thread"
        elseif t == "table" then
            if seen_tables[v] then
                return false, "contains a circular reference"
            end
            seen_tables[v] = true
            local ok, err = is_serialisable(v, seen_tables)
            if not ok then
                return false, err
            end
        end
    end
    return true
end


local function validate_event(event)
    assert(type(event) == "table", "Event must be a table")
    assert(type(event.kind) == "string", "Event kind must be a string")
    assert(event.value ~= nil, "Event value must not be nil")
    local ok, err = is_serialisable(event)
    assert(ok, "Event table must be serialisable: " .. (err or "unknown error"))
end


local function create_dispatch(log, blackboard, time_getter)
    return function(event)
        local changed = blackboard[event.kind] ~= event.value
        if not changed then return end

        event = vim.deepcopy(event)
        validate_event(event)
        blackboard[event.kind] = event.value
        require("eigenzeit.logger").log_event(log, event, time_getter())
    end
end

return {
    create_dispatch = create_dispatch,
}
