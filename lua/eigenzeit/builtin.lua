local DEBOUNCE_RATE_MS = 200

local GIT_BRANCH_EFFECT = "git_branch"
local FILE_PATH_EFFECT = "file_path"

-- https://www.reddit.com/r/neovim/comments/uz3ofs/heres_a_function_to_grab_the_name_of_the_current/
local function setup_check_git_branch(dispatch)
    local events = { "FileType", "BufEnter", "FocusGained" }
    local opts = {
        callback = require('eigenzeit.util').debounce(function()
            local git_branch = vim.fn.system("git branch --show-current 2> /dev/null | tr -d '\n'")
            local event = { kind = GIT_BRANCH_EFFECT, value = git_branch }
            dispatch(event)
        end, DEBOUNCE_RATE_MS)
    }
    vim.api.nvim_create_autocmd(events, opts)
end


local setup_check_filepath = function(dispatch)
    local events = { "BufEnter", "FocusGained" }
    local opts = {
        callback = require('eigenzeit.util').debounce(function()
            local path = vim.fn.expand("%:p")
                dispatch({
                    kind = FILE_PATH_EFFECT,
                    value = path,
                })
        end, DEBOUNCE_RATE_MS)
    }
    vim.api.nvim_create_autocmd(events, opts)
end

local function default_matcher(event, condition) -- omitting 3rd arg: tag
    local shouldMatchValue = condition.value or condition.pattern
    return shouldMatchValue or event.value:match(condition.pattern)
end

return {
    effects = {
        setup_check_git_branch = setup_check_git_branch,
        setup_check_filepath = setup_check_filepath,
    },
    default_matcher = default_matcher,
}
