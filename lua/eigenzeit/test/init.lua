local function get_test_files()
    local dir = debug.getinfo(1, "S").source:match("@(.*/)")
    return vim.fn.glob(dir .. "test-*.lua", false, true)
end


local function run_test_file(file)
    local tests = dofile(file)
    assert(type(tests) == "table", "test file must return a table")
    file = string.gsub(file, ".+/", "")
    local results = {
        name = tests.name or file,
        passed = 0,
        failed = 0,
        details = {},
    }
    for _, test in ipairs(tests) do
        local desc, fn = unpack(test)
        local ok, err = pcall(fn)
        if ok then
            results.passed = results.passed + 1
        else
            results.failed = results.failed + 1
        end
        -- if err, strip 'file' from the beginning of the string:
        table.insert(results.details, { desc = desc, ok = ok, err = err })
    end
    return results
end

local function run_suite()
    print("Running tests")
    local files = get_test_files()
    local results = {}
    local all_pass = true
    for _, file in ipairs(files) do
        local result = run_test_file(file)
        if result.failed > 0 then all_pass = false end
        table.insert(results, result)
    end
    results.pass = all_pass
    return results
end



local function print_results(results, verbose)
    local pass = "✓"
    local fail = "✗"
    for _, result in ipairs(results) do
        print(string.format("%s %d/%d - %s",
            result.failed == 0 and pass or fail,
            result.passed,
            result.passed + result.failed,
            result.name
        ))
        for _, err in ipairs(result.details) do
            if not err.ok or verbose then
                print(string.format("  %s %s", err.ok and pass or fail, err.desc))
                if not err.ok then
                    print("    " .. err.err)
                end
            end
        end
    end
end


local function assert_equals(a, b, msg)
    if a ~= b then
        if msg == nil then
            error(string.format("expected %s to equal %s", a, b))
        else
            error(string.format("expected %s to equal %s: %s", a, b, msg))
        end
    end
end

local function assert_deep_equals(a, b, msg)
    if vim.inspect(a) ~= vim.inspect(b) then
        if msg == nil then
            error(string.format("expected %s to equal %s", vim.inspect(a), vim.inspect(b)))
        else
            error(string.format("expected %s to equal %s: %s", vim.inspect(a), vim.inspect(b), msg))
        end
    end
end

local function assert_has_entries(tbl, entries, msg)
    for k, v in pairs(entries) do
        assert_equals(
            tbl[k], v,
            string.format("(%s) expected %s to have key %s with value %s", msg, vim.inspect(tbl), k, v))
    end
end

return {
    run_suite = run_suite,
    run_test_file = run_test_file,
    print_results = print_results,
    assert_equals = assert_equals,
    assert_deep_equals = assert_deep_equals,
    assert_has_entries = assert_has_entries,
}
