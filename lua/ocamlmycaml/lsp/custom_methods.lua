local util = require('ocamlmycaml.lsp.util')

-- probably worth having a helper function which takes the name
-- of the request e.g. 'ocamllsp/getDocumentation' and the buffer
-- and:
-- * checks if a client is attached to the buffer
-- * checks if the request is supported by the ocamllsp server
-- * on_success calls a callback in the form of `function(lsp_client) ... end`

local register_lsp_method = function(buffer, name, implementation_fn)
    return function (buffer, cb)
        local client = util.get_client_for_buffer(buffer)
        if client == nil then
            local err = {
                code = 1,
                message = "No active ocamllsp instance",
            }
            vim.notify(err.message)
            return
        end

        if "not_supported" then
            local err = {
                code = 1,
                message = "not supported",
            }
            vim.notify(err.messag)
            return
        end

        implementation_fn(client, cb)
    end
end


return {

    getDocumentation2 = register_lsp_method("ocamllsp/getDocumentation", function(cb, lsp_client)

    end),

    --- @param buffer integer buffer number
    --- @param callback OcamllspCallback
    getDocumentation = function(buffer, callback)
        -- return with_lsp(handle_error(callback), function(client)
        --
        -- end)

        local document_uri = vim.uri_from_bufnr(buffer)
        local client = util.get_client_for_buffer(buffer)

        if client == nil then
	        return util.handle_missing_ocamllsp(callback)
        end

        local params = {
            textDocument = {
                uri = document_uri
            },
            position = util.get_ocamllsp_pos(),
            contentFormat = "markdown"
        }
        client.request("ocamllsp/getDocumentation", params, callback)
    end,


    --- @param buffer integer buffer number
    --- @param callback OcamllspCallback Callback for results, see :h lsp-handler
    hoverExtended = function(buffer, callback)
        local client = util.get_client_for_buffer(buffer)
        if client == nil then
            return util.handle_missing_ocamllsp(callback)
        end

        local file_uri = vim.uri_from_bufnr(buffer)
        local params = {
            textDocument = {
                uri = file_uri
            },
            position = util.get_ocamllsp_pos(),
        }

        client.request("ocamllsp/hoverExtended", params, callback)
    end,



    --- @param buffer integer buffer number
    --- @param callback OcamllspCallback
    inferIntf = function(buffer, callback)
        local document_uri = vim.uri_from_bufnr(buffer)
        local client = util.get_client_for_buffer(buffer)

        if client == nil then
	        return util.handle_missing_ocamllsp(callback)
        end

        client.request("ocamllsp/inferIntf", { document_uri }, callback)
    end,


    --- @param buffer integer buffer number
    --- @param options MerlinCommand
    --- @param callback OcamllspCallback
    merlinCallCompatible = function(buffer, options, callback)
        local document_uri = vim.uri_from_bufnr(buffer)
        local client = util.get_client_for_buffer(buffer)

        if client == nil then
            return util.handle_missing_ocamllsp(callback)
        end

        local params = {
            uri = document_uri,
            command = options.command,
            args = options.args,
            resultAsSexp = options.asSexp
        }

        client.request("ocamllsp/merlinCallCompatible", params, callback)
    end,



    --- @param buffer integer buffer number
    --- @param callback function invoked with the result
    switchImplIntf = function(buffer, callback)
        local document_uri = vim.uri_from_bufnr(buffer)
        local client = util.get_client_for_buffer(buffer)

        if client == nil then
            return util.handle_missing_ocamllsp(callback)
        end

        client.request("ocamllsp/switchImplIntf", { document_uri }, callback)
    end,


    --- @param buffer integer buffer number
    --- @param callback function invoked with the result
    typeEnclosing = function(buffer, callback)
        local document_uri = vim.uri_from_bufnr(buffer)
        local client = util.get_client_for_buffer(buffer)

        if client == nil then
            return util.handle_missing_ocamllsp(callback)
        end

        local params = {
            uri = document_uri,
            at = util.get_ocamllsp_pos(),
            index = 0,
            verbosity = 2
        }

        client.request("ocamllsp/typeEnclosing", params, callback)
    end,


    --- @param buffer integer buffer number
    --- @param callback OcamllspCallback
    typedHoles = function(buffer, callback)
        local document_uri = vim.uri_from_bufnr(buffer)
        local client = util.get_client_for_buffer(buffer)

        if client == nil then
            return util.handle_missing_ocamllsp(callback)
        end

        client.request("ocamllsp/typedHoles", { uri = document_uri }, callback)
    end,

    --- @param buffer integer buffer number
    --- @param callback OcamllspCallback
    wrappingAstNode = function(buffer, callback)
        local document_uri = vim.uri_from_bufnr(buffer)
        local client = util.get_client_for_buffer(buffer)

        if client == nil then
            return util.handle_missing_ocamllsp(callback)
        end

        local params = {
            uri = document_uri,
            position = util.get_ocamllsp_pos()
        }

        client.request("ocamllsp/wrappingAstNode", params, callback)
    end,

    --- @param buffer integer buffer number
    --- @param callback OcamllspCallback
    construct = function(buffer, callback)
        local document_uri = vim.uri_from_bufnr(buffer)
        local client = util.get_client_for_buffer(buffer)

        if client == nil then
            return util.handle_missing_ocamllsp(callback)
        end

        local params = {
            uri = document_uri,
            position = util.get_ocamllsp_pos(),
            -- TODO: make those options for the function
            depth = 1,
            withValues = "local"
        }

        client.request("ocamllsp/construct", params, callback)
    end,
}
