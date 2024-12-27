local util = require('ocamlmycaml.util')
local log = util.create_logger("ocamlmycaml.dune")

local fidget_available, fidget_progress_handle = pcall(require, "fidget.progress.handle")

--- @class DuneJob
local DuneJob = {
    --- @type string | nil
    root_path = nil,

    --- @type string[]
    command = {},

    --- @type ProgressHandle
    progress_handler = nil,

    --- @type Process
    process = nil,

    --- @type vim.SystemOpts
    opts = {},

    --- @type DuneJob[]
    dune_jobs = {},

}
DuneJob.__index = DuneJob

DuneJob.active_jobs = function()
    return DuneJob.dune_jobs
    -- local jobs = {}
    -- for _, p in ipairs(util.Process.active) do
    --     if p.cmd[1] == 'dune' then
    --         table.insert(jobs, p)
    --     end
    -- end
    -- return jobs
end


--- @param root string
--- @param command string[]
--- @param opts vim.SystemOpts | nil
function DuneJob:run(root, command, opts)
    local job = setmetatable({
        root_path = root,
        command = command,
        opts = opts or {}
    }, self)

    -- TODO: replace those with buffer outputs
    opts = opts or {}

    local default_opts = {
        stdout = function (error, data)
            if error then
                log.error("Error: " .. error)
                return
            end

            if fidget_available and job.progress_handler then
                job.progress_handler:report({message = data})
            end
        end,

        stderr = function (error, data)
            if error then
                log.error("Error: " .. error)
                return
            end
            if fidget_available and job.progress_handler then
                job.progress_handler:report({message = data})
            end
        end,
    }

    --- @type vim.SystemOpts
    local options = vim.tbl_extend("keep", opts, default_opts)
    job.opts = options

    -- forcing specific behaviour we need for `cwd` and `detached`
    job.opts.cwd = root

    -- When using `dune exec -w <target>`, two processes are created:
    --
    -- 1. the dune process which waits for file system changes to trigger a compilation
    -- 2. the <target> process
    --
    -- In Neovim we only know the PID of the dune process, not the <target> one.
    -- Hence, we can only send a SIGINT to the dune process.
    -- However, dune is currently not forwarding those signals the the child process
    -- (https://github.com/ocaml/dune/issues/11089), which will leave the
    -- <target> processes orphaned.
    --
    -- Due to this reason we're stopping the dune process by sending the SIGINT
    -- to its process group id (PGID) which is shared with the <target> process.
    -- Sending a signal to the process group will forward it to all processes
    -- in the group (see `man kill`).
    --
    -- By setting `detach = true` we ensure that the dune and <target> PGID is
    -- different from the Neovim one itself.
    -- Otherwise sending SIGINT to the group would stop Neovim itself.
    job.opts.detach = true

    local process = util.Process:new(job.command, job.opts, function(completed)
        -- stop the progress handliner indicator
        job.progress_handler:finish()

        -- remove the job from the list of DuneJobs
        local to_remove = nil
        for idx, j in ipairs(DuneJob.active_jobs()) do
            if j == job then
                to_remove = idx
                break
            end
        end

        if to_remove ~= nil then
            table.remove(DuneJob.dune_jobs, to_remove)
        end
    end)
    if process == nil then
        error("unable to start dune job")
        return
    end

    job.process = process
    table.insert(DuneJob.dune_jobs, job)

    if fidget_available then
        job.progress_handler = fidget_progress_handle.create({
            title = table.concat(job.command, " "),
            message = "msg",
            lsp_client = {name = "dune"},
        })
    end

    return job
end

function DuneJob:stop()
    if self.process ~= nil then
        -- The PID of the dune process is the PGID of all spawned subprocesses (hopefuly).
        -- We can send a signal to the process group by using the negative PGID (see `man kill`)
        self.process:stop_group(2)
    end
end


function DuneJob:toTable()
    return {root_path = self.root_path, command = self.command, opts = self.opts}
end

local M = {
    DuneJob = DuneJob
}

return M
