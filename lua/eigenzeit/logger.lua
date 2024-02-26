local BREAK_THRESHOLD = 60 * 1000 * 5

local util = require("eigenzeit.util")
local entries = require("eigenzeit.entries")


local function make_log()
    return {
        _VERSION = 1
    }
end


local function get_last_entry(log, ofkind)
    for i = #log, 1, -1 do
        local entry = log[i]
        if (not ofkind or entry.kind == ofkind) then
            return entry
        end
    end
end


local function get_last_work_timestamp(log)
    local entry = get_last_entry(log, entries.KIND_WORK)
    return entry and entry.to
end


local function get_current_work_gap(log, timestamp)
    local last_work = get_last_work_timestamp(log)
    if last_work == nil then return false end
    return timestamp - last_work
end


local function can_update_work(log)
    local latest = log[#log]
    return latest ~= nil and latest.kind == entries.KIND_WORK
end


local function try_seal_maybe_with_break(log, timestamp, break_threshold)
    local latest = log[#log]
    if not entries.can_seal(latest) then return false end
    break_threshold = break_threshold or BREAK_THRESHOLD
    local gap = get_current_work_gap(log, timestamp)
    local ts = (gap and gap > break_threshold)
        and latest.to + break_threshold
        or timestamp
    log[#log] = entries.seal_work(latest, ts)
    return true
end


local function _add_event(log, event, timestamp)
    local entry = vim.deepcopy(event)
    entry.timestamp = timestamp
    table.insert(log, entry)
end

local function log_event(log, event, timestamp, break_threshold)
    try_seal_maybe_with_break(log, timestamp, break_threshold)
    _add_event(log, event, timestamp)
end

local function _new_work(log, timestamp)
    table.insert(log, entries.create_work(timestamp))
end

local had_break = function(log, timestamp, break_threshold)
    local latest = log[#log]
    break_threshold = break_threshold or BREAK_THRESHOLD
    return entries.is_work(latest)
        and get_current_work_gap(log, timestamp) > break_threshold
end


local function log_work(log, timestamp, break_threshold)
    local latest = log[#log]
    if not can_update_work(log) or not util.is_same_day(latest.to, timestamp) then
        _new_work(log, timestamp)
    elseif had_break(log, timestamp, break_threshold) then
        try_seal_maybe_with_break(log, timestamp, break_threshold)
        _new_work(log, timestamp)
    else
        latest.to = timestamp
        latest._str = util.range_to_string(latest)
    end
    return log
end


local function select_entries(log, opts)
    -- TODO: use a better algorithm/data structure for this
    -- TODO: Ledgers should have start and end times and we save one file
    --       per month or something (maybe ~2000 entriews)
    opts = opts or {}
    assert(log, "log is required")
    local from = opts.from or opts[1]
    local to = opts.to or opts[2]
    local kind = opts.kind
    local other_keys = opts.other_keys
    local result = {}
    if from and not to then
        to = os.time()
    elseif to and not from then
        from = 0
    end
    for _, entry in ipairs(log) do
        -- TODO: consider pruning entry times to be within from/to
        local in_time_range =
            not (from or to)
            or (entry.timestamp and entry.timestamp >= from and entry.timestamp <= to)
            or (entry.from and entry.to
                and (from <= entry.from and to > entry.from
                    or from < entry.to and entry.to <= to))
        local is_of_kind = not kind or entry.kind == kind
        if in_time_range and is_of_kind and util.has_keys(entry, other_keys) then
            table.insert(result, entry)
        end
    end
    return result
end


return {
    empty_log = make_log,
    try_seal_maybe_with_break = try_seal_maybe_with_break,
    get_last_entry = get_last_entry,
    get_last_work_timestamp = get_last_work_timestamp,
    get_current_work_gap = get_current_work_gap,
    can_update_work = can_update_work,
    had_break = had_break,
    log_event = log_event,
    log_work = log_work,
    select_entries = select_entries,
}
