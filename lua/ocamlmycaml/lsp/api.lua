local util = require('ocamlmycaml.lsp.util')
local log = require('ocamlmycaml.util').create_logger('ocamlmycaml.lsp')
local custom_methods = require('ocamlmycaml.lsp.custom_methods')
local workspace_commands = require('ocamlmycaml.lsp.workspace_commands')

--------------------------
--- MARK: custom types ---
--------------------------


--- The server capabilites provided by ocamllsp
--- @class OcamllspCapabilities
--- @field diagnostic_promotions boolean
--- @field handleHoverExtended boolean
--- @field handleInferIntf boolean
--- @field handleSwitchImplIntf boolean
--- @field handleTypedHoles boolean
--- @field handleWrappingAstNode boolean
--- @field interfaceSpecificLangId boolean
--- @field handleConstruct boolean
--- @field handleGetDocumentation boolean
--- @field handleMerlinCallCompatible boolean
--- @field handleTypeEnclosing boolean


--- The interface used by all `api` methods for ocamllsp
--- @alias OcamllspCallback function<lsp.ResponseError|nil, any>


--- The interface for merlin forwards (`merlinCallCompatible`)
--- @class MerlinCommand
--- @field command string
--- @field args string[]
--- @field asSexp boolean



--- @return OcamllspCapabilities
local get_available = function()
    local client = util.get_client_for_buffer(0)
    if client == nil then
        log.info("No active ocamllsp")
        return {}
    end

    -- all ocamllsp specific requests are stored under server_capabilities.experimental.ocamllsp
    --- @type OcamllspCapabilities
    local cap = client.server_capabilities.experimental.ocamllsp

    return {
        diagnostic_promotions = cap.diagnostic_promotions or false,
        getDocumentation = cap.handleGetDocumentation or false,
        hoverExtended = cap.handleHoverExtended or false,
        inferIntf = cap.handleInferIntf or false,
        merlinCallCompatible = cap.handleMerlinCallCompatible or false,
        switchImplIntf = cap.handleSwitchImplIntf or false,
        typeEnclosing = cap.handleTypeEnclosing or false,
        typedHoles = cap.handleTypedHoles or false,
        wrappingAstNode = cap.handleWrappingAstNode or false,
        interfaceSpecificLangId = cap.interfaceSpecificLangId or false,
        construct = cap.handleConstruct or false
    }
end

-- TODO: should we actually accept the official name of the capability?
--- @param name string name of the server capability
local check_available = function(name)
    local capabilities = get_available()
    return capabilities[name] == true
end

local merlin = {
    expand_ppx = function(buffer, callback)
        local position = util.get_merlin_pos()
        --- @type MerlinCommand
        local merlin_options = {
            command = "expand-ppx",
            args = {
                "-position", position,
            },
            asSexp = false
        }
        custom_methods.merlinCallCompatible(buffer, merlin_options, callback)
    end,
}


return {
    -- helpers
    get_available = get_available,
    check_available = check_available,

    -- ocamllsp specific requests
    custom_methods = custom_methods,
    workspace_commands = workspace_commands,
    merlin = merlin
}
