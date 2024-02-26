local M = {}

local logger = require('eigenzeit.logger')
local util = require('eigenzeit.util')
local test = require('eigenzeit.test')

local onkey_handler_added = true
local log = { }
local opts = { }

local dirs = {
    data = vim.fn.stdpath('data'),
    plugin = vim.fn.stdpath('data') .. '/eigenzeit',
    logs = vim.fn.stdpath('data') .. '/eigenzeit/logs',
}

M._log = {}
M._dirs = dirs

local write_ledger_debounced, update_ledger_debounced

local function add_on_key_handler()
    vim.on_key(function()
        write_ledger_debounced()
        update_ledger_debounced(log, opts)
    end)
end

function M.cmd_dump()
    vim.print(log)
end

function M.setup(_opts)
    opts = _opts or {}
    if not onkey_handler_added then
        add_on_key_handler()
        onkey_handler_added = true
    end
--    write_ledger_debounced = util.debounce(M.save_log, opts.write_rate_ms or 5000)
--    update_ledger_debounced = util.debounce(ledger.add_work, opts.update_rate_ms or 1000)
--    M.load_log()
    local results = test.run_suite()
    test.print_results(results)
end

function M.load_log()
    local file = io.open(dirs.plugin .. '/log.json', 'r')
    if file then
        local content = file:read('*a')
        file:close()
        log = vim.json.decode(content) or {}
    else
        log = { _version = 1 }
    end
end

function M.save_log()
    vim.fn.mkdir(dirs.plugin, 'p')
    local file = io.open(dirs.plugin .. '/log.json', 'w')
    if not file then
        print('Could not open file for writing')
        return
    end
    file:write(vim.json.encode(log))
    file:close()
end

return M
