local dune = require("ocamlmycaml.dune")
local lsp = require("ocamlmycaml.lsp")
local utop = require("ocamlmycaml.utop")

--- @class DuneSetup
--- @field autostart boolean

--- @class LspSetup


--- @class OcamlMyCamlSetup
--- @field dune DuneSetup
--- @field lsp LspSetup
--- @field mappings table<string, string|function>


local M = {}

--- @param opts OcamlMyCamlSetup
M.setup = function(opts)
    vim.lsp.set_log_level("DEBUG")

    -- setup the telescope extension (will make sure the autocomplete is available)
    -- can be accessed via :Telescope ocamlmycaml search_by_type
    require('telescope').load_extension("ocamlmycaml")

    -- setup dune options
    M.dune = dune.setup(opts.dune)

    -- setup key bindings
    M.mappings_autocmd_group = vim.api.nvim_create_augroup("ocamlmycaml.mappings", {})
    if opts.mappings ~= nil and type(opts.mappings) == 'table' then
        vim.api.nvim_create_autocmd('BufEnter', {
            group = M.mappings_autocmd_group,
            pattern = {"*.ml", "*.re", "*.mli", "*.rei"},
            callback = function(ev)
                --- @type vim.keymap.set.Opts
                local mapping_opts = {remap = false, buffer = ev.buf}

                -- example or mappings
                --[[
                local mappings = {
                    ["<leader>ocb"] = dune.build,
                    ["<leader>ocb"] = {cmd = dune.build, mode = "n"},
                    ["<C-s>"] = {cmd = function() end, mode = {"n", "i"}},
                }
                --]]

                for key, rhs in pairs(opts.mappings) do
                    if type(rhs) == "table" then
                        vim.keymap.set(rhs.mode, key, rhs.cmd, mapping_opts)
                    else
                        vim.keymap.set("n", key, rhs, mapping_opts)
                    end
                end
            end
        })

    end

    -- TODO: clean this up
    -- vim.api.nvim_create_user_command("Ocamllsp", function (command)
    --     local args = command.fargs
    --     if #args < 1 then
    --         return
    --     end
    --
    --     local buffer = vim.api.nvim_get_current_buf()
    --     if args[1] == "switch" then
    --         lsp.switchImplIntf(buffer)
    --     elseif args[1] == "hole" then
    --         lsp.nextHole(buffer)
    --     elseif args[1] == "typesearch" then
    --         lsp.merlin.find_by_type()
    --     end
    -- end, {nargs = '*'})

    -- setup main :Dune command which executes `dune` with the arguments
    vim.api.nvim_create_user_command("Dune", dune.dune_command, {nargs = '*'})

    -- setup command to stop individual watch builds
    vim.api.nvim_create_user_command("DuneStop", dune.select_job_to_stop, {})

    --- @type Utop
    local utop_instance = nil
    vim.api.nvim_create_user_command("Utop", function()
        local file = vim.api.nvim_buf_get_name(0)
        local root = dune.find_project_folder(file)
        if root == nil then
            print("Not a dune directory")
            return
        end
        local tmp = utop.utop_command(root, {'dune', 'utop', '--build-dir=_build_utop', '.', '--', '-emacs'})
        if tmp == nil then
            print("Error")
        else
            utop_instance = tmp
        end
    end, {})


    -- vim.keymap.set('n', '<leader>k', function()
    --     local lspApi = require("ocamlmycaml.lsp.api");
    --     lspApi.custom_methods.hoverExtended(0, function(error, data)
    --         vim.notify(vim.inspect(error))
    --         vim.notify(vim.inspect(data))
    --     end)
    -- end, {})

    -- vim.keymap.set('n', '<leader>oo', function()
    --     lsp.expand_ppx()
    -- end, {})

    -- vim.keymap.set('n', '<leader>oa', function()
    --     local lspApi = require("ocamlmycaml.lsp.api");
    --     lspApi.custom_methods.construct(0, function(error, data)
    --         vim.notify(vim.inspect(error))
    --         vim.notify(vim.inspect(data))
    --     end)
    -- end, {})

    vim.keymap.set({'v'}, '<C-CR>', function ()
        -- \22 => CTRL-V => visual block mode
        local mode = vim.fn.mode()
        if mode == '\22' then
            print("bug in vim.region(), unable to use")
            return
        end

        local selection = vim.region(0, '.', 'v', mode, true)
        local lines = {}

        for row_nr, position in pairs(selection) do
            local start_col, end_col = position[1], position[2]
            local line = vim.api.nvim_buf_get_text(0, row_nr, start_col, row_nr, end_col, {})[1]
            table.insert(lines, line)
        end

        utop_instance:evaluate_multi_input(lines)
    end, {})

    -- TODO: does this need to return anything?
    return {}
end



return M
