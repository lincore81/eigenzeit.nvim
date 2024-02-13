local ledger = require('zeitraum.ledger')

-- TODO: testing framework? or at least something less painful than this
local tests = {

    { "close_latest_entry", function()
        assert(ledger.close_latest_entry({}) == nil, "closing empty ledger")
        local log = { { "_work", from = 0, to = 0 } }
        ledger.close_latest_entry(log, 100)
        assert(log[1].to == 100, "closing work entry with timestamp")
    end },

    { "start_new_entry", function()
        local log = {}
        ledger.start_new_entry(log)
        assert(log[1][1] == "_work", "new entry is _work")
        assert(type(log[1].from) == "number", "new entry has from")
        assert(type(log[1].to) == "number", "new entry has to")
    end },

    { "get_last_entry", function()
        local kind = "foo"
        local log = { { kind } }
        local result = ledger.get_last_entry(log)
        assert(type(result) == "table" and result[1] == kind,
            "get last entry when called without kind or other_keys")
        log = { { "bar" }, { kind, n = 1 }, { kind, n = 2 }, { "baz", n = 3 } }
        result = ledger.get_last_entry(log, kind)
        assert(result.n == 2, "get last entry with kind")
    end },

    { "get_last_work_timestamp", function()
        local log = { { "_work", from = 0, to = 100 }, { "bar" } }
        assert(ledger.get_last_work_timestamp(log) == 100, "get last work timestamp")
    end },

    { "get_current_work_gap", function()
        local log = { { "_work", from = 0, to = 100 } }
        assert(ledger.get_current_work_gap(log, 200) == 100, "get current work gap")
    end },

    { "can_update_work", function()
        local log = {}
        assert(not ledger.can_update_work(log), "can't update work on empty ledger")
        log = { { "_work", from = 0, to = 100 } }
        assert(ledger.can_update_work(log), "can update if latest is work entry")
    end },

    { "add_event", function()
        local log = {}
        ledger.add_event(log, {"foo", x = 12})
        assert(log[1][1] == "foo", "add event adds event with kind")
        assert(log[1].x == 12, "add event adds event with context")
    end },

    { "add_work", function()
        local log = {}
        ledger.add_work(log, {}, 100)
        assert(log[1][1] == "_work", "add work to empty adds work entry")
        assert(log[1].from == 100, "add work to empty adds work entry with from")
        assert(log[1].to == 100, "add work to empty adds work entry with to")

        log = {
            {"_work", from = 1, to = 2},
        }
        ledger.add_work(log, {break_threshold = 1}, 4)
        vim.print(log)
        assert(log[1].to == 3, "add work after break adds break_threshold to last entry")
        assert(log[2].from == 4, "add work after break adds new work entry")

    end },

    { "select_entries", function()
        local log = {
            {"_work", from = 0, to = 100},
            {"foo", x = 12, timestamp = 150},
            {"bar", y = 13, timestamp = 200},
            {"_work", from = 1000, to = 2000},
            {"baz", z = 14, timestamp = 3000},
            {"_work", from = 4000, to = 5000},
            {"baz", z = 14, timestamp = 5100},
        }
        local result = ledger.select_entries{ledger=log, 200, 4500}
        assert(#result == 4, "select entries returns all entries at least partially within range")
        result = ledger.select_entries{200, 4500, ledger=log, kind="_work"}
        local work_time = 0
        for _, entry in ipairs(result) do
            if entry[1] == "_work" then
                work_time = work_time + entry.to - entry.from
            end
        end
        assert(work_time == 2000, "select entries with kind returns only entries of that kind")
        result = ledger.select_entries{ledger=log, kind="_work"}
        work_time = 0
        for _, entry in ipairs(result) do
            if entry[1] == "_work" then
                work_time = work_time + entry.to - entry.from
            end
        end
        assert(work_time == 2100, "select entries with kind and no range returns all entries of that kind")
        result = ledger.select_entries{ledger=log}
        assert(#result == 7, "select entries with no filters returns all entries")
    end},
}


local function run_tests()
    local passed = 0
    for _, test in ipairs(tests) do
        local name, fn = unpack(test)
        local ok, err = pcall(fn)
        print(string.format("%s %s", ok and "PASS" or "FAIL", name))
        if not ok then
            print(err)
        else
            passed = passed + 1
        end
    end
    print(string.format("%d/%d tests passed", passed, #tests))
end

return {
    run_tests = run_tests,
    tests = tests,
    reload = function()
        package.loaded['zeitraum.ledger'] = nil
        package.loaded['zeitraum.test.test-ledger'] = nil
    end
}
