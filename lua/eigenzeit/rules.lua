

function builtin_path_changed()
    return {
        name = "path_changed",
        triggers = {"BufEnter"},
        create_payload = function()
            local path = vim.fn.expand("%:p")
            if path == "" then return
            end
        end
    }
end
