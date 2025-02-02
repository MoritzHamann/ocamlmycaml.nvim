local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
-- local previewers = require('telescope.previewers')
local actions_state = require("telescope.actions.state")
local util = require("ocamlmycaml.util")
local log = util.create_logger("ocamlmycaml.sherlodoc")


local query_sherlodoc = function(prompt, cb)
    local cmd = {"sherlodoc", "search", prompt}
    log.info("prompt: " .. prompt)

    vim.system(cmd, nil, vim.schedule_wrap(function(completed)
        local err = completed.stderr
        if err ~= nil and err ~= "" then
            log.error(err)
            return
        end

        local output = completed.stdout
        if output == nil then
            log.info("No result")
            return
        end
        local lines = vim.split(output, "\n", {trimempty = true})

        -- TODO: we may get long type signatures which are broken over multiple
        -- lines. So we need to combine them and add a new entry only when we
        -- encounter type, value, module or other identifiers (maybe just
        -- check if the first character is whitespace?)
        -- Also should multi-line definitions be kept, but show in a preview window?
        local results = {}
        for idx, line in ipairs(lines) do
            table.insert(results, {value=line, idx=idx})
        end
        cb(results)
    end))
end



return {
    --[[
    TODO: need to add some parameters
          - DB path + format
          - number of results
          - pre-selected text
    ]]--
    search = function()

        local sherlodoc_finder = util.new_callback_finder({
            entry_maker = function(entry)
                return {
                    ordinal = entry.idx,
                    value = entry,
                    display = entry.value
                }
            end,
            fn = query_sherlodoc
        })

        local picker = pickers.new({
            prompt_title = "Search Sherlodoc",
            finder = sherlodoc_finder,
            -- previewer = previewers.new_buffer_previewer({
            --     title = "Docs",
            --     define_preview = function(self, entry, _)
            --         vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.doc, "\n"))
            --     end,
            -- }),
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = actions_state.get_selected_entry()
                    vim.api.nvim_paste(selection.value.value, false, -1)
                end)
                return true
            end
        }, {})

        picker:find()
    end
}
