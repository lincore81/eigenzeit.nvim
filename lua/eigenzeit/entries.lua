local util = require('eigenzeit.util')

local KIND_WORK = "_work"

local function is_valid(entry)
    return entry.kind ~= KIND_WORK or (entry.from and entry.to)
end

local function is_work(entry)
    return entry and entry.kind == KIND_WORK
end

local function can_seal(entry)
    return entry and entry.kind == KIND_WORK
end

local function create_work(timestamp)
    return { kind = KIND_WORK, from = timestamp, to = timestamp }
end

local function seal_work(entry, timestamp)
    if entry ~= nil and entry.kind == KIND_WORK then
        entry.to = timestamp
        entry._str = util.range_to_string(entry)
        entry._sealed = true
    end
    return entry
end

local function add_work(entry, timestamp)
    if entry.kind == KIND_WORK then
        entry.to = timestamp
    end
    return entry
end

return {
    is_valid = is_valid,
    is_work = is_work,
    can_seal = can_seal,
    create_work = create_work,
    seal_work = seal_work,
    add_work = add_work,
    KIND_WORK = KIND_WORK,
}
