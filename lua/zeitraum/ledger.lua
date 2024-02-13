local BREAK_THRESHOLD = 60 * 1000 * 5
local KIND_WORK = "_work"
local KIND = 1

local util = require("zeitraum.util")



local function close_work_entry(entry, opts, timestamp)
    timestamp = timestamp or os.time()
    if entry ~= nil and entry[KIND] == KIND_WORK then
        if entry.from and entry.to then
            local break_threshold = opts and opts.break_threshold or BREAK_THRESHOLD
            entry.to = math.min(timestamp, entry.to + break_threshold)
            entry._str = util.range_to_string(entry)
        else
            entry.from = entry.from or timestamp
            entry.to = entry.from
            entry._str = os.date("%Y-%m-%d %H:%M", entry.from)
            entry._info = "Fixed missing from/to"
        end
    end
    return entry
end


local function get_last_entry(log, kind)
    for i = #log, 1, -1 do
        local entry = log[i]
        if (not kind or entry[KIND] == kind) then
            return entry
        end
    end
end

local function create_work_entry(timestamp)
    timestamp = timestamp or os.time()
    return { KIND_WORK, from = timestamp, to = timestamp }
end


local function get_last_work_timestamp(ledger)
    local entry = get_last_entry(ledger, KIND_WORK)
    return entry and entry.to
end


local function get_current_work_gap(ledger, timestamp)
    local last_work = get_last_work_timestamp(ledger)
    if last_work == nil then return false end
    local now = timestamp or os.time()
    return now - last_work
end


local function can_update_work(ledger)
    local latest = ledger[#ledger]
    if latest == nil or latest[KIND] ~= KIND_WORK then
        return false
    end
    return true
end


local function add_event(ledger, event, opts, timestamp)
    local latest = ledger[#ledger]
    if latest and not latest.event then
        close_latest_entry(ledger, opts, timestamp)
    end
    local entry = vim.deepcopy(event)
    entry.timestamp = os.time()
    table.insert(ledger, entry)
end


local function add_work(ledger, opts, timestamp)
    timestamp = timestamp or os.time()
    local latest = ledger[#ledger]

    if not can_update_work(ledger) then
        latest = start_new_entry(ledger, timestamp)
    end
    local break_threshold = opts.break_threshold or BREAK_THRESHOLD
    local gap = get_current_work_gap(ledger, timestamp)
    local had_break = gap and gap > break_threshold

    if had_break then
        close_latest_entry(ledger, opts, timestamp)
        start_new_entry(ledger, opts, timestamp)
    elseif not util.is_same_day(latest.to, timestamp) then
        close_latest_entry(ledger, opts, timestamp)
        start_new_entry(ledger, opts, timestamp)
    else
        latest.to = timestamp
        latest._str = util.range_to_string(latest)
    end
    return ledger
end


local function select_entries(opts, ledger)
    -- TODO: use a better algorithm/data structure for this
    -- TODO: Can we bookmark start of days/weeks/months?
    -- TODO: Ledgers should have start and end times and we save one file
    --       per month or something (maybe ~2000 entriews)
    ledger = ledger or opts.ledger
    assert(ledger, "ledger is required")
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
    for _, entry in ipairs(ledger) do
        -- TODO: consider pruning entry times to be within from/to
        local in_time_range =
            not (from or to)
            or (entry.timestamp and entry.timestamp >= from and entry.timestamp <= to)
            or (entry.from and entry.to
                and (from <= entry.from and to > entry.from
                    or from < entry.to and entry.to <= to))
        local is_of_kind = in_time_range and not kind or entry[KIND] == kind
        if in_time_range and is_of_kind and util.has_keys(entry, other_keys) then
            table.insert(result, entry)
        end
    end
    return result
end

return {
    add_work = add_work,
    add_event = add_event,
    get_current_work_gap = get_current_work_gap,
    get_last_work_timestamp = get_last_work_timestamp,
    get_last_entry = get_last_entry,
    close_latest_entry = close_latest_entry,
    can_update_work = can_update_work,
    start_new_entry = start_new_entry,
    select_entries = select_entries,
}
