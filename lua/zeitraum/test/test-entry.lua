local entries = require('zeitraum.entries')

return {
    unit = "entries",
    { "seal_work", function()
        local entry = { kind = "_work", from = 0, to = 0 }
        assert(entries.seal_work(entry, 100).to == 100,
            "Sealing work entry")
        assert(entry.to == 100, "closing work entry with timestamp")
        entry = { kind = "_foo", from = 0, to = 0 }
        assert(entries.seal_work(entry, 100).to == 0,
            "Trying to seal non-work changes nothing")
    end},
}
