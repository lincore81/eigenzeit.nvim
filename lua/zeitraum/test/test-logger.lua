local logger = require('zeitraum.logger')
local t = require('zeitraum.test')

return {
    { "get_last_entry", function()
        local log = {
            { kind = "foo" },
            { kind = "_work" },
            { kind = "baz" },
        }
        t.assert_equals(logger.get_last_entry(log).kind, "baz",
            "Getting last entry")
        t.assert_equals(logger.get_last_entry(log, "_work").kind, "_work",
            "Getting last entry of kind")
    end },

    { "get_last_work_timestamp", function()
        local log = {
            { kind = "foo" },
            { kind = "_work", to = 100 },
            { kind = "_work", to = 200 },
        }
        t.assert_equals(logger.get_last_work_timestamp(log), 200,
            "Getting last work timestamp when last is work")

        log = {
            { kind = "_work", to = 100 },
            { kind = "_work", to = 200 },
            { kind = "foo" },
        }
        t.assert_equals(logger.get_last_work_timestamp(log), 200,
            "Getting last work timestamp when last is not work")
    end },

    { "get_current_work_gap", function()
        local log = {
            { kind = "_work", to = 200 },
        }
        t.assert_equals(logger.get_current_work_gap(log, 300), 100,
            "Getting current work gap")
        log = {
            { kind = "foo" },
        }
        t.assert_equals(logger.get_current_work_gap(log, 150), false,
            "Getting current work gap when no work is logged")
    end },

    { "can_update_work", function()
        local log = {
            { kind = "_work", to = 100 },
            { kind = "_work", to = 200 },
        }
        t.assert_equals(logger.can_update_work(log), true,
            "Can update work when last is work")
        log = {
            { kind = "_work", to = 100 },
            { kind = "foo" },
        }
        t.assert_equals(logger.can_update_work(log), false,
            "Can't update work when last is not work")
        log = {}
        t.assert_equals(logger.can_update_work(log), false,
            "Can't update work when log is empty")
    end },

    { "try_seal_maybe_with_break", function()
        local log = {
            { kind = "_work", from = 0, to = 100 },
        }
        logger.try_seal_maybe_with_break(log, 150, 100)
        t.assert_equals(log[1].to, 150,
            "Sealing work below break threshold uses timestamp")
        assert(log[1]._sealed, "Sealing marks entry as sealed")
        log = {
            { kind = "_work", from = 0, to = 100 },
        }
        logger.try_seal_maybe_with_break(log, 300, 50)
        t.assert_equals(log[1].to, 150,
            "Sealing work with gap greater than threshold adds the threshold")
        log = {
            { kind = "foo", from = 100, to = 100 },
        }
        logger.try_seal_maybe_with_break(log, 200, 50)
        assert(not log[1]._sealed, "Trying to seal non-work changes nothing")
    end },

    { "can_update_work", function()
        local log = {
            { kind = "_work", from = 0, to = 100 },
        }
        t.assert_equals(logger.can_update_work(log), true,
            "Can update work when last is work")
        log = {
            { kind = "_work", from = 0, to = 100 },
            { kind = "foo" },
        }
        t.assert_equals(logger.can_update_work(log), false,
            "Can't update work when last is not work")
        log = {}
        t.assert_equals(logger.can_update_work(log), false,
            "Can't update work when log is empty")
    end },

    { "log_event", function()
        local log = {}
        logger.log_event(log, { kind = "foo" }, 100)
        t.assert_equals(log[1].kind, "foo", "Logging event")
        t.assert_equals(log[1].timestamp, 100, "Logging event with timestamp")
    end },

    { "had_break", function()
        local log = {
            { kind = "_work", from = 0, to = 100 },
        }
        t.assert_equals(logger.had_break(log, 200, 100), false,
            "No break when gap is at/below threshold")
        t.assert_equals(logger.had_break(log, 201, 100), true,
            "Break when gap is above threshold")
    end },

    { "log_work", function()
        local log = {}
        logger.log_work(log, 100, 10000)
        t.assert_has_entries(log[#log], { kind = "_work", from = 100, to = 100 },
            "Logging work in empty log just adds the work entry")
        logger.log_work(log, 200, 10000)
        t.assert_equals(log[#log].to, 200, "Logging work in non-empty log updates the work entry")
        logger.log_work(log, 500, 100)
        t.assert_equals(log[#log].to, 300, "Logging after break adds break threshold to work entry")
    end },
}
