
--- Transform the nvim cursor position offsetts to ocamllsp offsets.
--- If no cursors position is provided, uses the current cursor in
--- active window
---
--- @param cursor integer[] | nil
--- @return table
local get_ocamllsp_pos = function(cursor)
    local win = vim.api.nvim_get_current_win()
    local c = cursor or vim.api.nvim_win_get_cursor(win)
    return {
        line = c[1] - 1,
        character = c[2]
    }
end

--- Transform the nvim cursor position offsetts to merli position string.
--- If no cursors position is provided, the current cursor in
--- active window is used
---
--- @param cursor integer[] | nil
--- @return string
local get_merlin_pos = function(cursor)
    local win = vim.api.nvim_get_current_win()
    local c = cursor or vim.api.nvim_win_get_cursor(win)
    return c[1] .. ":" .. c[2]
end


--- Get the current ocamllsp client for the buffer or nil if
--- no LSP client is attached
---
--- @param buffer integer buffer number
--- @return vim.lsp.Client | nil
local get_client_for_buffer = function(buffer)
    local clients = vim.lsp.get_clients({ bufnr = buffer, name = "ocamllsp" })
    if #clients == 0 or #clients > 1 then
        return nil
    end
    return clients[1]
end


--- Constructs and handles missing ocamllsp clients
---
--- @param callback OcamllspCallback
local function handle_missing_ocamllsp(callback)
      local err = {
	    code = 1,
	    message = "No active ocamllsp instance",
      }
      callback(err, nil)
end


--- TODO: Needs some rethinking
--- @param diff string `git diff` output
--- @return any
-- function parse_git_diff(diff)
--     local lines = vim.split(diff, "\n")
-- end

-- local wrap_diagnostics = function ()
--     local original_handler = vim.lsp.handlers['textDocument/publishDiagnostics']
--     vim.lsp.handlers['textDocument/publishDiagnostics'] = function(err, result, ctx, config)
--         local diagnostics = result.diagnostics
--
--         for _, d in ipairs(diagnostics) do
--             log.info(vim.inspect(d))
--             if d.source == "dune" and vim.startswith(d.message, 'diff') then
--                 -- TODO: remove
--                 -- log.info(d.message)
--
--                 -- local rgx = vim.regex([[@@ -(?<s>[0-9]+),(?<soffset>[0-9]+) \+(?<e>[0-9]+),(?<eoffset>[0-9]+) @@]])
--                 -- local test = "
--                 local message = vim.split(d.message, '\n')
--                 local positions = vim.tbl_filter(function(line)
--                     return rgx:match_str(line)
--                 end, message)
--
--                 if #positions > 0 then
--                     log.info(vim.inspect(positions))
--                 end
--
--             end
--         end
--
--         original_handler(err, result, ctx, config)
--     end
-- end

return {
    get_ocamllsp_pos = get_ocamllsp_pos,
    get_merlin_pos = get_merlin_pos,
    get_client_for_buffer = get_client_for_buffer,
    handle_missing_ocamllsp = handle_missing_ocamllsp
}
