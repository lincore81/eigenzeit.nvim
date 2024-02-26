

local function builtin_path_changed(handle_event)
    vim.api.nvim_create_autocmd({"BufEnter"}, {
        pattern = "*",
        callback = function()
            local path = vim.fn.expand("%:p")
            if path == "" then return end
            handle_event("path_changed", path)
        end
    })
end

local function builtin_git_repo_changed(handle_event)
    vim.api.nvim_create_autocmd({"BufEnter"}, {
        pattern = "*",
        callback = function()
            
        end
    })
end

local function get_git_branch(path)
    local git_branch = vim.fn.system("git -C " .. path .. " rev-parse --abbrev-ref HEAD")
    if #git_branch == 0 then
        return
    else
        return git_branch[1]
    end
end

local function get_remote_repo_name(path)
    local remote_repo_name = vim.fn.system("git -C " .. path .. " remote -v")
    return remote_repo_name
end

return {
    builtin_path_changed = builtin_path_changed,
    builtin_git_repo_changed = builtin_git_repo_changed
}

