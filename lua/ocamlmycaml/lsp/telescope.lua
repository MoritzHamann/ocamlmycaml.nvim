local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local previewers = require('telescope.previewers')
local actions_state = require("telescope.actions.state")
local util = require("ocamlmycaml.util")
local lsp_api = require("ocamlmycaml.lsp.api")
local lsp_util = require('ocamlmycaml.lsp.util')
local log = util.create_logger("ocamlmycaml.lsp.telescope")

-- TODO: adding docs to search_by_type is waaaaay slower than without it
--       potentially we can either debounce the search and/or look up
--       the documetation on demand when the item is highlighted

return {
    search_by_type = function()
        local buffer = vim.api.nvim_get_current_buf()
        local position = lsp_util.get_merlin_pos()

        local merlin_finder = util.new_callback_finder({
            entry_maker = function(entry)
                local name = string.gsub(entry.name, "\n", "")
                local type = string.gsub(entry.type, "\n", "")
                local doc = ""

                if entry.doc ~= vim.NIL then
                    doc = entry.doc
                end
                return {
                    value = entry,
                    display = name .. " : " .. type,
                    ordinal = entry.cost,
                    doc = doc
                }
            end,
            fn = function(prompt, cb)

                --- @type MerlinCommand
                local merlin_options = {
                    command = "search-by-type",
                    args = {
                        "-position", position,
                        "-query", prompt,
                        "-limit", "50",
                        -- "-with-doc", "false"
                    },
                    asSexp = false
                }
                lsp_api.custom_methods.merlinCallCompatible(
                    buffer, merlin_options,
                    function(error, result)
                        if error ~= nil then
                            log.error(vim.inspect(error))
                            cb({})
                        end
                        local suggestions = vim.json.decode(result.result)
                        cb(suggestions.value)
                    end
                )
            end
        })

        local picker = pickers.new({
            prompt_title = "Search by type",
            finder = merlin_finder,
            previewer = previewers.new_buffer_previewer({
                title = "Docs",
                define_preview = function(self, entry, _)
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.doc, "\n"))
                end,
            }),
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = actions_state.get_selected_entry()
                    vim.api.nvim_paste(selection.value.constructible, false, -1)
                end)
                return true
            end
        }, {})

        picker:find()
    end
}
