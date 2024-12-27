local make_entry = require("telescope.make_entry")


local M = {}


--- @class Process
local Process = {
    --- @type string[]
    cmd = {},

    --- @type vim.SystemOpts
    opts = {},

    --- @type vim.SystemObj|nil
    p = nil,

    --- @type Process[] list of all running processes
    active = {}
}
Process.__index = Process


--- @param cmd string[]
--- @param opts vim.SystemOpts
--- @param on_exit function | nil
--- @return Process | nil
function Process:new(cmd, opts, on_exit)

    local new_process = setmetatable({
        cmd = cmd,
        opts = opts or {},
    }, self)

    new_process.p = vim.system(cmd, opts, vim.schedule_wrap(function(completed)
        -- TODO: error handling on signals etc
        local index = nil
        for i, process in ipairs(Process.active) do
            if process == new_process then
                index = i
                break
            end
        end

        if index ~= nil then
            print("removing process at index", index)
            table.remove(Process.active, index)
        end

        if on_exit ~= nil then
            on_exit(completed)
        end
    end))

    table.insert(Process.active, new_process)

    return new_process
end

--- @param signal integer
function Process:stop(signal)
    -- using SIGINT by default
    if signal == nil then
        signal = 2
    end

    if self.p ~= nil and self.p:is_closing() == false then
        self.p:kill(signal)
    end
end

--- @param signal integer
function Process:stop_group(signal)
    -- using SIGINT by default
    if signal == nil then
        signal = 2
    end

    if self.p ~= nil and self.p:is_closing() == false then
        local gpid = -self.p.pid
        vim.uv.kill(gpid, signal)
    end
end


--- @param input string|string[]
function Process:write(input)
    if self.p == nil then
        print("process not started")
        return
    end
    self.p:write(input)
end

M.Process = Process


--- @class Logger
--- @field trace function<string>
--- @field debug function<string>
--- @field info function<string>
--- @field warn function<string>
--- @field error function<string>

--- @param namespace string
--- @return Logger
M.create_logger = function(namespace)
    local opts = {namespace = namespace}
    local logging_func_for = function(level)
        return function(msg)
            vim.notify(msg, level, opts)
        end
    end

    return {
        trace = logging_func_for(vim.log.levels.TRACE),
        debug = logging_func_for(vim.log.levels.DEBUG),
        info = logging_func_for(vim.log.levels.INFO),
        warn = logging_func_for(vim.log.levels.WARN),
        error = logging_func_for(vim.log.levels.ERROR),
    }
end


local _callable_obj = function()
  local obj = {}

  obj.__index = obj
  obj.__call = function(t, ...)
    return t:_find(...)
  end

  obj.close = function() end

  return obj
end

local CallbackDynamicFinder = _callable_obj()

function CallbackDynamicFinder:new(opts)
  opts = opts or {}

  assert(not opts.results, "`results` should be used with finder.new_table")
  assert(not opts.static, "`static` should be used with finder.new_oneshot_job")

  local obj = setmetatable({
    curr_buf = opts.curr_buf,
    fn = opts.fn,
    entry_maker = opts.entry_maker or make_entry.gen_from_string(opts),
  }, self)

  return obj
end

function CallbackDynamicFinder:_find(prompt, process_result, process_complete)
  self.fn(prompt, function(results)
      local result_num = 0
      for _, result in ipairs(results) do
        result_num = result_num + 1
        local entry = self.entry_maker(result)
        if entry then
          entry.index = result_num
        end
        if process_result(entry) then
          return
        end
      end

      process_complete()
    end)
end

M.new_callback_finder = function(opts)
    return CallbackDynamicFinder:new(opts)
end


--- @param buffer_name string
--- @return integer | nil
M.find_buffer = function(buffer_name)
    local buffer_list = vim.api.nvim_list_bufs()
    for _, buf_num in ipairs(buffer_list) do
        local name = vim.fn.bufname(buf_num)
        if name == buffer_name then
            return buf_num
        end
    end
    return nil
end


--- @param buffer_name string
--- @param lines string[]
M.append_to_buffer = function(buffer_name, lines)
    local buffer = M.find_buffer(buffer_name)
    if buffer == nil then
        buffer = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(buffer, buffer_name)
    end

    vim.api.nvim_buf_set_lines(buffer, -1, -1, true, lines)
end

return M
