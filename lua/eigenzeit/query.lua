
local function query_time(from, to, log)
    local result = 0
    from = os.time(from)
    to = os.time(to)
    for _, entry in ipairs(log) do
        if entry.from >= from and entry.to <= to then
            result = result + math.max(entry.to - entry.from, 0)
        end
    end
    return result
end

return {
    query_time = query_time
}
