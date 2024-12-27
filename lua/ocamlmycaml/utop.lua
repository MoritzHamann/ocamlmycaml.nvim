local Process = require("ocamlmycaml.util").Process
local util = require("ocamlmycaml.util")


--- @class Utop
local Utop = {
    --- @type Process
    process = nil,

    --- @type string
    root_path = ""
}
Utop.__index = Utop


--- @param root_path string
--- @param command string[]
--- @return Utop | nil
function Utop:start(root_path, command)

    --- @type vim.SystemOpts
    local opts = {
        cwd = root_path,
        stdin = true,
        detach = true,
        stdout = vim.schedule_wrap(function(err, data)
            print("|stdout,data| " .. data)
            if err ~= nil then
                print("|stdout,err|", err)
            end
            local lines = vim.split(data, "\n")
            local stdout = vim.tbl_filter(function(line)
                return vim.startswith(line, "stdout:")
            end, lines)
            local output = vim.tbl_map(function(line)
                return vim.fn.substitute(line, "stdout:", "", "")
            end, stdout)
            util.append_to_buffer("*utop*", output)
        end),
        stderr = vim.schedule_wrap(function (err, data)
            print("|stderr,data|", data)
            if err ~= nil then
                print("|stderr,err|", err)
            end
        end)
    }
    local p = Process:new(command, opts)
    if p == nil then
        print("Unable to start utop process")
        return
    end

    local utop = { root_path = root_path, process = p}

    return setmetatable(utop, self)
end



--- @param command string
--- @param data string[]
function Utop:send_command(command, data)
    local stdin = {}

    table.insert(stdin, command .. ":")

    for _, line in ipairs(data) do
        table.insert(stdin, "data:" .. line)
    end

    table.insert(stdin, "end:")

    self.process:write(stdin)
end

--- @param lines string | string[]
function Utop:evaluate_input(lines)

end


--- @param lines string | string[]
function Utop:evaluate_multi_input(lines)
    local stdin = {}

    if type(lines) == 'string' then
        stdin = { lines }
    elseif type(lines) == 'table' then
        stdin = lines
    else
        print('wrong input')
    end
    print(vim.inspect(stdin))
    self:send_command("input-multi", stdin)
end


function Utop:complete()

end

function Utop:complete_company()

end



local M = {}
M.utop_command = function(root, command)
    -- local args = command.fargs
    -- if #args < 1 then
    --     return
    -- end

    -- local cmd = vim.deepcopy(args)
    return Utop:start(root, command)
end

return M
