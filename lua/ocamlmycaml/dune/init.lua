-- local Job = require('plenary.job')
local DuneJob = require('ocamlmycaml.dune.dune_job').DuneJob


-- TODOs:
-- * stop DuneJob when last buffer of project is closed
-- * log DuneJob output to buffer (?)
-- * investigate use of different build directories
--   (i.e. to be able to run `dune build` and `dune utop` simultaneous)
-- * get a list of dune defined dependencies (requires `sexp` to be installed):
--      `dune describe external-lib-deps | sexp query "smash (field external_deps) each (index 0)"`


local M = {
    DuneJob = DuneJob
}

--- @param dune_root string dune project root folder
--- @return DuneJob|nil
M.find_dune_job_for_project = function(dune_root)
    for _, job in ipairs(DuneJob.active_jobs()) do
        if job.root_path == dune_root then
            return job
        end
    end
    return nil
end

local function stop_all_dune_jobs()
    for _, job in ipairs(DuneJob.active_jobs()) do
        if job ~= nil then
            job:stop()
        end
    end
end


-- TODO: document opts
M.setup = function(opts)
    -- store settings for later access in other functions
    M.opts = opts

    local au_grp = vim.api.nvim_create_augroup("ocamlmycaml.dune", {})

    -- used for hot reload of plugin during development under Lazy
    vim.api.nvim_create_autocmd({"User"}, {
        group = au_grp,
        once = false,
        pattern = {"OcamlMyCamlStart", "OcamlMyCamlStop"},
        callback = function(event)
            if event.match == "OcamlMyCamlStart" then
                -- query all workspaces for the ocamllsp client and start those DuneJobs
                local dune_jobs = vim.g.ocamlmycaml_jobs
                for _, job_table in ipairs(dune_jobs) do
                    DuneJob:run(job_table.root_path, job_table.command)
                end
            elseif event.match == "OcamlMyCamlStop" then
                local jobs = vim.tbl_map(function(job) return job:toTable() end, DuneJob.active_jobs())
                jobs = vim.tbl_values(jobs)
                vim.g.ocamlmycaml_jobs = jobs
                stop_all_dune_jobs()
            end
        end
    })

    vim.api.nvim_create_autocmd({"VimLeavePre"}, {
        group = au_grp,
        once = false,
        pattern = {"*"},
        callback = function(_)
            stop_all_dune_jobs()
        end
    })

    -- ensure we start a default build job once we enter an ocaml file in a dune project
    if opts.auto_start == true then
        vim.api.nvim_create_autocmd({"LspAttach"}, {
            group = au_grp,
            once = false,
            pattern = {"*.ml", "*.mli"},
            callback = function(event)
                local file = event.file
                local dune_root = M.find_project_folder(file)

                -- only start job if it's not yet running
                if dune_root ~= nil then
                    for _, job in ipairs(DuneJob.active_jobs()) do
                        if job.root_path == dune_root then
                            return
                        end
                    end
                    -- we haven't found an active job for the current root dir
                    DuneJob:run(dune_root, {"dune", "build", "-w", "--build-dir=_build_lsp"})
                end
            end
        })
        return
    end
end

--- check if folder is part of a dune project by searching up the file tree for a `dune-project` file
---@param file string
---@return string | nil
M.find_project_folder = function (file)
    local is_readable = vim.fn.filereadable(file) == 1
    if not is_readable then
        return nil
    end
    return vim.fs.root(file, "dune-project")
end


-- stop all running dune jobs
M.stop_all_dune_jobs = stop_all_dune_jobs


--- @class UserCommandInfo
--- @field name string Command name
--- @field args string The args passed to the command, if any
--- @field fargs table The args split by unescaped whitespace (when more than one argument is allowed), if any
--- @field nargs string Number of arguments `:command-nargs`
--- @field bang boolean "true" if the command was executed with a ! modifier
--- @field line1 number The starting line of the command range
--- @field line2 number The final line of the command range
--- @field range number The number of items in the command range: 0, 1, or 2
--- @field count number Any count supplied
--- @field reg string The optional register, if specified
--- @field mods string Command modifiers, if any
--- @field smods table Command modifiers in a structured format. Has the same structure as the "mods" key of `nvim_parse_cmd()`.


--- @param command UserCommandInfo
M.dune_command = function(command)
    local args = command.fargs
    if #args < 1 then
        return
    end

    local file = vim.api.nvim_buf_get_name(0)
    local root = M.find_project_folder(file)
    local cmd = vim.deepcopy(args)
    table.insert(cmd, 1, 'dune')

    if root == nil then
        error("Not a dune project")
        return
    end

    DuneJob:run(root, cmd)
end



-- TODO: this needs improvements, however with ocamllsp's diagnostics, it's not a high priority.
--       This can/should probably just be copied from ocaml/vim-ocaml
M.dune_efm = {
    '%AFile "%f"\\, line %l\\, characters %c-%k:',
    -- '%C%.%# | %.%#',
    '%C%.%# | %m', -- include the code line iself in the error message
    '%C %#^%#',
    '%C%trror%.%#: %m',
    '%C%tarning %m',
    '%C%m'
}

-- TODO: not a fan of the sync() call, but good enough for now.
--       would prefer a callback based design, but this seem not to be supported by
--       telescope at the moment.
-- M.dune_targets = function()
--     local targets = {}
--     local dune_job = Job:new({
--         command = "dune",
--         args = {"describe"},
--     })
--
--     -- pipe the results into sexp
--     local sexp_job = Job:new({
--         command = "sexp",
--         args = {"query", "(cat (pipe (field executables) (field names) (index 0)) (pipe (field library) (test (field local) (equals true)) (field name)))"},
--         writer = dune_job,
--         on_exit = function (job)
--             targets = job:result()
--         end
--     })
--     dune_job:and_then(sexp_job)
--
--     -- start the actual job
--     sexp_job:sync()
--
--     return targets
-- end


M.setup_make = function()
    vim.o.makeprg = "dune build $*"
    vim.opt.efm = M.dune_efm
end

return M
