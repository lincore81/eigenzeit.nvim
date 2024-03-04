local WRITE_RATE_MS = 5000
local LOG_WORK_RATE_MS = 5000
local BREAK_THRESHOLD_SECS = 5 * 60

local M = {
    log = {},
    dirs = {
        data = vim.fn.stdpath('data'),
        plugin = vim.fn.stdpath('data') .. '/eigenzeit',
        logs = vim.fn.stdpath('data') .. '/eigenzeit/logs',
    },
}


local write_log_debounced, log_work_debounced

function M.run_tests(verbose)
    local test = require('eigenzeit.test')
    local results = test.run_suite()
    if verbose or not results.pass then
        test.print_results(results)
    end
end

local function setup_effects(dispatch)
    local effects = require('eigenzeit.builtin').effects
    for _, effect in pairs(effects) do
        effect(dispatch)
    end
end

local function setup_key_handler()
    vim.on_key(function()
        write_log_debounced()
        log_work_debounced(
            M.log,
            require("eigenzeit.datetime").utc_timestamp(),
            M.opts.break_threshold or BREAK_THRESHOLD_SECS)
    end)
end

function M.setup(_opts)
    M.opts = _opts or {}
    if not M.is_setup then
        if M.opts.logs_dir then M.dirs.logs = M.opts.logs_dir end
        M.load_log()
        M._blackboard = {}
        M.default_matcher = require('eigenzeit.builtin').default_matcher
        M.dispatch = require('eigenzeit.dispatch').create_dispatch(
            M.log,
            M._blackboard,
            require("eigenzeit.datetime").utc_timestamp)
        setup_effects(M.dispatch)
        local logger = require('eigenzeit.logger')
        local util = require('eigenzeit.util')
        write_log_debounced = util.debounce(
            M.save_log,
            M.opts.write_rate_ms or WRITE_RATE_MS)
        log_work_debounced = util.debounce(
            logger.log_work,
            M.opts.log_work_rate_ms or LOG_WORK_RATE_MS)
        setup_key_handler()
        M.is_setup = true
    end
end


---- SERIALISATION ----

function M.load_log()
    local file = io.open(M.dirs.logs .. '/log.json', 'r')
    if file then
        local content = file:read('*a')
        file:close()
        M.log = vim.json.decode(content) or {}
    else
        M.log = { _version = 1 }
    end
end

function M.save_log()
    vim.fn.mkdir(M.dirs.logs, 'p')
    local file = io.open(M.dirs.logs .. '/log.json', 'w')
    if not file then
        print('Could not open file for writing')
        return
    end
    file:write(vim.json.encode(M.log))
    file:close()
end

return M
