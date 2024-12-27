local dune = require('ocamlmycaml.dune')


return {
    -- Internal command to see metrics for ocamllsp
    ["ocamllsp/view-metrics"] = function()
        vim.lsp.buf.execute_command({
            command = "ocamllsp/view-metrics",
        })
    end,

    -- This is a command normally executed via code actions. It takes a DocumentUri as a parameter,
    -- however it's the URI of the document to be opened directly. I.e. it will not open a .mli wenn
    -- a .ml URI is provided.
    ["ocamllsp/open-related-source"] = function(buffer)
        local document_uri = vim.uri_from_bufnr(buffer)

        vim.lsp.buf.execute_command({
            command = "ocamllsp/open-related-source",
            arguments = { document_uri }
        })
    end,
    -- this just reads the provided URI and displays it in a buffer?
    ["ocamllsp/show-document-text"] = function(buffer)
        local uri = vim.uri_from_bufnr(buffer)

        vim.lsp.buf.execute_command({
            command = "ocamllsp/show-document-text",
            arguments = {uri}
        })
    end,
    ["ocamllsp/show-merlin-config"] = function()
        vim.lsp.buf.execute_command({
            command = "ocamllsp/show-merlin-config",
        })
    end,
    ["dune/promote"] = function(buffer)
        local file = vim.api.nvim_buf_get_name(buffer)
        local dune_root = dune.find_project_folder(file)
        if dune_root == nil then
            vim.notify("not a dune folder", vim.log.levels.INFO)
            return
        end

        local args = {
            -- root folder of the project?
            dune = dune_root,
            -- `in_source` is the file we want to promote?
            in_source = file
        }
        vim.lsp.buf.execute_command({
            command = "dune/promote",
            arguments = { args }
        })
    end
}
