local has_telescope, telescope = pcall(require, 'telescope')
local lsp = require("ocamlmycaml.lsp.telescope")

if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

return telescope.register_extension ({
  exports = { search_by_type = lsp.search_by_type}
})
