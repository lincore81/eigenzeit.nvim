local IND_WORK = "_work"

local function is_valid(entry)
    return entry.kind ~= KIND_WORK or (entry.from and entry.to)
end

local function is_work(entry)
    return entry.kind == KIND_WORK
end

local function create_work_entry(timestamp)
    return { kind = KIND_WORK, from = timestamp, to = timestamp }
end


local function seal_work_entry(entry, timestamp)
    if entry ~= nil and entry.kind == KIND_WORK then
        entry.to = timestamp
        entry._str = util.range_to_string(entry)
        entry._sealed = true
    end
    return entry
end

return {
    is_valid = is_valid,
    is_work = is_work,
    create_work_entry = create_work_entry,
    seal_work_entry = seal_work_entry,
}
